import { useState } from 'react';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Sidebar from './components/Sidebar';
import ErrorBoundary from './components/ErrorBoundary';
import Login from './pages/Login';
import Signup from './pages/Signup';
import Dashboard from './pages/Dashboard';
import Customers from './pages/Customers';
import Employees from './pages/Employees';
import Firmware from './pages/Firmware';
import Deactivated from './pages/Deactivated';
import AppUsers from './pages/AppUsers';
import Products from './pages/Products';

const AppContent = () => {
  const { isAuthenticated, loading, isDeactivated } = useAuth();
  const [authView, setAuthView] = useState('login'); // 'login' or 'signup'
  const [activePage, setActivePage] = useState('dashboard'); // 'dashboard', 'crm', 'employees', 'firmware'

  // 1. Initial Session Verification spinner
  if (loading) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
        background: 'hsl(var(--bg-deep))',
        gap: '16px'
      }}>
        <div style={{
          width: '50px',
          height: '50px',
          border: '4px solid rgba(255, 125, 0, 0.1)',
          borderTopColor: 'var(--primary)',
          borderRadius: '50%',
          animation: 'spin-slow 1s linear infinite'
        }}></div>
        <p style={{ color: 'var(--text-secondary)', fontWeight: 600, fontSize: '15px', letterSpacing: '1px' }}>
          VERIFYING SECURITY KEYS...
        </p>
      </div>
    );
  }

  // 2. Unauthenticated branch
  if (!isAuthenticated) {
    return authView === 'login' ? (
      <Login onNavigate={setAuthView} />
    ) : (
      <Signup onNavigate={setAuthView} />
    );
  }

  // 3. Authenticated but Deactivated/Suspended branch
  if (isDeactivated) {
    return <Deactivated />;
  }

  // 4. Authenticated & Active workspace branch
  return (
    <div className="app-container">
      {/* Sidebar Nav */}
      <Sidebar activePage={activePage} setActivePage={setActivePage} />

      {/* Main Panel Viewport */}
      <main className="main-content">
        <ErrorBoundary key={activePage}>
          {activePage === 'dashboard' && <Dashboard />}
          {activePage === 'app-users' && <AppUsers />}
          {activePage === 'products' && <Products />}
          {activePage === 'sales' && <Customers />}
          {activePage === 'employees' && <Employees />}
          {activePage === 'firmware' && <Firmware />}
        </ErrorBoundary>
      </main>
    </div>
  );
};

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
