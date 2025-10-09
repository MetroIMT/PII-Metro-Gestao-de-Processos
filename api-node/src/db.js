import { MongoClient } from 'mongodb';
import { config } from './config.js';

let client;
let db;

export async function connectDB() {
  client = new MongoClient(config.mongoUri);
  await client.connect();
  db = client.db(config.dbName);
  console.log('MongoDB conectado');
  return db;
}

export function getDB() {
  if (!db) throw new Error('Banco não conectado');
  return db;
}

export function getClient() {
  if (!client) throw new Error('Cliente Mongo não conectado');
  return client;
}