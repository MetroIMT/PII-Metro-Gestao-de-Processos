export async function ensureIndexes(db) {
  // Instrumentos
  await db
    .collection("instrumentos")
    .createIndex({ codigoInterno: 1 }, { unique: true });
  await db.collection("instrumentos").createIndex({ validadeCalibracao: 1 });
  await db.collection("instrumentos").createIndex({ status: 1 });
  // Índice composto útil para buscas por status e vencimento
  await db
    .collection("instrumentos")
    .createIndex({ status: 1, validadeCalibracao: 1 });

  // Ferramentas
  await db
    .collection("ferramentas")
    .createIndex({ codigoInterno: 1 }, { unique: true });
  await db.collection("ferramentas").createIndex({ atualizadoEm: 1 });

  // Usuários
  await db.collection("usuarios").createIndex({ email: 1 }, { unique: true });
  await db.collection("usuarios").createIndex({ role: 1 });
  await db.collection("usuarios").createIndex({ ativo: 1 });
}
