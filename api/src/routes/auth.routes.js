import { Router } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { getDB } from "../db.js";
import { config } from "../config.js";

const router = Router();

router.post("/login", async (req, res) => {
  const { email, senha } = req.body || {};

  if (!email || !senha) {
    return res.status(400).json({ error: "Email e senha são obrigatórios." });
  }

  const emailNormalizado = String(email).trim().toLowerCase();

  if (!emailNormalizado.endsWith("@metrosp.com.br")) {
    return res.status(400).json({ error: "Use um email @metrosp.com.br." });
  }

  try {
    const db = getDB();
    const usuariosCol = db.collection("usuarios");

    const usuario = await usuariosCol.findOne({
      email: emailNormalizado,
      ativo: true,
    });
    if (!usuario) {
      return res.status(401).json({ error: "Credenciais inválidas." });
    }

    const senhaValida = await bcrypt.compare(senha, usuario.senhaHash);
    if (!senhaValida) {
      return res.status(401).json({ error: "Credenciais inválidas." });
    }

    const token = jwt.sign(
      { sub: usuario._id, role: usuario.role },
      config.jwtSecret,
      {
        expiresIn: "8h",
      }
    );

    // Record a session document so the UI can show active sessions.
    try {
      const db = getDB();
      const userIdStr = usuario._id.toString();
      const ua = req.get("user-agent") || "Desconhecido";
      const ip = req.headers["x-forwarded-for"] || req.ip || null;

      const sessionDoc = {
        userId: userIdStr,
        device: ua,
        ip: ip,
        lastSeen: new Date(),
        criadoEm: new Date(),
      };

      const { insertedId } = await db
        .collection("sessions")
        .insertOne(sessionDoc);

      return res.json({
        token,
        role: usuario.role,
        nome: usuario.nome,
        id: userIdStr,
        expiresIn: 8 * 60 * 60,
        sessionId: insertedId ? String(insertedId) : null,
      });
    } catch (e) {
      // If session save fails, still return token but log error.
      console.error("Erro ao gravar sessão:", e);
      return res.json({
        token,
        role: usuario.role,
        nome: usuario.nome,
        id: usuario._id.toString(),
        expiresIn: 8 * 60 * 60,
      });
    }
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Erro interno ao autenticar." });
  }
});

export default router;
