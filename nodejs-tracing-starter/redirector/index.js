import express from "express";
import routes from "./routes.js";
import { logger } from "../lib/logger.js";

const app = express();
app.use(express.json());
app.use(routes);

const port = process.env.PORT || 3001;
app.listen(port, () => {
	logger.info(`Redirector service listening on port ${port}`);
});
