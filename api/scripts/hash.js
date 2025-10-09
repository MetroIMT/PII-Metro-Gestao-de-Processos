import '../src/config.js';
import bcrypt from 'bcryptjs';
import { config } from '../src/config.js';

const senha = process.argv[2] || 'admin123';

async function gerarHash() {
  try {
    const hash = await bcrypt.hash(senha, config.bcryptRounds);
    console.log(JSON.stringify({ senha, hash }, null, 2));
    process.exit(0);
  } catch (err) {
    console.error('Erro ao gerar hash:', err);
    process.exit(1);
  }
}

gerarHash();