import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import express from "express";
import routes from "./routes.js";
import { logger } from "../lib/logger.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

const app = express();
app.use(express.json());
app.use(express.static(join(__dirname, "public")));
app.get("/", (_req, res) => res.sendFile(join(__dirname, "public", "index.html")));
app.use(routes);

const port = process.env.PORT || 3000;
app.listen(port, () => {
	logger.info(`Shortener service listening on port ${port}`);
});
