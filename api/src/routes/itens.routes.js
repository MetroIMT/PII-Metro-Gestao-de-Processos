import { Router } from "express";
import { ObjectId } from "mongodb";
import { getDB } from "../db.js";
import { auth, requireRole } from "../middlewares/auth.js";

const router = Router();

const TIPO_COLLECTION_MAP = {
  instrumento: "instrumentos",
  ferramenta: "ferramentas",
};

function resolveCollection(tipo) {
  return TIPO_COLLECTION_MAP[tipo] ?? null;
}

router.get("/", auth(false), async (req, res) => {
  try {
    const { tipo, status } = req.query;
    const db = getDB();

    const filtroStatus = status ? { status } : {};

    const collectionName = tipo ? resolveCollection(tipo) : null;

    if (tipo && !collectionName) {
      return res
        .status(400)
        .json({ error: 'tipo precisa ser "instrumento" ou "ferramenta"' });
    }

    if (collectionName) {
      const itens = await db
        .collection(collectionName)
        .find(filtroStatus)
        .sort({ atualizadoEm: -1, criadoEm: -1 })
        .limit(200)
        .toArray();
      return res.json(
        itens.map((doc) => ({
          ...doc,
          tipo,
        }))
      );
    }

    const [ferramentas, instrumentos] = await Promise.all([
      db
        .collection("ferramentas")
        .find(filtroStatus)
        .sort({ atualizadoEm: -1, criadoEm: -1 })
        .limit(200)
        .toArray(),
      db
        .collection("instrumentos")
        .find(filtroStatus)
        .sort({ atualizadoEm: -1, criadoEm: -1 })
        .limit(200)
        .toArray(),
    ]);

    res.json([
      ...ferramentas.map((doc) => ({ ...doc, tipo: "ferramenta" })),
      ...instrumentos.map((doc) => ({ ...doc, tipo: "instrumento" })),
    ]);
  } catch (error) {
    console.error("Erro ao listar itens:", error);
    res.status(500).json({ error: "Falha ao listar itens" });
  }
});

// Alertas de calibração: instrumentos com validade vencida ou a vencer em N dias
router.get("/alerts/calibracao", auth(), async (req, res) => {
  try {
    const days = Number(req.query.days ?? 30);
    if (!Number.isFinite(days) || days <= 0) {
      return res.status(400).json({ error: "days deve ser > 0" });
    }

    const now = new Date();
    const limit = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    const db = getDB();
    const cursor = db
      .collection("instrumentos")
      .find({ validadeCalibracao: { $lte: limit } })
      .project({ nome: 1, codigoInterno: 1, validadeCalibracao: 1, status: 1 })
      .sort({ validadeCalibracao: 1 });

    const itens = await cursor.toArray();
    const vencidos = itens.filter(
      (i) => i.validadeCalibracao && i.validadeCalibracao < now
    );
    const aVencer = itens.filter(
      (i) => i.validadeCalibracao && i.validadeCalibracao >= now
    );

    res.json({
      total: itens.length,
      vencidos,
      aVencer,
    });
  } catch (error) {
    console.error("Erro ao listar alertas de calibração:", error);
    res.status(500).json({ error: "Falha ao listar alertas" });
  }
});

// Busca item por código único (patrimônio/codigoInterno)
router.get("/buscar-por-codigo", auth(false), async (req, res) => {
  try {
    const { codigo, tipo } = req.query;
    if (!codigo) return res.status(400).json({ error: "codigo é obrigatório" });

    const db = getDB();
    const collections = tipo
      ? [resolveCollection(tipo)]
      : ["instrumentos", "ferramentas"];
    const validCollections = collections.filter(Boolean);

    for (const col of validCollections) {
      const doc = await db
        .collection(col)
        .findOne({ codigoInterno: String(codigo) });
      if (doc) {
        return res.json({
          ...doc,
          tipo: col === "instrumentos" ? "instrumento" : "ferramenta",
        });
      }
    }

    res.status(404).json({ error: "Item não encontrado" });
  } catch (error) {
    console.error("Erro ao buscar por código:", error);
    res.status(500).json({ error: "Falha na busca por código" });
  }
});

router.post("/", auth(), requireRole("admin"), async (req, res) => {
  const { tipo, ...body } = req.body || {};

  if (!tipo) {
    return res.status(400).json({ error: "tipo é obrigatório" });
  }

  const collectionName = resolveCollection(tipo);
  if (!collectionName) {
    return res
      .status(400)
      .json({ error: 'tipo precisa ser "instrumento" ou "ferramenta"' });
  }

  if (!body?.nome) {
    return res.status(400).json({ error: "nome é obrigatório" });
  }

  const quantidade = Number(body.quantidade ?? 0);
  if (!Number.isFinite(quantidade) || quantidade < 0) {
    return res
      .status(400)
      .json({ error: "quantidade deve ser zero ou positivo" });
  }

  const payload = {
    ...body,
    quantidade,
    status: body.status ?? (tipo === "instrumento" ? "disponivel" : undefined),
    criadoEm: new Date(),
    atualizadoEm: new Date(),
  };

  try {
    const db = getDB();
    const result = await db.collection(collectionName).insertOne(payload);
    res.status(201).json({ _id: result.insertedId, tipo, ...payload });
  } catch (error) {
    console.error("Erro ao criar item:", error);
    res.status(500).json({ error: "Falha ao criar item" });
  }
});

router.patch("/:id", auth(), requireRole("admin"), async (req, res) => {
  const { tipo, ...body } = req.body || {};
  const { id } = req.params;

  if (!tipo) {
    return res.status(400).json({ error: "tipo é obrigatório" });
  }

  const collectionName = resolveCollection(tipo);
  if (!collectionName) {
    return res
      .status(400)
      .json({ error: 'tipo precisa ser "instrumento" ou "ferramenta"' });
  }

  if (!ObjectId.isValid(id)) {
    return res.status(400).json({ error: "ID inválido" });
  }

  if (!body || Object.keys(body).length === 0) {
    return res
      .status(400)
      .json({ error: "Informe ao menos um campo para atualizar" });
  }

  const updatePayload = {
    ...body,
    atualizadoEm: new Date(),
  };

  if (updatePayload.quantidade !== undefined) {
    const quantidade = Number(updatePayload.quantidade);
    if (!Number.isFinite(quantidade) || quantidade < 0) {
      return res
        .status(400)
        .json({ error: "quantidade deve ser zero ou positivo" });
    }
    updatePayload.quantidade = quantidade;
  }

  try {
    const db = getDB();
    const { matchedCount } = await db
      .collection(collectionName)
      .updateOne({ _id: new ObjectId(id) }, { $set: updatePayload });

    if (!matchedCount) {
      return res.status(404).json({ error: "Item não encontrado" });
    }

    res.json({ ok: true });
  } catch (error) {
    console.error("Erro ao atualizar item:", error);
    res.status(500).json({ error: "Falha ao atualizar item" });
  }
});

export default router;
