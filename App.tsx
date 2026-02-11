import React from 'react';

const App: React.FC = () => {
  return (
    <div style={{
      fontFamily: 'system-ui, sans-serif',
      padding: '2rem',
      backgroundColor: '#121212',
      color: 'white',
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      gap: '1rem'
    }}>
      <header>
        <h1 style={{ margin: 0, color: '#00a2ff' }}>Roblox Lua Studio Lite</h1>
        <p style={{ opacity: 0.8 }}>Project Management & Script Generation Dashboard</p>
      </header>
      
      <main style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
        <section style={{ backgroundColor: '#1e1e1e', padding: '1.5rem', borderRadius: '8px' }}>
          <h2>Current Scripts</h2>
          <ul style={{ listStyle: 'none', padding: 0 }}>
            <li style={{ padding: '0.5rem 0', borderBottom: '1px solid #333' }}>📄 MainServer.lua</li>
            <li style={{ padding: '0.5rem 0', borderBottom: '1px solid #333' }}>📄 MainClient.lua</li>
          </ul>
        </section>
        
        <section style={{ backgroundColor: '#1e1e1e', padding: '1.5rem', borderRadius: '8px' }}>
          <h2>Active Systems</h2>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
            {['Store', 'Inventory', 'Stage', 'Fail', 'Save'].map(sys => (
              <span key={sys} style={{ 
                backgroundColor: '#00a2ff', 
                padding: '0.2rem 0.6rem', 
                borderRadius: '4px',
                fontSize: '0.8rem'
              }}>{sys}System</span>
            ))}
          </div>
        </section>
      </main>
      
      <footer style={{ marginTop: 'auto', borderTop: '1px solid #333', paddingTop: '1rem', textAlign: 'center', opacity: 0.5 }}>
        &copy; 2024 Roblox Lua Studio Lite • Powered by Gemini
      </footer>
    </div>
  );
};

export default App;
