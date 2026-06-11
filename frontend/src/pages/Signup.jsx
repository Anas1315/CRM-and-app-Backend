import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Activity, Mail, Lock, User, ShieldCheck, Briefcase, AlertCircle } from 'lucide-react';

const Signup = ({ onNavigate }) => {
  const { signup } = useAuth();
  const [name,      setName]      = useState('');
  const [email,     setEmail]     = useState('');
  const [password,  setPassword]  = useState('');
  const [role,      setRole]      = useState('employee');
  const [dept,      setDept]      = useState('Sales');
  const [roleTitle, setRoleTitle] = useState('');
  const [error,     setError]     = useState('');
  const [loading,   setLoading]   = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!name || !email || !password) { setError('Name, email, and password are required'); return; }
    setError(''); setLoading(true);
    try {
      await signup(name, email, password, role, dept, roleTitle || 'Sales Agent');
    } catch (err) {
      setError(err.message || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-wrapper">
      <div className="glass-panel auth-card slide-in" style={{ maxWidth: '480px' }}>
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
          <p className="auth-subtitle">Register a new CRM staff account</p>
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
            <label>Full Name</label>
            <div style={{ position: 'relative' }}>
              <span style={{ position: 'absolute', left: '13px', top: '13px', color: 'var(--text-muted)' }}><User size={16} /></span>
              <input type="text" className="glass-input" placeholder="Sarah Smith"
                value={name} onChange={e => setName(e.target.value)}
                style={{ paddingLeft: '42px' }} disabled={loading} />
            </div>
          </div>

          <div className="form-group">
            <label>Work Email</label>
            <div style={{ position: 'relative' }}>
              <span style={{ position: 'absolute', left: '13px', top: '13px', color: 'var(--text-muted)' }}><Mail size={16} /></span>
              <input type="email" className="glass-input" placeholder="sarah@solar.com"
                value={email} onChange={e => setEmail(e.target.value)}
                style={{ paddingLeft: '42px' }} disabled={loading} />
            </div>
          </div>

          <div className="form-group">
            <label>Password</label>
            <div style={{ position: 'relative' }}>
              <span style={{ position: 'absolute', left: '13px', top: '13px', color: 'var(--text-muted)' }}><Lock size={16} /></span>
              <input type="password" className="glass-input" placeholder="Min 6 characters"
                value={password} onChange={e => setPassword(e.target.value)}
                style={{ paddingLeft: '42px' }} disabled={loading} />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
            <div className="form-group">
              <label>Department</label>
              <div style={{ position: 'relative' }}>
                <span style={{ position: 'absolute', left: '13px', top: '13px', color: 'var(--text-muted)' }}><Briefcase size={16} /></span>
                <select className="glass-input" value={dept} onChange={e => setDept(e.target.value)}
                  style={{ paddingLeft: '42px' }} disabled={loading}>
                  <option value="Sales">Sales</option>
                  <option value="Engineering">Engineering</option>
                  <option value="Support">Support</option>
                  <option value="Management">Management</option>
                </select>
              </div>
            </div>

            <div className="form-group">
              <label>CRM Role</label>
              <div style={{ position: 'relative' }}>
                <span style={{ position: 'absolute', left: '13px', top: '13px', color: 'var(--text-muted)' }}><ShieldCheck size={16} /></span>
                <select className="glass-input" value={role} onChange={e => setRole(e.target.value)}
                  style={{ paddingLeft: '42px' }} disabled={loading}>
                  <option value="employee">Employee</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
            </div>
          </div>

          <div className="form-group" style={{ marginBottom: '24px' }}>
            <label>Job Title</label>
            <input type="text" className="glass-input" placeholder="e.g. Senior Sales Executive"
              value={roleTitle} onChange={e => setRoleTitle(e.target.value)} disabled={loading} />
          </div>

          <button type="submit" className="glass-btn primary"
            style={{ width: '100%', padding: '12px', justifyContent: 'center' }} disabled={loading}>
            {loading ? 'Creating account...' : 'Register CRM Account'}
          </button>
        </form>

        <div className="auth-footer">
          Already have an account?{' '}
          <button onClick={() => onNavigate('login')} className="auth-link"
            style={{ background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: 'inherit' }}>
            Sign In
          </button>
        </div>
      </div>
    </div>
  );
};

export default Signup;
