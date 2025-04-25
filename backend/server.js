// server.js

require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
const cors = require('cors');
const fetch = require('node-fetch');

const app = express();
const port = process.env.PORT || 3000;

// --- Middleware ---
app.use(cors({ origin: '*' }));
app.use(bodyParser.json());

// --- Database pool ---
const pool = mysql.createPool({
  host:     process.env.DB_HOST     || 'localhost',
  user:     process.env.DB_USER     || 'root',
  password: process.env.DB_PASSWORD || 'rootpw',  // 使用與docker-compose相同的預設密碼
  database: process.env.DB_NAME     || 'ChatbotDB',  // 修改為與 SQL 初始化腳本匹配
  waitForConnections: true,
  connectionLimit:   10,
  charset:   'utf8mb4'
});

// --- Helper: call Ollama Gemma3 model ---
async function getBotResponse(userMessage) {
  try {
    const response = await fetch(process.env.OLLAMA_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gemma3:1b',
        prompt: userMessage,
        temperature: 0.7
      }),
    });

    const ndjson = await response.text();
    console.log('Ollama NDJSON response:', ndjson);

    let finalAnswer = '';
    for (const line of ndjson.split('\n')) {
      if (!line.trim()) continue;
      const parsed = JSON.parse(line);
      if (parsed.done) break;
      if (parsed.response) finalAnswer += parsed.response;
    }
    return finalAnswer || '抱歉，我暫時沒有回應。';
  } catch (err) {
    console.error('Error calling Ollama:', err);
    return '抱歉，模型暫時無法回應。';
  }
}

// --- API routes mounted under /api ---
const router = express.Router();

// POST /api/register
router.post('/register', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ message: '請提供 username 和 password' });
  }
  try {
    console.log('嘗試註冊用戶:', username); // 添加日誌

    // 檢查用戶是否已存在
    const [rows] = await pool.query(
      'SELECT id FROM Users WHERE username = ?',
      [username]
    );
    if (rows.length) {
      return res.status(400).json({ message: '使用者已存在' });
    }

    // 生成密碼哈希
    const hash = await bcrypt.hash(password, 10);
    
    console.log('插入新用戶到資料庫'); // 添加日誌
    
    // 插入新用戶
    await pool.query(
      'INSERT INTO Users (username, password_hash, created_at) VALUES (?, ?, NOW())',
      [username, hash]
    );
    
    console.log('註冊成功:', username); // 添加日誌
    res.status(201).json({ message: '註冊成功' });
  } catch (err) {
    console.error('註冊過程中發生錯誤:', err);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// POST /api/login
router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ message: '請提供 username 和 password' });
  }
  try {
    const [rows] = await pool.query(
      'SELECT id, password_hash FROM Users WHERE username = ?',
      [username]
    );
    if (!rows.length) {
      return res.status(400).json({ message: '使用者不存在' });
    }
    const user = rows[0];
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(400).json({ message: '密碼錯誤' });
    }
    res.json({ message: '登入成功', userId: user.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// POST /api/chat
router.post('/chat', async (req, res) => {
  const { userId, message } = req.body;
  if (!userId || !message) {
    return res.status(400).json({ message: '請提供 userId 和 message' });
  }
  try {
    const botResponse = await getBotResponse(message);
    await pool.query(
      'INSERT INTO ChatLogs (user_id, user_message, bot_response, timestamp) VALUES (?, ?, ?, NOW())',
      [userId, message, botResponse]
    );
    res.json({ botResponse });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// GET /api/admin/logs
router.get('/admin/logs', async (_req, res) => {
  try {
    const [logs] = await pool.query(
      'SELECT * FROM ChatLogs ORDER BY timestamp DESC'
    );
    res.json({ logs });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

app.use('/api', router);

// --- Start server ---
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
  console.log(`Using database: ${process.env.DB_NAME || 'ChatbotDB'}`);
});
