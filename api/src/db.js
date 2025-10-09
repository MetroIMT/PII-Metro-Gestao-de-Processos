import { MongoClient } from 'mongodb';
import { config } from './config.js';

let client;
let db;

export async function connectDB() {
  if (!client) {
    client = new MongoClient(config.mongoUri);
    await client.connect();
    console.log('MongoDB conectado');
  }

  if (!db) {
    db = client.db(config.dbName);
  }

  return db;
}

export function getDB() {
  if (!db) {
    throw new Error('Banco não conectado. Chame connectDB() primeiro.');
  }
  return db;
}

export function getClient() {
  if (!client) {
    throw new Error('Cliente Mongo não conectado. Chame connectDB() primeiro.');
  }
  return client;
}