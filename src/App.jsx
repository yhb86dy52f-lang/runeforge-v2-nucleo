import React, { useState } from 'react';
import axios from 'axios';

function App() {
  const [message, setMessage] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);

  const sendMessage = async () => {
    if (!message.trim()) return;
    setLoading(true);
    try {
      const res = await axios.post('http://localhost:3100/api/chat', { message });
      setResponse(res.data.reply || res.data);
    } catch (err) {
      setResponse('Error de conexión: ' + err.message);
    }
    setLoading(false);
  };

  return (
    <div style={{ padding: '2rem', maxWidth: '600px', margin: 'auto', fontFamily: 'sans-serif', background: '#0d0d0d', color: '#fff', minHeight: '100vh' }}>
      <h1 style={{ color: '#00FF66' }}>⚡ RUNEFORGE CHAT</h1>
      <textarea
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        rows="4"
        style={{ width: '100%', padding: '0.5rem', fontSize: '1rem', background: '#1a1a1a', color: '#fff', border: '1px solid #333' }}
        placeholder="Escribe tu mensaje..."
      />
      <button onClick={sendMessage} disabled={loading} style={{ marginTop: '0.5rem', padding: '0.5rem 1rem', background: '#00FF66', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}>
        {loading ? 'Pensando...' : 'Enviar'}
      </button>
      {response && (
        <div style={{ marginTop: '1rem', padding: '1rem', background: '#1a1a1a', color: '#d0d0d0', borderRadius: '8px', border: '1px solid #333' }}>
          <strong>Respuesta:</strong>
          <pre style={{ whiteSpace: 'pre-wrap' }}>{response}</pre>
        </div>
      )}
    </div>
  );
}

export default App;
