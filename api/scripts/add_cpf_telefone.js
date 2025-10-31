import { connectDB } from "../src/db.js";

async function run() {
  const db = await connectDB();
  const col = db.collection("usuarios");

  // Set cpf to empty string where missing or null
  const resCpf = await col.updateMany(
    { $or: [{ cpf: { $exists: false } }, { cpf: null }] },
    { $set: { cpf: "" } }
  );

  // Set telefone to empty string where missing or null
  const resTel = await col.updateMany(
    { $or: [{ telefone: { $exists: false } }, { telefone: null }] },
    { $set: { telefone: "" } }
  );

  console.log(
    `cpf modifiedCount=${resCpf.modifiedCount}, matched=${resCpf.matchedCount}`
  );
  console.log(
    `telefone modifiedCount=${resTel.modifiedCount}, matched=${resTel.matchedCount}`
  );
  process.exit(0);
}

run().catch((err) => {
  console.error("Migration failed", err);
  process.exit(1);
});
