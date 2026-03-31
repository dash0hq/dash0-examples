import * as cheerio from "cheerio";
import { logger } from "../lib/logger.js";

export async function extractMetadata(url) {
	try {
		const response = await fetch(url, {
			headers: {
				"User-Agent": "Shortener/1.0",
			},
			signal: AbortSignal.timeout(5000),
		});

		const contentType = response.headers.get("content-type") || "";

		if (!response.ok) {
			throw new Error(`Unusable response: ${response.statusText}`);
		}

		if (!contentType.includes("text/html")) {
			return { title: null, description: null };
		}

		const html = await response.text();

		logger.info(
			{
				"url.target": url,
				"http.response.content_type": contentType,
				"metadata.html_bytes": html.length,
			},
			"Parsing HTML for metadata",
		);

		const $ = cheerio.load(html);

		const title =
			$('meta[property="og:title"]').attr("content") ||
			$("title").first().text().trim() ||
			null;

		const description =
			$('meta[property="og:description"]').attr("content") ||
			$('meta[name="description"]').attr("content") ||
			null;

		return { title, description };
	} catch (err) {
		logger.error({ err }, "Failed to extract metadata");
		return { title: null, description: null };
	}
}
