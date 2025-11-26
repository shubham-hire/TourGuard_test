/**
 * Database configuration and connection pool (SQLite Adapter)
 * Mimics pg library interface but uses sqlite3
 */

import sqlite3 from 'sqlite3';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

// Path to the shared database file (created by tourguard-backend Final)
// Adjust path to point to: ../../../tourguard-backend Final/database.sqlite
const dbPath = path.resolve(__dirname, '../../../../tourguard-backend Final/database.sqlite');
console.log('Connecting to SQLite database at:', dbPath);

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database:', err.message);
    } else {
        console.log('Connected to the SQLite database.');
    }
});

// Wrapper to mimic pg Pool
// @ts-ignore
const pool = {
    query: <T = any>(text: string, params: any[] = []): Promise<{ rows: T[], rowCount: number }> => {
        return new Promise((resolve, reject) => {
            // Convert Postgres parameter syntax ($1, $2, etc.) to SQLite (?)
            let sqliteQuery = text.replace(/\$\d+/g, '?');

            // Convert Postgres NOW() to SQLite datetime('now')
            sqliteQuery = sqliteQuery.replace(/NOW\(\)/gi, "datetime('now')");

            // Log for debugging
            // console.log('SQL:', sqliteQuery, params);

            if (sqliteQuery.trim().toUpperCase().startsWith('SELECT')) {
                db.all(sqliteQuery, params, (err, rows) => {
                    if (err) {
                        console.error('Query error:', err.message, sqliteQuery);
                        reject(err);
                    } else {
                        resolve({
                            rows: rows as T[],
                            rowCount: rows ? rows.length : 0
                        });
                    }
                });
            } else {
                db.run(sqliteQuery, params, function (err) {
                    if (err) {
                        console.error('Query error:', err.message, sqliteQuery);
                        reject(err);
                    } else {
                        // 'this' contains lastID and changes
                        resolve({
                            rows: [],
                            rowCount: this.changes
                        });
                    }
                });
            }
        });
    },
    end: () => {
        return new Promise<void>((resolve, reject) => {
            db.close((err) => {
                if (err) reject(err);
                else resolve();
            });
        });
    },
    on: (event: string, callback: Function) => {
        // No-op for 'error' event
    }
};

export default pool;
