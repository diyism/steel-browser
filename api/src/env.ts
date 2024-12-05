import { z } from "zod";
import { config } from "dotenv";

config();

const envSchema = z.object({
  HOST: z.string().optional().default("0.0.0.0"),
  DOMAIN: z.string().optional(),
  PORT: z.string().optional().default("3000"),
  CDP_REDIRECT_PORT: z.string().optional().default("9222"),
  PROXY_URL: z.string().optional(),
  DEFAULT_HEADERS: z
    .string()
    .transform((val) => (val ? JSON.parse(val) : undefined))
    .pipe(z.record(z.string()))
    .optional(),
});

export const env = envSchema.parse(process.env);
