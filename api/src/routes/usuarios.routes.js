import { Router } from "express";
import { ObjectId } from "mongodb";
import bcrypt from "bcryptjs";
import multer from "multer";
import path from "path";
import fs from "fs";
import { getDB } from "../db.js";
import { auth, requireRole, requireAdmin } from "../middlewares/auth.js";

const router = Router();

// Multer setup: store files in api/uploads
const uploadDir = path.join(process.cwd(), "api", "uploads");
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const unique =
      Date.now() + "-" + Math.random().toString(36).substring(2, 8);
    cb(null, unique + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

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

// Buscar usuário por id (apenas o próprio usuário ou admin)
router.get("/:id", auth(), async (req, res) => {
  try {
    const { id } = req.params;
    if (!ObjectId.isValid(id))
      return res.status(400).json({ error: "ID inválido" });

    if (!req.user) return res.status(401).json({ error: "Não autorizado" });
    if (req.user.sub !== id && req.user.role !== "admin")
      return res.status(403).json({ error: "Acesso negado" });

    const db = getDB();
    const user = await db
      .collection("usuarios")
      .findOne({ _id: new ObjectId(id) }, { projection: { senhaHash: 0 } });

    if (!user) return res.status(404).json({ error: "Usuário não encontrado" });
    res.json(user);
  } catch (error) {
    console.error("Erro ao buscar usuário:", error);
    res.status(500).json({ error: "Falha ao buscar usuário" });
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

      const {
        nome,
        email,
        senha,
        current,
        cpf,
        telefone,
        role,
        ativo,
        avatarUrl,
      } = req.body || {};

      const db = getDB();

      // Load existing user for password verification and other checks
      let existingUser = null;
      try {
        existingUser = await db
          .collection("usuarios")
          .findOne({ _id: new ObjectId(id) });
      } catch (e) {
        existingUser = null;
      }

      const update = { atualizadoEm: new Date() };
      if (nome !== undefined) update.nome = nome;
      if (email !== undefined)
        update.email = String(email).trim().toLowerCase();

      // Handle password change: if the user is changing their own password and
      // is not an admin, require `current` and verify it against the stored
      // senhaHash. Admins may change without providing the current password.
      if (senha !== undefined) {
        if (req.user && req.user.sub === id && req.user.role !== "admin") {
          if (!current)
            return res.status(400).json({ error: "Senha atual é necessária" });
          if (!existingUser || !existingUser.senhaHash)
            return res
              .status(400)
              .json({ error: "Não foi possível verificar a senha atual" });
          const ok = await bcrypt.compare(
            String(current),
            String(existingUser.senhaHash)
          );
          if (!ok)
            return res.status(403).json({ error: "Senha atual incorreta" });
        }
        update.senhaHash = await bcrypt.hash(String(senha), 10);
      }

      if (cpf !== undefined) update.cpf = cpf;
      if (telefone !== undefined) update.telefone = telefone;
      if (avatarUrl !== undefined) update.avatarUrl = avatarUrl;
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

      if (update.email) {
        const exists = await db
          .collection("usuarios")
          .findOne({ email: update.email, _id: { $ne: new ObjectId(id) } });
        if (exists)
          return res.status(409).json({ error: "Email já cadastrado" });
      }

      // Se o cliente explicitamente enviou avatarUrl === null, remova arquivo anterior
      if (avatarUrl === null) {
        try {
          const existing = await db
            .collection("usuarios")
            .findOne({ _id: new ObjectId(id) });
          if (existing && existing.avatarUrl) {
            try {
              const parsed = new URL(String(existing.avatarUrl));
              const prevName = path.basename(parsed.pathname);
              const prevPath = path.join(uploadDir, prevName);
              if (fs.existsSync(prevPath)) fs.unlinkSync(prevPath);
            } catch (e) {
              // ignore parse/remove errors
            }
          }
        } catch (e) {
          // ignore db errors
        }
        update.avatarUrl = null;
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

// (Nota: remoção de arquivo ao receber avatarUrl=null é tratada na rota PATCH acima)

// Upload avatar (multipart/form-data) -> atualiza avatarUrl do usuário
router.post(
  "/:id/avatar",
  auth(),
  upload.single("avatar"),
  async (req, res) => {
    try {
      const { id } = req.params;
      if (!ObjectId.isValid(id))
        return res.status(400).json({ error: "ID inválido" });

      // somente o próprio usuário ou admin pode fazer upload
      if (!req.user) return res.status(401).json({ error: "Não autorizado" });
      if (req.user.sub !== id && req.user.role !== "admin")
        return res.status(403).json({ error: "Acesso negado" });

      if (!req.file) return res.status(400).json({ error: "Arquivo ausente" });

      const filename = req.file.filename;
      const publicUrl = `${req.protocol}://${req.get(
        "host"
      )}/uploads/${filename}`;

      // Antes de atualizar, remova arquivo de avatar anterior (se existir)
      try {
        const db = getDB();
        const existing = await db
          .collection("usuarios")
          .findOne({ _id: new ObjectId(id) });
        if (existing && existing.avatarUrl) {
          try {
            const parsed = new URL(String(existing.avatarUrl));
            const prevName = path.basename(parsed.pathname);
            const prevPath = path.join(uploadDir, prevName);
            if (fs.existsSync(prevPath)) fs.unlinkSync(prevPath);
          } catch (e) {
            // ignore errors parsing/removing previous file
          }
        }
      } catch (e) {
        // ignore db errors here; proceed to update avatarUrl
      }

      const db = getDB();
      const { matchedCount } = await db
        .collection("usuarios")
        .updateOne(
          { _id: new ObjectId(id) },
          { $set: { avatarUrl: publicUrl, atualizadoEm: new Date() } }
        );

      if (!matchedCount)
        return res.status(404).json({ error: "Usuário não encontrado" });

      const updatedUser = await db
        .collection("usuarios")
        .findOne({ _id: new ObjectId(id) }, { projection: { senhaHash: 0 } });
      res.json(updatedUser);
    } catch (error) {
      console.error("Erro ao fazer upload de avatar:", error);
      res.status(500).json({ error: "Falha ao enviar avatar" });
    }
  }
);

// Revogar sessão remota (se existir coleção 'sessions')
router.post("/:id/sessions/:sessionId/revoke", auth(), async (req, res) => {
  try {
    const { id, sessionId } = req.params;
    if (!req.user) return res.status(401).json({ error: "Não autorizado" });
    if (req.user.sub !== id && req.user.role !== "admin")
      return res.status(403).json({ error: "Acesso negado" });

    const db = getDB();
    const query = { userId: id };
    // tente interpretar sessionId como ObjectId
    if (ObjectId.isValid(sessionId)) query._id = new ObjectId(sessionId);
    else query.id = sessionId;

    // se não existir coleção sessions, a operação será silenciosa
    try {
      const { deletedCount } = await db.collection("sessions").deleteOne(query);
      // ok mesmo que deletedCount seja 0
    } catch (e) {
      // ignore errors if collection doesn't exist
    }

    res.json({ ok: true });
  } catch (error) {
    console.error("Erro ao revogar sessão:", error);
    res.status(500).json({ error: "Falha ao revogar sessão" });
  }
});

// Listar sessões ativas de um usuário (se existir coleção 'sessions')
router.get("/:id/sessions", auth(), async (req, res) => {
  try {
    const { id } = req.params;
    if (!ObjectId.isValid(id))
      return res.status(400).json({ error: "ID inválido" });

    // somente o próprio usuário ou admin pode consultar as sessões
    if (!req.user) return res.status(401).json({ error: "Não autorizado" });
    if (req.user.sub !== id && req.user.role !== "admin")
      return res.status(403).json({ error: "Acesso negado" });

    const db = getDB();
    try {
      const docs = await db
        .collection("sessions")
        .find({ userId: id })
        .sort({ lastSeen: -1 })
        .toArray();

      // Normalize para JSON-friendly
      const sessions = docs.map((d) => ({
        id: d._id ? String(d._id) : d.id || null,
        device: d.device || d.userAgent || "Desconhecido",
        ip: d.ip || null,
        lastSeen: d.lastSeen ? new Date(d.lastSeen) : null,
        // inclui outros campos úteis sem expor sensíveis
      }));

      return res.json(sessions);
    } catch (e) {
      // se collection não existir, retornamos array vazio
      return res.json([]);
    }
  } catch (error) {
    console.error("Erro ao listar sessões:", error);
    res.status(500).json({ error: "Falha ao listar sessões" });
  }
});
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
