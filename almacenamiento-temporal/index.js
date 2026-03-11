require('dotenv').config();
const express = require('express');
const multer = require('multer');
const TelegramBot = require('node-telegram-bot-api');
const fs = require('fs');
const path = require('path');

// --- Constantes y Configuración ---
const DB_FILE = path.resolve(__dirname, 'gallery.json');
const MEDIA_DIR = path.resolve(__dirname, 'storage-media');
const STORAGE_LIMIT_GB = Number(process.env.STORAGE_LIMIT_GB || '15');
const STORAGE_LIMIT_BYTES = Math.floor(STORAGE_LIMIT_GB * 1024 * 1024 * 1024);
const TELEGRAM_URL_CACHE_MS = 6 * 60 * 60 * 1000; // 6 horas

if (!fs.existsSync(MEDIA_DIR)) {
  fs.mkdirSync(MEDIA_DIR, { recursive: true });
}

if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, '[]');
}

const token = process.env.TELEGRAM_BOT_TOKEN;
const chatId = process.env.TELEGRAM_CHAT_ID;
const bot = token ? new TelegramBot(token) : null;

const app = express();
const port = process.env.PORT || 3000;

// --- Middleware ---
app.use(express.static('public'));
app.use('/media', express.static(MEDIA_DIR));
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// --- Funciones Auxiliares ---

function loadGallery() {
  return JSON.parse(fs.readFileSync(DB_FILE, 'utf8') || '[]');
}

function saveGallery(items) {
  fs.writeFileSync(DB_FILE, JSON.stringify(items, null, 2));
}

function getBaseUrl(req) {
  if (process.env.PUBLIC_BASE_URL) return process.env.PUBLIC_BASE_URL;
  return `${req.protocol}://${req.get('host')}`;
}

function sanitizeFilename(name) {
  return name.replace(/[^a-zA-Z0-9._-]/g, '_');
}

function bytesToGb(v) {
  return Number((v / (1024 * 1024 * 1024)).toFixed(3));
}

function getLocalStorageUsage(galleryData) {
  let used = 0;
  for (const item of galleryData) {
    if (item.storageBackend === 'local' && item.localPath && fs.existsSync(item.localPath)) {
      try {
        const stats = fs.statSync(item.localPath);
        used += stats.size;
      } catch (_) {}
    }
  }
  return used;
}

function getStorageStatus(galleryData) {
  const usedBytes = getLocalStorageUsage(galleryData);
  const freeBytes = Math.max(STORAGE_LIMIT_BYTES - usedBytes, 0);
  const usagePct = STORAGE_LIMIT_BYTES > 0 ? (usedBytes / STORAGE_LIMIT_BYTES) * 100 : 0;
  const localCount = galleryData.filter((x) => x.storageBackend === 'local').length;
  const telegramCount = galleryData.filter((x) => x.storageBackend === 'telegram').length;

  return {
    limitGb: STORAGE_LIMIT_GB,
    usedBytes,
    usedGb: bytesToGb(usedBytes),
    freeBytes,
    freeGb: bytesToGb(freeBytes),
    usagePct: Number(usagePct.toFixed(2)),
    localCount,
    telegramCount,
  };
}

function saveLocalMedia(buffer, originalname) {
  const fileName = `${Date.now()}_${Math.random().toString(16).slice(2, 8)}_${sanitizeFilename(originalname)}`;
  const fullPath = path.join(MEDIA_DIR, fileName);
  fs.writeFileSync(fullPath, buffer);
  return { fileName, fullPath };
}

function parseExpiresInSeconds(reqBody) {
  const raw = Number(reqBody.expiresInSec || '86400');
  if (!Number.isFinite(raw) || raw <= 0) return 86400;
  // Seguridad: mínimo 5 minutos, máximo 7 días
  return Math.min(Math.max(Math.floor(raw), 300), 604800);
}

async function getFileUrl(fileId) {
  try {
    if (!bot) return null;
    const file = await bot.getFile(fileId);
    return `https://api.telegram.org/file/bot${token}/${file.file_path}`;
  } catch (error) {
    console.error(`Error obteniendo URL para ${fileId}:`, error.message);
    return null;
  }
}

// Limpieza de historias expiradas (Cada 1 hora)
async function cleanupExpiredStories() {
  console.log('Iniciando limpieza de historias expiradas...');
  try {
    const galleryData = loadGallery();
    const now = Math.floor(Date.now() / 1000);
    
    const remaining = [];
    for (const item of galleryData) {
      if (item.isStory && item.expiresAt && item.expiresAt < now) {
        console.log(`Borrando historia expirada: ${item.id || item.file_id || item.filename}`);

        if (item.storageBackend === 'local' && item.localPath && fs.existsSync(item.localPath)) {
          try {
            fs.unlinkSync(item.localPath);
          } catch (_) {}
        }

        if (item.storageBackend === 'telegram' && bot && chatId) {
          try {
            await bot.deleteMessage(chatId, item.id);
          } catch (_) {}
        }
      } else {
        remaining.push(item);
      }
    }
    
    saveGallery(remaining);
    console.log('Limpieza completada.');
  } catch (err) {
    console.error('Error en limpieza:', err);
  }
}

setInterval(cleanupExpiredStories, 3600000); // 1 hora

// --- Rutas ---

app.get('/api/gallery', async (req, res) => {
  try {
    const galleryData = loadGallery();
    const limit = Math.min(Number(req.query.limit || '200'), 500);
    const offset = Math.max(Number(req.query.offset || '0'), 0);
    const nowMs = Date.now();

    const paged = galleryData.slice(offset, offset + limit);
    const result = [];

    for (const item of paged) {
      if (item.storageBackend === 'local') {
        const exists = item.localPath && fs.existsSync(item.localPath);
        if (!exists) continue;
        result.push({
          ...item,
          url: `${getBaseUrl(req)}/media/${encodeURIComponent(item.localFileName)}`,
        });
        continue;
      }

      // Telegram: usar cache de URL para no consultar siempre
      let telegramUrl = item.cachedTelegramUrl || null;
      const cachedAtMs = item.cachedTelegramUrlAt ? Number(item.cachedTelegramUrlAt) : 0;
      const isCacheFresh = telegramUrl && cachedAtMs > 0 && nowMs - cachedAtMs < TELEGRAM_URL_CACHE_MS;

      if (!isCacheFresh && item.file_id) {
        telegramUrl = await getFileUrl(item.file_id);
        item.cachedTelegramUrl = telegramUrl;
        item.cachedTelegramUrlAt = nowMs;
      }

      if (telegramUrl) {
        result.push({ ...item, url: telegramUrl });
      }
    }

    saveGallery(galleryData);
    res.status(200).json(result);
  } catch (err) {
    res.status(500).json({ message: 'Error interno' });
  }
});

app.get('/api/storage/status', (req, res) => {
  try {
    const galleryData = loadGallery();
    return res.status(200).json(getStorageStatus(galleryData));
  } catch (err) {
    return res.status(500).json({ message: 'Error interno' });
  }
});

app.post('/upload', upload.single('media'), async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'Sin archivo' });

  const { buffer, mimetype, originalname } = req.file;
  const extension = originalname.split('.').pop().toLowerCase();
  let fileType = mimetype.startsWith('image') ? 'photo' : 
                 (mimetype.startsWith('audio') ? 'audio' : 
                 (mimetype.startsWith('video') ? 'video' : 'document'));

  if (fileType === 'document' || mimetype === 'application/octet-stream') {
    if (['jpg', 'jpeg', 'png', 'gif'].includes(extension)) fileType = 'photo';
    else if (['mp4', 'mov'].includes(extension)) fileType = 'video';
    else if (['mp3', 'm4a'].includes(extension)) fileType = 'audio';
  }

  try {
    const galleryData = loadGallery();
    const storageStatus = getStorageStatus(galleryData);
    const isStory = req.body.isStory === 'true';
    const expiresInSec = parseExpiresInSeconds(req.body);
    const nowSec = Math.floor(Date.now() / 1000);
    const shouldTryLocal = isStory || req.body.preferLocal === 'true';
    const hasLocalSpace = storageStatus.freeBytes >= buffer.length;

    let newEntry;

    // 1) Local primero si hay espacio
    if (shouldTryLocal && hasLocalSpace) {
      const local = saveLocalMedia(buffer, originalname);
      newEntry = {
        id: `local_${Date.now()}`,
        file_id: null,
        filename: originalname,
        type: fileType,
        date: nowSec,
        isStory,
        expiresAt: isStory ? nowSec + expiresInSec : null,
        storageBackend: 'local',
        localPath: local.fullPath,
        localFileName: local.fileName,
        cachedTelegramUrl: null,
        cachedTelegramUrlAt: null,
        sizeBytes: buffer.length,
      };

      galleryData.unshift(newEntry);
      saveGallery(galleryData);

      return res.status(200).json({
        ok: true,
        ...newEntry,
        url: `${getBaseUrl(req)}/media/${encodeURIComponent(local.fileName)}`,
        media_url: `${getBaseUrl(req)}/media/${encodeURIComponent(local.fileName)}`,
        source: 'local',
        storage: getStorageStatus(galleryData),
      });
    }

    // 2) Fallback a Telegram si no hay espacio local
    if (!bot || !chatId) {
      return res.status(500).json({
        message: 'Sin espacio local y Telegram no configurado. Define TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID.',
      });
    }

    let sentMessage;
    const options = { filename: originalname, contentType: mimetype };

    if (fileType === 'photo') sentMessage = await bot.sendPhoto(chatId, buffer, {}, options);
    else if (fileType === 'audio') sentMessage = await bot.sendAudio(chatId, buffer, {}, options);
    else if (fileType === 'video') sentMessage = await bot.sendVideo(chatId, buffer, {}, options);
    else sentMessage = await bot.sendDocument(chatId, buffer, {}, options);

    let file_id;
    if (sentMessage.photo) file_id = sentMessage.photo.pop().file_id;
    else if (sentMessage.audio) file_id = sentMessage.audio.file_id;
    else if (sentMessage.video) file_id = sentMessage.video.file_id;
    else if (sentMessage.document) file_id = sentMessage.document.file_id;

    const initialUrl = await getFileUrl(file_id);
    newEntry = {
      id: sentMessage.message_id,
      file_id,
      filename: originalname,
      type: fileType,
      date: sentMessage.date,
      isStory,
      expiresAt: isStory ? (sentMessage.date + expiresInSec) : null,
      storageBackend: 'telegram',
      localPath: null,
      localFileName: null,
      cachedTelegramUrl: initialUrl,
      cachedTelegramUrlAt: Date.now(),
      sizeBytes: buffer.length,
    };

    galleryData.unshift(newEntry);
    saveGallery(galleryData);

    return res.status(200).json({
      ok: true,
      ...newEntry,
      url: initialUrl,
      media_url: initialUrl,
      source: 'telegram',
      storage: getStorageStatus(galleryData),
    });
  } catch (error) {
    console.error('Error upload:', error);
    res.status(500).json({ message: 'Error server' });
  }
});

app.get('/api/url/:fileId', async (req, res) => {
  const freshUrl = await getFileUrl(req.params.fileId);
  if (!freshUrl) return res.status(404).json({ message: 'Not found' });
  res.status(200).json({ url: freshUrl });
});

app.post('/api/cleanup', async (_req, res) => {
  await cleanupExpiredStories();
  return res.status(200).json({ ok: true });
});

app.listen(port, () => console.log(`Servidor listo en puerto ${port}`));
