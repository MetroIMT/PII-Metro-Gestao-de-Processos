import { Router } from "express";
import { ObjectId } from "mongodb";
import bcrypt from "bcryptjs";
import { getDB } from "../db.js";
import { auth, requireRole, requireAdmin } from "../middlewares/auth.js";

const router = Router();

const ROLES = ["tecnico", "gestor", "admin"];

// Listar usuários (admin e gestor podem ver; gestor não vê admins por padrão)
router.get("/", auth(), requireRole("gestor", "admin"), async (req, res) => {
  try {
    const db = getDB();
    const filtro = {};
    // Se role for gestor, opcionalmente pode ocultar admins
    if (req.user.role === "gestor")
      filtro.role = { $in: ["tecnico", "gestor"] };

    const users = await db
      .collection("usuarios")
      .find(filtro)
      .project({ senhaHash: 0 })
      .sort({ nome: 1 })
      .toArray();
    res.json(users);
  } catch (error) {
    console.error("Erro ao listar usuários:", error);
    res.status(500).json({ error: "Falha ao listar usuários" });
  }
});

// Criar usuário (apenas admin)
router.post("/", auth(), requireAdmin, async (req, res) => {
  try {
    const {
      nome,
      email,
      senha,
      cpf,
      telefone,
      role = "tecnico",
      ativo = true,
    } = req.body || {};
    if (!nome || !email || !senha || !cpf || !telefone) {
      return res
        .status(400)
        .json({ error: "nome, email, senha, cpf e telefone são obrigatórios" });
    }
    const emailNorm = String(email).trim().toLowerCase();
    if (!ROLES.includes(role))
      return res.status(400).json({ error: "role inválido" });

    const db = getDB();
    const jaExiste = await db
      .collection("usuarios")
      .findOne({ email: emailNorm });
    if (jaExiste) return res.status(409).json({ error: "Email já cadastrado" });

    const senhaHash = await bcrypt.hash(String(senha), 10);
    const doc = {
      nome,
      email: emailNorm,
      senhaHash,
      cpf,
      telefone,
      role,
      ativo: !!ativo,
      criadoEm: new Date(),
      atualizadoEm: new Date(),
    };
    const { insertedId } = await db.collection("usuarios").insertOne(doc);
    res.status(201).json({
      _id: insertedId,
      nome,
      email: emailNorm,
      cpf,
      telefone,
      role,
      ativo,
      criadoEm: doc.criadoEm,
      atualizadoEm: doc.atualizadoEm,
    });
  } catch (error) {
    console.error("Erro ao criar usuário:", error);
    res.status(500).json({ error: "Falha ao criar usuário" });
  }
});

// Atualizar usuário (admin pode tudo; gestor não pode promover para admin)
router.patch(
  "/:id",
  auth(),
  requireRole("gestor", "admin"),
  async (req, res) => {
    try {
      const { id } = req.params;
      if (!ObjectId.isValid(id))
        return res.status(400).json({ error: "ID inválido" });

      const { nome, email, senha, cpf, telefone, role, ativo } = req.body || {};
      const update = { atualizadoEm: new Date() };
      if (nome !== undefined) update.nome = nome;
      if (email !== undefined)
        update.email = String(email).trim().toLowerCase();
      if (senha !== undefined)
        update.senhaHash = await bcrypt.hash(String(senha), 10);
      if (cpf !== undefined) update.cpf = cpf;
      if (telefone !== undefined) update.telefone = telefone;
      if (role !== undefined) {
        if (!ROLES.includes(role))
          return res.status(400).json({ error: "role inválido" });
        if (req.user.role === "gestor" && role === "admin")
          return res
            .status(403)
            .json({ error: "gestor não pode promover para admin" });
        update.role = role;
      }
      if (ativo !== undefined) update.ativo = !!ativo;

      const db = getDB();
      if (update.email) {
        const exists = await db
          .collection("usuarios")
          .findOne({ email: update.email, _id: { $ne: new ObjectId(id) } });
        if (exists)
          return res.status(409).json({ error: "Email já cadastrado" });
      }

      const { matchedCount } = await db
        .collection("usuarios")
        .updateOne({ _id: new ObjectId(id) }, { $set: update });

      if (!matchedCount)
        return res.status(404).json({ error: "Usuário não encontrado" });

      // ✅ BUSCAR E RETORNAR O USUÁRIO ATUALIZADO
      const updatedUser = await db
        .collection("usuarios")
        .findOne({ _id: new ObjectId(id) }, { projection: { senhaHash: 0 } });

      res.json(updatedUser);
    } catch (error) {
      console.error("Erro ao atualizar usuário:", error);
      res.status(500).json({ error: "Falha ao atualizar usuário" });
    }
  }
);

// Remover usuário (apenas admin)
router.delete("/:id", auth(), requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    if (!ObjectId.isValid(id))
      return res.status(400).json({ error: "ID inválido" });

    const db = getDB();
    const { deletedCount } = await db
      .collection("usuarios")
      .deleteOne({ _id: new ObjectId(id) });
    if (!deletedCount)
      return res.status(404).json({ error: "Usuário não encontrado" });
    res.json({ ok: true });
  } catch (error) {
    console.error("Erro ao remover usuário:", error);
    res.status(500).json({ error: "Falha ao remover usuário" });
  }
});

export default router;
