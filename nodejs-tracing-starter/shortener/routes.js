import { Router } from "express";
import { nanoid } from "nanoid";
import db from "../lib/db.js";
import { logger } from "../lib/logger.js";
import redis from "../lib/redis.js";
import { extractMetadata } from "./metadata.js";

const router = Router();
const REDIRECTOR_URL = process.env.REDIRECTOR_URL || "http://redirector:3001";

router.get("/health", (_req, res) => res.json({ status: "ok" }));

router.get("/api/urls", async (_req, res) => {
	const result = await db.query(
		"SELECT short_code, original_url, title, description, created_at FROM urls ORDER BY created_at DESC LIMIT 20",
	);

	const rows = await Promise.all(
		result.rows.map(async (row) => {
			const visits = await db.query(
				"SELECT COUNT(*) FROM visits WHERE short_code = $1",
				[row.short_code],
			);
			return { ...row, visit_count: parseInt(visits.rows[0].count, 10) };
		}),
	);

	res.json(rows);
});

router.post("/api/shorten", async (req, res) => {
	const { url } = req.body;

	if (!url) {
		return res.status(400).json({ error: "url is required" });
	}

	try {
		new URL(url);
	} catch {
		return res.status(400).json({ error: "Invalid URL format" });
	}

	try {
		const shortCode = nanoid(8);
		const metadata = await extractMetadata(url);

		await db.query(
			`INSERT INTO urls (short_code, original_url, title, description)
       VALUES ($1, $2, $3, $4)`,
			[shortCode, url, metadata.title, metadata.description],
		);

		await redis.set(`url:${shortCode}`, url, { EX: 86400 });

		res.status(201).json({
			short_code: shortCode,
			short_url: `${req.protocol}://${req.get("host")}/${shortCode}`,
			original_url: url,
			title: metadata.title,
			description: metadata.description,
		});
	} catch (err) {
		logger.error({ err }, "Failed to create short URL");
		res.status(500).json({ error: "Internal server error" });
	}
});

router.get("/:code", async (req, res) => {
	const { code } = req.params;

	try {
		const response = await fetch(`${REDIRECTOR_URL}/resolve/${code}`, {
			headers: {
				"x-forwarded-for": req.ip || req.socket.remoteAddress,
				"user-agent": req.get("user-agent") || "unknown",
			},
			signal: AbortSignal.timeout(5000),
			redirect: "manual",
		});

		const body = await response.json();

		if (!response.ok) {
			return res.status(response.status).json(body);
		}

		res.redirect(302, body.original_url);
	} catch (err) {
		logger.error({ err }, "Redirect proxy failed");
		res.status(502).json({ error: "Redirector service unavailable" });
	}
});

export default router;
