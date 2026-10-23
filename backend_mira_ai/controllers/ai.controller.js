// ai.controller.js
// Paste this into your Node.js/Express backend controllers folder
// Requires: npm install @google/genai

const { GoogleGenAI } = require('@google/genai');

// Ensure you have GEMINI_API_KEY in your server's .env file
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

// We use the recommended general model for most text/vision tasks
const MODEL_NAME = 'gemini-2.5-flash';

exports.generateCaption = async (req, res) => {
  try {
    const { prompt, tone = 'Casual', language = 'English', length = 'Short' } = req.body;

    if (!prompt) {
      return res.status(400).json({ message: 'Prompt is required' });
    }

    const systemInstruction = `You are Mira AI, a creative social media assistant.
    Write a ${length.toLowerCase()}, ${tone.toLowerCase()} caption in ${language} about the user's prompt.
    Do not invent facts. Also provide 3-5 highly relevant hashtags.
    Output format: Write the caption first, followed by a '#' separator, then the space-separated hashtags.`;

    const response = await ai.models.generateContent({
      model: MODEL_NAME,
      contents: prompt,
      config: {
        systemInstruction: systemInstruction,
        temperature: 0.7,
      }
    });

    res.status(200).json({ caption: response.text });
  } catch (error) {
    console.error('Mira AI Caption Error:', error);
    res.status(500).json({ message: 'Failed to generate caption' });
  }
};

exports.analyzeImage = async (req, res) => {
  try {
    const { tone = 'Aesthetic', language = 'English' } = req.body;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ message: 'Image file is required' });
    }

    // Convert multer buffer to base64 format required by Gemini
    const imagePart = {
      inlineData: {
        data: file.buffer.toString('base64'),
        mimeType: file.mimetype
      }
    };

    const systemInstruction = `You are Mira AI. Analyze this image.
    Write a creative, ${tone.toLowerCase()} caption in ${language}.
    Do not identify real people by name. Be concise.
    Output format: Return JSON exactly like this: {"caption": "your caption", "hashtags": ["tag1", "tag2"]}`;

    const response = await ai.models.generateContent({
      model: MODEL_NAME,
      contents: [imagePart, "Analyze this image and create a post"],
      config: {
        systemInstruction: systemInstruction,
        responseMimeType: "application/json",
      }
    });

    const result = JSON.parse(response.text);
    res.status(200).json(result);
  } catch (error) {
    console.error('Mira AI Vision Error:', error);
    res.status(500).json({ message: 'Failed to analyze image' });
  }
};

exports.generateCommentReplies = async (req, res) => {
  try {
    const { postCaption, parentComment } = req.body;

    const prompt = `Post context: "${postCaption}".
    The user received this comment: "${parentComment}".
    Generate 3 short, friendly, and distinct replies the user could send back.
    Format as JSON: {"replies": ["reply1", "reply2", "reply3"]}`;

    const response = await ai.models.generateContent({
      model: MODEL_NAME,
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        temperature: 0.8,
      }
    });

    const result = JSON.parse(response.text);
    res.status(200).json(result);
  } catch (error) {
    console.error('Mira AI Comment Replies Error:', error);
    res.status(500).json({ message: 'Failed to generate replies' });
  }
};

exports.generateChatReplies = async (req, res) => {
  try {
    const { recentMessages } = req.body; // Array of recent strings

    if (!recentMessages || !recentMessages.length) {
      return res.status(200).json({ replies: [] });
    }

    const prompt = `Recent chat history:
    ${recentMessages.map(m => "- " + m).join('\n')}

    You are the user receiving these messages. Generate 3 very short, casual, natural quick replies.
    Format as JSON: {"replies": ["reply1", "reply2", "reply3"]}`;

    const response = await ai.models.generateContent({
      model: MODEL_NAME,
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        temperature: 0.6, // slightly lower for predictable short chats
      }
    });

    const result = JSON.parse(response.text);
    res.status(200).json(result);
  } catch (error) {
    console.error('Mira AI Chat Replies Error:', error);
    res.status(500).json({ message: 'Failed to generate chat replies' });
  }
};

exports.generateSubtitles = async (req, res) => {
  // NOTE: For true video transcription, Gemini 2.5 Flash supports audio extraction if you upload via the File API.
  // However, for large videos, passing buffers inline will fail or exceed limits.
  // This is a simplified placeholder showing the intent. You must use the Gemini File API for real videos.
  try {
    res.status(200).json({
      subtitles: [
        { start: 0.0, end: 2.0, text: "Hey guys, welcome back!" },
        { start: 2.0, end: 4.5, text: "Today we are looking at Mira AI." }
      ]
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to generate subtitles' });
  }
};
