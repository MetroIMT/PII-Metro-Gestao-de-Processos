import { Router } from "express";
import { ObjectId } from "mongodb";
import { auth } from "../middlewares/auth.js";
import { getClient, getDB } from "../db.js";

const router = Router();

router.get("/", async (req, res) => {
  const { itemId, limit } = req.query;
  const filtro = {};

  if (itemId) {
    // A busca por `codigo` não precisa de `ObjectId`
    filtro.codigoMaterial = itemId;
  }

  const max = Math.min(Math.max(Number(limit) || 200, 1), 1000); // 1..1000

  const db = getDB();
  // Ordena por várias chaves possíveis, para maior compatibilidade
  const docs = await db
    .collection("movimentos")
    .find(filtro)
    .sort({ data: -1, dataHora: -1, createdAt: -1, _id: -1 })
    .limit(max)
    .toArray();

  res.json(docs);
});

router.post("/", auth(), async (req, res) => {
  const { tipo, itemTipo, itemId, quantidade = 1, observacao } = req.body || {};

  if (!tipo || !itemTipo || !itemId) {
    return res.status(400).json({ error: "Campos obrigatórios faltando" });
  }

  const tiposPermitidos = ["entrada", "saida", "emprestimo", "devolucao"];
  if (!tiposPermitidos.includes(tipo)) {
    return res.status(400).json({ error: "Tipo inválido" });
  }

  if (!["instrumento", "ferramenta"].includes(itemTipo)) {
    return res
      .status(400)
      .json({ error: 'itemTipo precisa ser "instrumento" ou "ferramenta"' });
  }

  if (!ObjectId.isValid(itemId)) {
    return res.status(400).json({ error: "itemId inválido" });
  }

  const quantidadeNum = Number(quantidade);
  if (!Number.isFinite(quantidadeNum) || quantidadeNum <= 0) {
    return res
      .status(400)
      .json({ error: "Quantidade precisa ser maior que zero" });
  }

  const usuarioId = req.user?.sub;
  if (!usuarioId || !ObjectId.isValid(usuarioId)) {
    return res.status(401).json({ error: "Usuário inválido" });
  }

  const db = getDB();
  const client = getClient();
  const collectionName =
    itemTipo === "instrumento" ? "instrumentos" : "ferramentas";
  const _id = new ObjectId(itemId);
  const usuarioObjectId = new ObjectId(usuarioId);
  const session = client.startSession();

  try {
    await session.withTransaction(async () => {
      await db.collection("movimentos_estoque").insertOne(
        {
          tipo,
          itemTipo,
          itemId: _id,
          quantidade: quantidadeNum,
          usuarioId: usuarioObjectId,
          observacao: observacao ?? null,
          dataHora: new Date(),
        },
        { session }
      );

      const inc =
        tipo === "entrada" || tipo === "devolucao"
          ? quantidadeNum
          : -quantidadeNum;
      const status =
        itemTipo === "instrumento"
          ? tipo === "emprestimo"
            ? "emprestada"
            : tipo === "devolucao"
            ? "disponivel"
            : undefined
          : undefined;

      const update = {
        $inc: { quantidade: inc },
        $set: { atualizadoEm: new Date() },
      };

      if (status) {
        update.$set.status = status;
      }

      const { matchedCount } = await db
        .collection(collectionName)
        .updateOne({ _id }, update, { session });

      if (!matchedCount) {
        throw new Error("ITEM_NOT_FOUND");
      }
    });

    res.status(201).json({ ok: true });
  } catch (error) {
    if (error.message === "ITEM_NOT_FOUND") {
      return res.status(404).json({ error: "Item não encontrado" });
    }

    console.error("Erro ao registrar movimento:", error);
    res.status(500).json({ error: "Falha ao registrar movimento" });
  } finally {
    await session.endSession();
  }
});

// Registrar movimento por código único (codigoInterno)
router.post("/by-code", auth(), async (req, res) => {
  const { tipo, codigo, itemTipo, quantidade = 1, observacao } = req.body || {};

  if (!tipo || !codigo || !itemTipo) {
    return res.status(400).json({ error: "Campos obrigatórios faltando" });
  }

  const tiposPermitidos = ["entrada", "saida", "emprestimo", "devolucao"];
  if (!tiposPermitidos.includes(tipo)) {
    return res.status(400).json({ error: "Tipo inválido" });
  }

  if (!["instrumento", "ferramenta"].includes(itemTipo)) {
    return res
      .status(400)
      .json({ error: 'itemTipo precisa ser "instrumento" ou "ferramenta"' });
  }

  const quantidadeNum = Number(quantidade);
  if (!Number.isFinite(quantidadeNum) || quantidadeNum <= 0) {
    return res
      .status(400)
      .json({ error: "Quantidade precisa ser maior que zero" });
  }

  const usuarioId = req.user?.sub;
  if (!usuarioId || !ObjectId.isValid(usuarioId)) {
    return res.status(401).json({ error: "Usuário inválido" });
  }

  const db = getDB();
  const client = getClient();
  const collectionName =
    itemTipo === "instrumento" ? "instrumentos" : "ferramentas";
  const usuarioObjectId = new ObjectId(usuarioId);
  const session = client.startSession();

  try {
    await session.withTransaction(async () => {
      const item = await db
        .collection(collectionName)
        .findOne({ codigoInterno: String(codigo) }, { session });
      if (!item) throw new Error("ITEM_NOT_FOUND");

      // Salvaguarda de estoque não negativo
      const inc =
        tipo === "entrada" || tipo === "devolucao"
          ? quantidadeNum
          : -quantidadeNum;
      const novaQtd = Number(item.quantidade ?? 0) + inc;
      if (novaQtd < 0) throw new Error("NO_STOCK");

      const status =
        itemTipo === "instrumento"
          ? tipo === "emprestimo"
            ? "emprestada"
            : tipo === "devolucao"
            ? "disponivel"
            : undefined
          : undefined;

      await db.collection("movimentos_estoque").insertOne(
        {
          tipo,
          itemTipo,
          itemId: item._id,
          codigoInterno: item.codigoInterno,
          quantidade: quantidadeNum,
          usuarioId: usuarioObjectId,
          observacao: observacao ?? null,
          dataHora: new Date(),
        },
        { session }
      );

      const update = {
        $inc: { quantidade: inc },
        $set: { atualizadoEm: new Date() },
      };
      if (status) update.$set.status = status;

      const { matchedCount } = await db
        .collection(collectionName)
        .updateOne({ _id: item._id }, update, { session });

      if (!matchedCount) throw new Error("ITEM_NOT_FOUND");
    });

    res.status(201).json({ ok: true });
  } catch (error) {
    if (error.message === "ITEM_NOT_FOUND")
      return res.status(404).json({ error: "Item não encontrado" });
    if (error.message === "NO_STOCK")
      return res.status(409).json({ error: "Estoque insuficiente" });
    console.error("Erro ao registrar movimento por código:", error);
    res.status(500).json({ error: "Falha ao registrar movimento" });
  } finally {
    await session.endSession();
  }
});

export default router;

// GET /movimentos/estoque - retorna documentos da coleção 'movimentos_estoque'
router.get('/estoque', async (req, res) => {
  try {
    const db = getDB();
    const filtro = {};
    // opcional: permitir filtro por codigo via query ?codigo=...
    if (req.query.codigo) filtro.codigoMaterial = req.query.codigo;

    const docs = await db
      .collection('movimentos_estoque')
      .find(filtro)
      .sort({ data: -1 })
      .limit(1000)
      .toArray();

    res.json(docs);
  } catch (err) {
    console.error('Erro ao listar movimentos_estoque', err);
    res.status(500).json({ error: 'Erro ao listar movimentos_estoque' });
  }
});
