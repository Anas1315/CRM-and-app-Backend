import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Activity, Mail, Lock, AlertCircle } from 'lucide-react';

const Login = ({ onNavigate }) => {
  const { login } = useAuth();
  const [email,    setEmail]    = useState('');
  const [password, setPassword] = useState('');
  const [error,    setError]    = useState('');
  const [loading,  setLoading]  = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email || !password) { setError('Both fields are required'); return; }
    setError(''); setLoading(true);
    try {
      await login(email, password);
    } catch (err) {
      setError(err.message || 'Invalid credentials');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-wrapper">
      <div className="glass-panel auth-card slide-in">
        {/* Logo */}
        <div className="auth-header">
          <div className="auth-logo">
            <div style={{
              background: 'linear-gradient(135deg,hsl(var(--primary)) 0%,#ff5500 100%)',
              width: '36px', height: '36px', borderRadius: '8px',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <Activity size={18} className="spin-slow" color="#fff" />
            </div>
            <span className="text-gradient">SOLAR CRM</span>
          </div>
          <p className="auth-subtitle">Staff Management Portal — sign in with your CRM credentials</p>
        </div>

        {/* Demo hint */}
        <div style={{
          background: 'rgba(59,130,246,.08)', border: '1px solid rgba(59,130,246,.2)',
          borderRadius: '10px', padding: '10px 14px', fontSize: '12px',
          color: '#93c5fd', marginBottom: '20px', lineHeight: '1.5'
        }}>
          <strong>Demo:</strong> crm-admin@solar.com / admin123
        </div>

        {error && (
          <div style={{
            background: 'rgba(239,68,68,.12)', border: '1px solid rgba(239,68,68,.3)',
            borderRadius: '8px', color: '#ef4444', padding: '10px 14px',
            fontSize: '13px', marginBottom: '18px', display: 'flex', gap: '8px', alignItems: 'center'
          }}>
            <AlertCircle size={14} /> {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="login-email">CRM Staff Email</label>
            <div style={{ position: 'relative' }}>
              <span style={{ position: 'absolute', left: '13px', top: '13px', color: 'var(--text-muted)' }}>
                <Mail size={16} />
              </span>
              <input id="login-email" type="email" className="glass-input"
                placeholder="admin@solar.com" value={email}
                onChange={e => setEmail(e.target.value)} style={{ paddingLeft: '42px' }} disabled={loading} />
            </div>
          </div>

          <div className="form-group" style={{ marginBottom: '24px' }}>
            <label htmlFor="login-password">Password</label>
            <div style={{ position: 'relative' }}>
              <span style={{ position: 'absolute', left: '13px', top: '13px', color: 'var(--text-muted)' }}>
                <Lock size={16} />
              </span>
              <input id="login-password" type="password" className="glass-input"
                placeholder="••••••••" value={password}
                onChange={e => setPassword(e.target.value)} style={{ paddingLeft: '42px' }} disabled={loading} />
            </div>
          </div>

          <button type="submit" className="glass-btn primary"
            style={{ width: '100%', padding: '12px', justifyContent: 'center' }} disabled={loading}>
            {loading ? 'Verifying...' : 'Access CRM Portal'}
          </button>
        </form>

        <div className="auth-footer">
          New CRM staff member?{' '}
          <button onClick={() => onNavigate('signup')} className="auth-link"
            style={{ background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: 'inherit' }}>
            Register Here
          </button>
        </div>
      </div>
    </div>
  );
};

export default Login;
