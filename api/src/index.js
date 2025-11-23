import express from "express";
import cors from "cors";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { config } from "./config.js";
import { connectDB } from "./db.js";
import { ensureIndexes } from "./indexes.js";
import authRoutes from "./routes/auth.routes.js";
import itensRoutes from "./routes/itens.routes.js";
import movimentosRoutes from "./routes/movimentos.routes.js";
import usuariosRoutes from "./routes/usuarios.routes.js";
import materiaisRoutes from "./routes/materiais.routes.js";

async function bootstrap() {
  const db = await connectDB();
  await ensureIndexes(db);

  const app = express();
  app.use(cors());
  app.use(express.json());

  // Serve uploaded files (avatars)
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const uploadsDir = path.join(process.cwd(), "api", "uploads");
  try {
    fs.mkdirSync(uploadsDir, { recursive: true });
  } catch (e) {
    console.warn("Não foi possível criar pasta de uploads:", e);
  }
  app.use("/uploads", express.static(uploadsDir));

  app.get("/health", (_, res) => res.json({ ok: true }));
  app.use("/auth", authRoutes);
  app.use("/itens", itensRoutes);
  app.use("/materiais", materiaisRoutes);
  app.use("/movimentos", movimentosRoutes);
  app.use("/usuarios", usuariosRoutes);

  app.listen(config.port, '0.0.0.0', () => {
    console.log(`API rodando em http://localhost:${config.port}`);
  });
}

bootstrap().catch((err) => {
  console.error("Falha ao iniciar a API", err);
  process.exit(1);
});
