const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

// Ensure temporary upload directory exists
const uploadDir = path.join(__dirname, '../../uploads/temp');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configurable max file size (default 10MB)
const maxMb = parseInt(process.env.MAX_IMAGE_SIZE_MB || '10', 10);
const maxFileSize = maxMb * 1024 * 1024;

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Generate safe temporary filename
    const safeExt = path.extname(file.originalname).toLowerCase() || '.jpg';
    const randomName = `${Date.now()}_${crypto.randomBytes(8).toString('hex')}${safeExt}`;
    cb(null, randomName);
  }
});

const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  
  if (allowedMimeTypes.includes(file.mimetype.toLowerCase())) {
    cb(null, true);
  } else {
    const error = new Error(`Unsupported image format: '${file.mimetype}'. Allowed formats: JPEG, PNG, WEBP.`);
    error.code = 'UNSUPPORTED_IMAGE_FORMAT';
    error.status = 400;
    cb(error, false);
  }
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: maxFileSize
  },
  fileFilter: fileFilter
});

module.exports = {
  uploadImage: upload.single('image')
};
