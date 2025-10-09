import '../src/config.js';
import bcrypt from 'bcryptjs';
import { config } from '../src/config.js';

const senha = process.argv[2] || 'admin123';

const hash = await bcrypt.hash(senha, config.bcryptRounds);
console.log(JSON.stringify({ senha, hash }, null, 2));
process.exit(0);