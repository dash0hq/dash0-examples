import { Router } from "express";
import db from "../lib/db.js";
import { logger } from "../lib/logger.js";
import redis from "../lib/redis.js";
import { geolocate } from "./geo.js";

const router = Router();

router.get("/health", (_req, res) => res.json({ status: "ok" }));

router.get("/resolve/:code", async (req, res) => {
	const { code } = req.params;

	try {
		const cached = await redis.get(`urls:${code}`);

		let originalUrl;

		if (cached) {
			originalUrl = cached;
		} else {
			const result = await db.query(
				"SELECT original_url FROM urls WHERE short_code = $1",
				[code],
			);

			if (result.rows.length === 0) {
				return res.status(404).json({ error: "Short URL not found" });
			}

			originalUrl = result.rows[0].original_url;

			await redis.set(`urls:${code}`, originalUrl, { EX: 86400 });
		}

		await recordVisit(req, code);

		res.json({ original_url: originalUrl });
	} catch (err) {
		logger.error({ err }, "Resolve failed");
		res.status(500).json({ error: "Internal server error" });
	}
});

async function recordVisit(req, shortCode) {
	const ip = req.get("x-forwarded-for") || req.ip || req.socket.remoteAddress;
	const userAgent = req.get("user-agent") || "unknown";

	try {
		const geo = await geolocate(ip);

		await db.query(
			`INSERT INTO visits (short_code, ip_address, country, city, user_agent)
         VALUES ($1, $2, $3, $4, $5)`,
			[shortCode, ip, geo.country, geo.city, userAgent],
		);
	} catch (err) {
		logger.error({ err }, "Failed to record visit");
	}
}

export default router;
