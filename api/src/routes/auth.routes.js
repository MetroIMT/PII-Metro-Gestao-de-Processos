import { Router } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { getDB } from "../db.js";
import { config } from "../config.js";

const router = Router();

router.post("/login", async (req, res) => {
  try {
    const { email, senha } = req.body || {};
    if (!email || !senha) {
      return res.status(400).json({ error: "email e senha são obrigatórios" });
    }

    const emailNormalizado = String(email).trim().toLowerCase();
    if (!emailNormalizado) {
      return res.status(400).json({ error: "email inválido" });
    }

    const db = getDB();
    const user = await db
      .collection("usuarios")
      .findOne({ email: emailNormalizado, ativo: true });

    if (!user?.senhaHash) {
      return res.status(401).json({ error: "Credenciais inválidas" });
    }

    const senhaConfere = await bcrypt.compare(String(senha), user.senhaHash);
    if (!senhaConfere) {
      return res.status(401).json({ error: "Credenciais inválidas" });
    }

    const token = jwt.sign(
      { sub: user._id.toString(), role: user.role },
      config.jwtSecret,
      { expiresIn: "8h" }
    );

    res.json({
      token,
      role: user.role,
      nome: user.nome,
      id: user._id.toString(),
      expiresIn: 8 * 60 * 60, // segundos
    });
  } catch (error) {
    console.error("Erro ao autenticar usuário:", error);
    res.status(500).json({ error: "Falha ao realizar login" });
  }
});

export default router;