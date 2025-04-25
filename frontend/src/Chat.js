// src/Chat.js
import React, { useState, useEffect, useRef } from 'react';
import { marked } from 'marked';
import DOMPurify from 'dompurify';

function Chat({ user }) {
  const [message, setMessage] = useState('');
  const [chatLog, setChatLog] = useState([]);
  const messagesEndRef = useRef(null);

  const sendMessage = async () => {
    if (!message.trim()) return;
    
    // 儲存使用者輸入訊息
    const currentMessage = message;
    
    // 先更新聊天記錄，加入使用者訊息及 placeholder 「思考中…」
    setChatLog(prev => [
      ...prev,
      { user: currentMessage, bot: "Reasoning…" }
    ]);
    
    // 清空輸入欄
    setMessage('');

    try {
      const response = await fetch('http://localhost:3001/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: user.userId, message: currentMessage })
      });
      const data = await response.json();
      
      // 更新最後一筆聊天記錄的機器人回覆
      setChatLog(prev => {
        const newChat = [...prev];
        newChat[newChat.length - 1].bot = data.botResponse;
        return newChat;
      });
    } catch (err) {
      console.error('Error:', err);
      setChatLog(prev => {
        const newChat = [...prev];
        newChat[newChat.length - 1].bot = "Error";
        return newChat;
      });
    }
  };

  // 當 chatLog 更新時，自動滾動到最底部
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [chatLog]);

  return (
    <div style={{ maxWidth: '800px', margin: '20px auto', padding: '10px' }}>
      <h2 style={{ textAlign: 'center', marginBottom: '20px' }}>
        Welcome {user.username} to the Chatbot
      </h2>
      <div style={{
        border: '1px solid #ccc',
        padding: '10px',
        height: '400px',
        overflowY: 'auto',
        marginBottom: '20px'
      }}>
        {chatLog.map((chat, index) => (
          <div key={index} style={{ marginBottom: '15px', padding: '8px', borderBottom: '1px solid #eee' }}>
            <div style={{ fontWeight: 'bold' }}>You：</div>
            <div style={{ marginBottom: '5px' }}>{chat.user}</div>
            <div style={{ fontWeight: 'bold' }}>Chatbot：</div>
            <div
              dangerouslySetInnerHTML={{
                __html: DOMPurify.sanitize(marked.parse(chat.bot ?? ''))
              }}
            />
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>
      <div style={{ display: 'flex', gap: '10px' }}>
        <input
          type="text"
          value={message}
          onChange={e => setMessage(e.target.value)}
          onKeyPress={e => {
            if (e.key === 'Enter') {
              sendMessage();
            }
          }}
          placeholder="Please enter your message"
          style={{ flex: 1, padding: '10px', fontSize: '16px' }}
        />
        <button
          onClick={sendMessage}
          style={{
            padding: '10px 20px',
            backgroundColor: '#1976d2',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontSize: '16px'
          }}
        >
          Send
        </button>
      </div>
    </div>
  );
}

export default Chat;
