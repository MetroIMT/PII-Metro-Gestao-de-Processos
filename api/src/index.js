import express from "express";
import cors from "cors";
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

  app.get("/health", (_, res) => res.json({ ok: true }));
  app.use("/auth", authRoutes);
  app.use("/itens", itensRoutes);
  app.use("/materiais", materiaisRoutes);
  app.use("/movimentos", movimentosRoutes);
  app.use("/usuarios", usuariosRoutes);

  app.listen(config.port, () => {
    console.log(`API rodando em http://localhost:${config.port}`);
  });
}

bootstrap().catch((err) => {
  console.error("Falha ao iniciar a API", err);
  process.exit(1);
});
