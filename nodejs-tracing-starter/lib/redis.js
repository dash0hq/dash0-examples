import { createClient } from "redis";
import { logger } from "./logger.js";

const redis = createClient({ url: process.env.REDIS_URL });

redis.on("error", (err) => logger.error({ err }, "Redis error"));

await redis.connect();

export default redis;
