import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { auth } from '../auth.js';
import { getClient, getDB } from '../db.js';

const router = Router();

router.get('/', auth(), async (req, res) => {
  const { itemId } = req.query;
  const filtro = {};
  if (itemId) filtro.itemId = new ObjectId(itemId);

  const db = getDB();
  const docs = await db
    .collection('movimentos')
    .find(filtro)
    .sort({ dataHora: -1 })
    .limit(200)
    .toArray();

  res.json(docs);
});

router.post('/', auth(), async (req, res) => {
  const { tipo, itemTipo, itemId, quantidade = 1, observacao } = req.body || {};
  if (!tipo || !itemTipo || !itemId) {
    return res.status(400).json({ error: 'Campos obrigatórios faltando' });
  }

  const db = getDB();
  const client = getClient();
  const col = itemTipo === 'instrumento' ? 'instrumentos' : 'ferramentas';
  const _id = new ObjectId(itemId);

  const session = client.startSession();
  try {
    await session.withTransaction(async () => {
      await db.collection('movimentos').insertOne(
        {
          tipo,
          itemTipo,
          itemId: _id,
          quantidade,
          usuarioId: new ObjectId(req.user.sub),
          observacao: observacao ?? null,
          dataHora: new Date(),
        },
        { session }
      );

      const inc =
        tipo === 'entrada' || tipo === 'devolucao' ? quantidade : -quantidade;
      const status =
        tipo === 'emprestimo'
          ? 'emprestada'
          : tipo === 'devolucao'
          ? 'disponivel'
          : undefined;

      const update = {
        $inc: { quantidade: inc },
        $set: { atualizadoEm: new Date() },
      };
      if (status) update.$set.status = status;

      await db.collection(col).updateOne({ _id }, update, { session });
    });

    res.status(201).json({ ok: true });
  } finally {
    await session.endSession();
  }
});

export default router;