import express from 'express';
import { getDB } from '../db.js';

const router = express.Router();

// GET /materiais?tipo=giro  - lista materiais, opcionalmente filtrando por tipo
router.get('/', async (req, res) => {
  try {
    const db = getDB();
    const filtro = {};
    if (req.query.tipo) filtro.tipo = req.query.tipo;

    const materiais = await db.collection('materiais').find(filtro).toArray();
    res.json(materiais);
  } catch (err) {
    console.error('Erro ao listar materiais', err);
    res.status(500).json({ error: 'Erro ao listar materiais' });
  }
});

// POST /materiais - cria um material (aceita campo `tipo` no body)
router.post('/', async (req, res) => {
  try {
    const db = getDB();
    const body = req.body ?? {};

    if (!body.codigo || !body.nome) {
      return res.status(400).json({ error: 'Campos "codigo" e "nome" são obrigatórios' });
    }

    const quantidade = Number(body.quantidade ?? 0);

    const doc = {
      codigo: body.codigo,
      nome: body.nome,
      quantidade: Number.isNaN(quantidade) ? 0 : quantidade,
      local: body.local ?? '',
      vencimento: body.vencimento ? new Date(body.vencimento) : null,
      tipo: body.tipo ?? null,
      criadoEm: new Date(),
    };

    const result = await db.collection('materiais').insertOne(doc);
    doc._id = result.insertedId;
    res.status(201).json(doc);
  } catch (err) {
    console.error('Erro ao criar material', err);
    res.status(500).json({ error: 'Erro ao criar material' });
  }
});

// POST /materiais/giro - cria material e força tipo = 'giro'
router.post('/giro', async (req, res) => {
  try {
    const db = getDB();
    const body = req.body ?? {};

    if (!body.codigo || !body.nome) {
      return res.status(400).json({ error: 'Campos "codigo" e "nome" são obrigatórios' });
    }

    const quantidade = Number(body.quantidade ?? 0);

    const doc = {
      codigo: body.codigo,
      nome: body.nome,
      quantidade: Number.isNaN(quantidade) ? 0 : quantidade,
      local: body.local ?? '',
      vencimento: body.vencimento ? new Date(body.vencimento) : null,
      tipo: 'giro',
      criadoEm: new Date(),
    };

    const result = await db.collection('materiais').insertOne(doc);
    doc._id = result.insertedId;
    res.status(201).json(doc);
  } catch (err) {
    console.error('Erro ao criar material (giro)', err);
    res.status(500).json({ error: 'Erro ao criar material' });
  }
});

export default router;
