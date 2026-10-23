// ai.routes.js
// Paste this into your Node.js/Express backend routes folder
// Make sure to hook it up in your app.js or server.js like:
// const aiRoutes = require('./routes/ai.routes');
// app.use('/api/ai', aiRoutes);

const express = require('express');
const router = express.Router();
const multer = require('multer');
const aiController = require('../controllers/ai.controller');
// const { protect } = require('../middlewares/auth.middleware');

// Setup multer for memory storage for vision/subtitles
// Be careful with file size limits in production
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }
});

// Protect all AI routes so only logged in users can consume quotas
// router.use(protect);

// Generate Caption + Hashtags from text
router.post('/captions', aiController.generateCaption);

// Vision: Analyze image and generate caption + hashtags
router.post('/vision', upload.single('image'), aiController.analyzeImage);

// Generate Smart Replies for Comments
router.post('/comment-replies', aiController.generateCommentReplies);

// Generate Smart Replies for Chat
router.post('/chat-replies', aiController.generateChatReplies);
// Generate Subtitles (Requires Gemini Audio capabilities or transcription service)
router.post('/subtitles', upload.single('video'), aiController.generateSubtitles);
module.exports = router;