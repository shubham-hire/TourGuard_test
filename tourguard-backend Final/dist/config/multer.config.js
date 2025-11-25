"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.multerConfig = void 0;
const multer_1 = require("multer");
const path_1 = require("path");
exports.multerConfig = {
    storage: (0, multer_1.diskStorage)({
        destination: './uploads/profile-photos',
        filename: (req, file, cb) => {
            const uniqueName = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}${(0, path_1.extname)(file.originalname)}`;
            cb(null, uniqueName);
        },
    }),
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png)$/)) {
            return cb(new Error('Only JPEG/PNG images allowed'), false);
        }
        cb(null, true);
    },
};
