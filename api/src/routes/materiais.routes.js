import express from 'express';
import { getDB, getClient } from '../db.js';
import { ObjectId } from 'mongodb';

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

// POST /materiais/movimentar - realiza uma movimentação de entrada ou saída
router.post('/movimentar', async (req, res) => {
  const { codigo, tipo, quantidade, usuario, local } = req.body;

  // 1. Validação básica
  if (!codigo || !tipo || !quantidade || !usuario || !local) {
    return res.status(400).json({
      error: 'Campos "codigo", "tipo", "quantidade", "usuario" e "local" são obrigatórios.',
    });
  }

  if (tipo !== 'entrada' && tipo !== 'saida') {
    return res.status(400).json({ error: 'O campo "tipo" deve ser "entrada" ou "saida".' });
  }

  const qtd = parseInt(quantidade, 10);
  if (isNaN(qtd) || qtd <= 0) {
    return res.status(400).json({ error: 'A "quantidade" deve ser um número positivo.' });
  }

  const client = getClient();
  const session = client.startSession();

  try {
    await session.withTransaction(async () => {
      const db = getDB();
      const materiaisCollection = db.collection('materiais');
      const movimentosCollection = db.collection('movimentos');

      // 2. Encontrar o material
      const material = await materiaisCollection.findOne({ codigo: codigo }, { session });

      if (!material) {
        throw new Error(`Material com código "${codigo}" não encontrado.`);
      }

      let novaQuantidade;
      // 3. Validar e calcular novo estoque
      if (tipo === 'saida') {
        if (material.quantidade < qtd) {
          throw new Error(`Estoque insuficiente para o material "${material.nome}". Disponível: ${material.quantidade}, Requisitado: ${qtd}.`);
        }
        novaQuantidade = material.quantidade - qtd;
      } else { // entrada
        novaQuantidade = material.quantidade + qtd;
      }

      // 4. Ação 1: Atualizar a quantidade na coleção "materiais"
      const updateResult = await materiaisCollection.updateOne(
        { _id: material._id },
        { $set: { quantidade: novaQuantidade } },
        { session }
      );

      if (updateResult.modifiedCount === 0) {
          throw new Error('Não foi possível atualizar o estoque do material.');
      }

      // 5. Ação 2: Inserir o registro na coleção "movimentos"
      const movimento = {
        codigoMaterial: material.codigo,
        descricao: material.nome,
        quantidade: qtd,
        tipo: tipo === 'entrada' ? 'Entrada' : 'Saída', // Padronizando para o front-end
        usuario: usuario,
        local: local,
        data: new Date(),
      };

      await movimentosCollection.insertOne(movimento, { session });
    });

    // Se a transação for bem-sucedida
    res.status(200).json({ message: 'Movimentação realizada com sucesso.' });

  } catch (err) {
    console.error('Erro na transação de movimentação:', err);
    res.status(500).json({ error: err.message || 'Ocorreu um erro durante a movimentação do material.' });
  } finally {
    await session.endSession();
  }
});

export default router;
