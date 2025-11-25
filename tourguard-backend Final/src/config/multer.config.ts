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
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png)$/)) {
            return cb(new Error('Only JPEG/PNG images allowed'), false);
        }
        cb(null, true);
    },
};
