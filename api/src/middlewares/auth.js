import jwt from "jsonwebtoken";
import { config } from "../config.js";
import { getDB } from "../db.js";
import { ObjectId } from "mongodb";

export function auth(required = true) {
  return (req, res, next) => {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;

    if (!token) {
      return required
        ? res.status(401).json({ error: "Token ausente" })
        : next();
    }

    try {
      const payload = jwt.verify(token, config.jwtSecret);
      req.user = payload; // { sub, role }
      // If the client sent a session id, update its lastSeen timestamp so
      // the sessions list reflects recent activity.
      const sessionId =
        req.headers["x-session-id"] || req.headers["X-Session-Id"];
      if (sessionId) {
        try {
          const db = getDB();
          // Try interpreting as ObjectId first
          let query = null;
          try {
            query = { _id: new ObjectId(String(sessionId)) };
          } catch (e) {
            // fallback to string id field
            query = { id: String(sessionId) };
          }
          db.collection("sessions")
            .updateOne(query, { $set: { lastSeen: new Date() } })
            .catch(() => {});
        } catch (e) {
          // ignore session update errors
        }
      }
      next();
    } catch (err) {
      return res.status(401).json({ error: "Token inválido" });
    }
  };
}

export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: "Não autorizado" });
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: "Acesso negado" });
    }
    next();
  };
}

// Middleware helper to require admin specifically
export function requireAdmin(req, res, next) {
  if (!req.user) return res.status(401).json({ error: "Não autorizado" });
  if (req.user.role !== "admin")
    return res.status(403).json({ error: "Acesso negado" });
  next();
}
