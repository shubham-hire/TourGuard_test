import { diskStorage } from 'multer';
import { extname } from 'path';

export const multerConfig = {
    storage: diskStorage({
        destination: './uploads/profile-photos',
        filename: (req, file, cb) => {
            const uniqueName = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}${extname(file.originalname)}`;
            cb(null, uniqueName);
        },
    }),
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
    fileFilter: (req, file, cb) => {
        // Accept common image formats including mobile formats (webp, heic)
        const allowedMimes = /image\/(jpg|jpeg|png|webp|heic|heif)$/;
        const allowedExts = /\.(jpg|jpeg|png|webp|heic|heif)$/i;
        
        if (allowedMimes.test(file.mimetype) || allowedExts.test(file.originalname)) {
            cb(null, true);
        } else {
            console.log(`Rejected file: ${file.originalname}, mimetype: ${file.mimetype}`);
            return cb(new Error(`Image format not allowed. Got: ${file.mimetype}`), false);
        }
    },
};
