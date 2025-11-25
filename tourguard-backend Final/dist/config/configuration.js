"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = () => ({
    PORT: parseInt(process.env.PORT, 10) || 3000,
    DATABASE_HOST: process.env.DATABASE_HOST || 'localhost',
    DATABASE_PORT: parseInt(process.env.DATABASE_PORT, 10) || 5432,
    DATABASE_USER: process.env.DATABASE_USER || 'tourguard',
    DATABASE_PASSWORD: process.env.DATABASE_PASSWORD || 'secret',
    DATABASE_NAME: process.env.DATABASE_NAME || 'tourguard_db',
    JWT_SECRET: process.env.JWT_SECRET || 'secret',
    JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '3600s',
    BCRYPT_SALT: parseInt(process.env.BCRYPT_SALT, 10) || 10,
});
