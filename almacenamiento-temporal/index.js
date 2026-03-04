require('dotenv').config();
const express = require('express');
const multer = require('multer');
const TelegramBot = require('node-telegram-bot-api');
const fs = require('fs');

// --- Constantes y Configuración ---
const DB_FILE = './gallery.json';

if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, '[]');
}

const token = process.env.TELEGRAM_BOT_TOKEN;
const chatId = process.env.TELEGRAM_CHAT_ID;
const bot = new TelegramBot(token);

const app = express();
const port = process.env.PORT || 3000;

// --- Middleware ---
app.use(express.static('public'));
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// --- Funciones Auxiliares ---

async function getFileUrl(fileId) {
  try {
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
    const galleryData = JSON.parse(fs.readFileSync(DB_FILE, 'utf8') || '[]');
    const now = Math.floor(Date.now() / 1000);
    
    const remaining = [];
    for (const item of galleryData) {
      if (item.isStory && item.expiresAt && item.expiresAt < now) {
        console.log(`Borrando historia expirada: ${item.file_id}`);
        // Intentar borrar de Telegram (opcional, puede fallar si es muy viejo)
        try { await bot.deleteMessage(chatId, item.id); } catch (e) {}
      } else {
        remaining.push(item);
      }
    }
    
    fs.writeFileSync(DB_FILE, JSON.stringify(remaining, null, 2));
    console.log('Limpieza completada.');
  } catch (err) {
    console.error('Error en limpieza:', err);
  }
}

setInterval(cleanupExpiredStories, 3600000); // 1 hora

// --- Rutas ---

app.get('/api/gallery', async (req, res) => {
  try {
    const galleryData = JSON.parse(fs.readFileSync(DB_FILE, 'utf8') || '[]');
    const galleryWithFreshUrls = await Promise.all(
      galleryData.map(async (item) => {
        const freshUrl = await getFileUrl(item.file_id);
        return { ...item, url: freshUrl };
      })
    );
    res.status(200).json(galleryWithFreshUrls.filter(item => item.url !== null));
  } catch (err) {
    res.status(500).json({ message: 'Error interno' });
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
    const galleryData = JSON.parse(fs.readFileSync(DB_FILE, 'utf8') || '[]');
    const newEntry = {
      id: sentMessage.message_id,
      file_id, 
      filename: originalname,
      type: fileType,
      date: sentMessage.date,
      isStory: req.body.isStory === 'true',
      expiresAt: req.body.isStory === 'true' ? (sentMessage.date + 86400) : null
    };
    
    galleryData.unshift(newEntry);
    fs.writeFileSync(DB_FILE, JSON.stringify(galleryData, null, 2));
    res.status(200).json({ ...newEntry, url: initialUrl });
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

app.listen(port, () => console.log(`Servidor listo en puerto ${port}`));
