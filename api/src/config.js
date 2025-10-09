import 'dotenv/config';

export const config = {
  port: Number(process.env.PORT ?? 8080),
  mongoUri: process.env.MONGODB_URI,
  dbName: process.env.MONGODB_DB ?? 'gestao-de-processos-metro',
  jwtSecret: process.env.JWT_SECRET,
  bcryptRounds: Number(process.env.BCRYPT_ROUNDS ?? 10),
};

if (!config.mongoUri || !config.jwtSecret) {
  throw new Error('Defina MONGODB_URI e JWT_SECRET no arquivo .env');
}