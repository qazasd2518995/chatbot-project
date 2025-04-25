// src/App.js
import React, { useState } from 'react';
import Register from './Register';
import Login from './Login';
import Chat from './Chat';

function App() {
  const [user, setUser] = useState(null);
  const [view, setView] = useState('login'); // 可切換 'login'、'register'、'chat'

  const handleLogin = (userData) => {
    setUser(userData);
    setView('chat');
  };

  return (
    <div style={{ maxWidth: '800px', margin: '20px auto', padding: '10px' }}>
      {view === 'register' && (
        <Register onRegistered={() => setView('login')} />
      )}
      {view === 'login' && (
        <Login
          onLogin={handleLogin}
          onSwitchRegister={() => setView('register')}
        />
      )}
      {view === 'chat' && <Chat user={user} />}
    </div>
  );
}

export default App;
