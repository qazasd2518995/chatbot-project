// server.js
const express = require('express');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
const cors = require('cors');
const fetch = require('node-fetch');

// 建立 app 實例
const app = express();

app.use(cors());
app.use(bodyParser.json());

// 建立資料庫連線池
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'Xiang0116.',
  database: 'chatbot_db',
  waitForConnections: true,
  connectionLimit: 10,
});

// ========== 整合 Ollama Gemma 模型 ==========
// 修改 getBotResponse 函式中的 model 參數
async function getBotResponse(userMessage) {
    try {
      const response = await fetch('http://localhost:11434/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'gemma3:1b',
          prompt: userMessage,
          temperature: 0.7
        }),
      });
  
      const ndjson = await response.text();
      console.log("Ollama NDJSON response:", ndjson);
  
      let finalAnswer = '';
      const lines = ndjson.split('\n');
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed) continue;
        try {
          const jsonLine = JSON.parse(trimmed);
          if (jsonLine.done) break;
          if (jsonLine.response) {  // 修改這裡，使用 response 欄位
            finalAnswer += jsonLine.response;
          }
        } catch (parseErr) {
          console.error("解析NDJSON錯誤:", parseErr);
        }
      }
  
      return finalAnswer || '抱歉，我暫時沒有回應。';
    } catch (error) {
      console.error('呼叫 Ollama 發生錯誤：', error);
      return '抱歉，模型暫時無法回應。';
    }
  }
  
   

// ========== 以下為原本的 API 路由 ==========

// 使用者註冊 API
app.post('/register', async (req, res) => {
  const { username, password } = req.body;
  try {
    const [rows] = await pool.query('SELECT * FROM Users WHERE username = ?', [username]);
    if (rows.length > 0) {
      return res.status(400).json({ message: '使用者已存在' });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    await pool.query(
      'INSERT INTO Users (username, password_hash, created_at) VALUES (?, ?, NOW())',
      [username, hashedPassword]
    );
    res.status(201).json({ message: '註冊成功' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 使用者登入 API
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const [rows] = await pool.query('SELECT * FROM Users WHERE username = ?', [username]);
    if (rows.length === 0) {
      return res.status(400).json({ message: '使用者不存在' });
    }
    const user = rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(400).json({ message: '密碼錯誤' });
    }
    // 簡單回傳 userId，或可改用 JWT token
    res.json({ message: '登入成功', userId: user.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 聊天 API
app.post('/chat', async (req, res) => {
  const { userId, message } = req.body;
  try {
    // 呼叫本地模型取得回覆
    const botResponse = await getBotResponse(message);

    // 儲存聊天記錄
    await pool.query(
      'INSERT INTO ChatLogs (user_id, user_message, bot_response, timestamp) VALUES (?, ?, ?, NOW())',
      [userId, message, botResponse]
    );

    // 回傳給前端
    res.json({ botResponse });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 管理者查詢聊天記錄 API (可加入驗證機制)
app.get('/admin/logs', async (req, res) => {
  try {
    const [logs] = await pool.query('SELECT * FROM ChatLogs ORDER BY timestamp DESC');
    res.json({ logs });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
