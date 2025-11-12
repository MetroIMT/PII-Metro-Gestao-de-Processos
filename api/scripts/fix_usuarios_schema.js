import "dotenv/config";
import { MongoClient } from "mongodb";

const MONGO_URI = process.env.MONGODB_URI;
const DB_NAME = process.env.MONGODB_DB || "gestao-de-processos-metroimt";

if (!MONGO_URI) {
  console.error("❌ MONGODB_URI não está definido no .env");
  process.exit(1);
}

async function fixSchema() {
  console.log("🔌 Conectando ao MongoDB...");
  console.log(
    "   URI:",
    MONGO_URI.replace(/\/\/([^:]+):([^@]+)@/, "//$1:****@")
  ); // Esconde senha
  console.log("   Database:", DB_NAME);

  const client = await MongoClient.connect(MONGO_URI);
  const db = client.db(DB_NAME);

  try {
    console.log("🔄 Atualizando schema da coleção usuarios...");

    // Remove a validação atual
    await db.command({
      collMod: "usuarios",
      validator: {},
      validationLevel: "off",
    });

    console.log("✅ Schema atualizado com sucesso!");
    console.log("   - Validação removida para permitir cpf e telefone");
    console.log("   - Agora você pode adicionar usuários normalmente");
  } catch (error) {
    console.error("❌ Erro ao atualizar schema:", error);
  } finally {
    await client.close();
  }
}

fixSchema();
