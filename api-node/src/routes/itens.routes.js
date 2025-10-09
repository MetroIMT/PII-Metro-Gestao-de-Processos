import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { getDB } from '../db.js';
import { auth, requireRole } from '../auth.js';

const router = Router();

router.get('/', auth(false), async (req, res) => {
  const { tipo, status } = req.query;
  const db = getDB();

  const col =
    tipo === 'instrumento'
      ? 'instrumentos'
      : tipo === 'ferramenta'
      ? 'ferramentas'
      : null;

  if (col) {
    const filtro = {};
    if (status) filtro.status = status;
    const itens = await db.collection(col).find(filtro).limit(200).toArray();
    return res.json(itens);
  }

  const filtro = status ? { status } : {};
  const [ferramentas, instrumentos] = await Promise.all([
    db.collection('ferramentas').find(filtro).toArray(),
    db.collection('instrumentos').find(filtro).toArray(),
  ]);

  res.json([
    ...ferramentas.map((doc) => ({ ...doc, tipo: 'ferramenta' })),
    ...instrumentos.map((doc) => ({ ...doc, tipo: 'instrumento' })),
  ]);
});

router.post('/', auth(), requireRole('admin'), async (req, res) => {
  const { tipo, ...payload } = req.body || {};
  const col = tipo === 'instrumento' ? 'instrumentos' : 'ferramentas';
  payload.criadoEm = new Date();

  const db = getDB();
  const result = await db.collection(col).insertOne(payload);
  res.status(201).json({ _id: result.insertedId, ...payload });
});

router.patch('/:id', auth(), requireRole('admin'), async (req, res) => {
  const { tipo, ...payload } = req.body || {};
  const col = tipo === 'instrumento' ? 'instrumentos' : 'ferramentas';
  payload.atualizadoEm = new Date();

  const db = getDB();
  await db
    .collection(col)
    .updateOne({ _id: new ObjectId(req.params.id) }, { $set: payload });

  res.json({ ok: true });
});

export default router;