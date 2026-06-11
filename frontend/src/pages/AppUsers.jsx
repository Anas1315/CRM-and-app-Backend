/* eslint-disable react-hooks/set-state-in-effect */
import { useEffect, useState, useCallback } from 'react';
import { api } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import Modal from '../components/Modal';
import {
  Search, Smartphone, UserX, UserCheck, Eye,
  CheckCircle, XCircle, Shield, X, Trash2
} from 'lucide-react';

// ── Helper badges ────────────────────────────────────────
const StatusBadge = ({ isActive }) => isActive
  ? <span className="badge success"><CheckCircle size={10} style={{ marginRight:4 }} />Active</span>
  : <span className="badge danger"><XCircle size={10} style={{ marginRight:4 }} />Blocked</span>;

// ── User Detail Drawer ───────────────────────────────────
const UserDetail = ({ userId, onClose }) => {
  const [user, setUser] = useState(null);

  useEffect(() => {
    api.get(`/api/app-users/${userId}`).then(setUser).catch(console.error);
  }, [userId]);

  if (!user) return (
    <Modal onClose={onClose}>
      <div className="glass-panel modal-content modal-sm" style={{ display:'flex', justifyContent:'center', padding:'50px' }}>
        <div style={{ width:'30px', height:'30px', border:'3px solid rgba(255,125,0,.1)', borderTopColor:'hsl(var(--primary))', borderRadius:'50%', animation:'spin-slow 1s linear infinite' }} />
      </div>
    </Modal>
  );

  return (
    <Modal onClose={onClose}>
      <div className="glass-panel modal-content modal-sm">
        <div className="modal-header">
          <h3 className="modal-title">App User Profile</h3>
          <button className="modal-close" onClick={onClose}><X size={18} /></button>
        </div>

        {/* Avatar & name */}
        <div style={{ display:'flex', alignItems:'center', gap:'16px', marginBottom:'20px', padding:'16px', background:'rgba(255,255,255,.02)', borderRadius:'12px', border:'1px solid var(--glass-border)' }}>
          <div style={{ width:'50px', height:'50px', borderRadius:'50%', background:'rgba(255,125,0,.1)', border:'1px solid rgba(255,125,0,.2)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:'18px', fontWeight:700, color:'hsl(var(--primary))' }}>
            {user.username?.[0]?.toUpperCase()}
          </div>
          <div>
            <div style={{ fontWeight:700, fontSize:'16px', color:'#fff' }}>{user.username}</div>
            <div style={{ fontSize:'13px', color:'hsl(var(--text-secondary))' }}>{user.email}</div>
            <div style={{ display:'flex', gap:'6px', marginTop:'6px' }}>
              <StatusBadge isActive={user.is_active} />
            </div>
          </div>
        </div>

        {/* Detail rows */}
        {[
          ['Role',          user.role],
          ['Phone',         user.phone_number || 'Not provided'],
          ['Product SKU',   user.product_code || 'None'],
          ['Device ID',     user.device_id || 'None'],
          ['Verified',      user.is_verified ? 'Yes' : 'No'],
          ['2FA Enabled',   user.two_factor_enabled ? 'Yes' : 'No'],
          ['Registered',    new Date(user.created_at).toLocaleDateString()],
          ['Total Sales',   user.total_sales || 0],
          ['Total Spent',   `$${parseFloat(user.total_spent || 0).toLocaleString()}`],
        ].map(([label, val]) => (
          <div key={label} style={{ display:'flex', justifyContent:'space-between', padding:'9px 0', borderBottom:'1px solid rgba(255,255,255,.03)', fontSize:'14px' }}>
            <span style={{ color:'hsl(var(--text-secondary))', fontWeight:500 }}>{label}</span>
            <span style={{ color:'#fff', fontWeight:600, textTransform:'none' }}>{val}</span>
          </div>
        ))}
      </div>
    </Modal>
  );
};

// ── Main Component ───────────────────────────────────────
const AppUsers = () => {
  const { isAdmin } = useAuth();
  const [users,          setUsers]          = useState([]);
  const [loading,        setLoading]        = useState(true);
  const [search,         setSearch]         = useState('');
  const [filter,         setFilter]         = useState('all');   // all | active | deactivated
  const [detailId,       setDetailId]       = useState(null);
  const [statusLoading,  setStatusLoading]  = useState({});
  const [deleteLoading,  setDeleteLoading]  = useState({});

  const fetchUsers = useCallback(() => {
    setLoading(true);
    api.get('/api/app-users')
      .then(data => setUsers(Array.isArray(data) ? data : []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  // ── Toggle active / inactive ─────────────────────────
  const toggleStatus = async (user) => {
    const newActive = user.is_active ? 0 : 1;
    setStatusLoading(p => ({ ...p, [user.id]: true }));
    try {
      await api.patch(`/api/app-users/${user.id}/status`, { is_active: newActive });
      setUsers(prev => prev.map(u => u.id === user.id ? { ...u, is_active: newActive } : u));
    } catch (err) {
      alert(err.message);
    } finally {
      setStatusLoading(p => ({ ...p, [user.id]: false }));
    }
  };

  const deleteUser = async (user) => {
    if (!window.confirm(`Delete app user ${user.username}? This action cannot be undone.`)) return;

    setDeleteLoading(p => ({ ...p, [user.id]: true }));
    try {
      await api.delete(`/api/app-users/${user.id}`);
      setUsers(prev => prev.filter(u => u.id !== user.id));
    } catch (err) {
      alert(err.message);
    } finally {
      setDeleteLoading(p => ({ ...p, [user.id]: false }));
    }
  };

  // ── Filter ───────────────────────────────────────────
  const filtered = users.filter(u => {
    const term = search.toLowerCase();
    const matchSearch = !term || u.username?.toLowerCase().includes(term) || u.email?.toLowerCase().includes(term);
    const matchFilter =
      filter === 'all'         ? true :
      filter === 'active'      ? u.is_active === 1 :
      filter === 'deactivated' ? u.is_active === 0 : true;
    return matchSearch && matchFilter;
  });

  const pills = [
    { id:'all',         label:`All (${users.length})` },
    { id:'active',      label:`Active (${users.filter(u => u.is_active).length})` },
    { id:'deactivated', label:`Blocked (${users.filter(u => !u.is_active).length})` },
  ];

  return (
    <div className="slide-in">
      {/* Header */}
      <header style={{ marginBottom:'28px' }}>
        <h1 style={{ fontSize:'26px', fontWeight:800, color:'#fff', marginBottom:'4px', display:'flex', alignItems:'center', gap:'10px' }}>
          <Smartphone size={24} color="hsl(var(--primary))" /> Mobile APP User
        </h1>
        <p style={{ color:'hsl(var(--text-secondary))', fontSize:'14px' }}>
          Manage system users registered on the Mobile App.
        </p>
      </header>

      {/* Filter pills */}
      <div style={{ display:'flex', gap:'8px', flexWrap:'wrap', marginBottom:'16px' }}>
        {pills.map(p => (
          <button key={p.id} onClick={() => setFilter(p.id)} style={{
            background: filter === p.id ? 'linear-gradient(135deg,rgba(255,125,0,.2),rgba(255,69,0,.1))' : 'rgba(255,255,255,.04)',
            border: filter === p.id ? '1px solid rgba(255,125,0,.35)' : '1px solid rgba(255,255,255,.08)',
            color: filter === p.id ? '#fff' : 'hsl(var(--text-secondary))',
            borderRadius:'20px', padding:'6px 14px', fontSize:'12px', fontWeight:600,
            cursor:'pointer', fontFamily:'var(--font-main)', transition:'var(--transition-fast)'
          }}>{p.label}</button>
        ))}
      </div>

      {/* Search bar */}
      <div className="glass-panel" style={{ padding:'12px 16px', display:'flex', gap:'12px', alignItems:'center', marginBottom:'20px' }}>
        <Search size={18} color="hsl(var(--text-muted))" />
        <input type="text" placeholder="Search by username or email..." className="glass-input"
          style={{ border:'none', background:'transparent', padding:'4px' }}
          value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {/* Table */}
      <div className="glass-panel" style={{ padding:'24px' }}>
        {loading ? (
          <div style={{ display:'flex', justifyContent:'center', padding:'40px' }}>
            <div style={{ width:'30px', height:'30px', border:'3px solid rgba(255,125,0,.1)', borderTopColor:'hsl(var(--primary))', borderRadius:'50%', animation:'spin-slow 1s linear infinite' }} />
          </div>
        ) : (
          <div className="table-container">
            <table className="custom-table">
              <thead>
                <tr>
                  <th>App User</th>
                  <th>Role</th>
                  <th>Product SKU</th>
                  <th>App Status</th>
                  <th>Registered</th>
                  {isAdmin && <th style={{ textAlign:'right' }}>Actions</th>}
                </tr>
              </thead>
              <tbody>
                {filtered.map(u => (
                  <tr key={u.id}>
                    <td>
                      <div style={{ display:'flex', alignItems:'center', gap:'10px' }}>
                        <div style={{
                          width:'34px', height:'34px', borderRadius:'50%', flexShrink:0,
                          background: 'rgba(255,255,255,.04)',
                          border: '1px solid rgba(255,255,255,.08)',
                          display:'flex', alignItems:'center', justifyContent:'center',
                          fontSize:'13px', fontWeight:700,
                          color: 'hsl(var(--text-secondary))'
                        }}>
                          {u.username?.[0]?.toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontWeight:600, color:'#fff', fontSize:'14px' }}>{u.username}</div>
                          <div style={{ fontSize:'11px', color:'hsl(var(--text-secondary))' }}>{u.email}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span style={{ fontSize:'12px', fontWeight:700, textTransform:'uppercase',
                        color: u.role === 'master_admin' ? 'hsl(var(--primary))' : u.role === 'admin' ? '#a78bfa' : 'hsl(var(--text-secondary))',
                        display:'flex', alignItems:'center', gap:'4px'
                      }}>
                        {u.role === 'master_admin' && <Shield size={11} />}
                        {u.role}
                      </span>
                    </td>
                    <td style={{ fontSize:'13px', color:'#fff', fontWeight:600 }}>
                      {u.product_code || <span style={{ color:'hsl(var(--text-muted))' }}>No SKU</span>}
                    </td>
                    <td><StatusBadge isActive={u.is_active} /></td>
                    <td style={{ fontSize:'13px', color:'hsl(var(--text-secondary))' }}>
                      {new Date(u.created_at).toLocaleDateString()}
                    </td>
                    {isAdmin && (
                      <td style={{ textAlign:'right' }}>
                        <div style={{ display:'flex', gap:'6px', justifyContent:'flex-end', alignItems:'center' }}>
                          {/* Detail */}
                          <button className="glass-btn" style={{ padding:'5px 10px' }}
                            onClick={() => setDetailId(u.id)}>
                            <Eye size={13} />
                          </button>

                          {/* Deactivate / Reactivate */}
                          <button
                            className={`glass-btn ${u.is_active ? 'danger' : 'primary'}`}
                            style={{ padding:'5px 10px', fontSize:'12px', gap:'4px', minWidth:'98px', justifyContent:'center' }}
                            onClick={() => toggleStatus(u)}
                            disabled={!!statusLoading[u.id]}>
                            {statusLoading[u.id] ? '...' : u.is_active
                              ? <><UserX size={12} /> Deactivate</>
                              : <><UserCheck size={12} /> Reactivate</>
                            }
                          </button>

                          <button
                            className="glass-btn danger"
                            style={{ padding:'5px 10px', fontSize:'12px', gap:'4px', minWidth:'82px', justifyContent:'center' }}
                            onClick={() => deleteUser(u)}
                            disabled={!!deleteLoading[u.id]}>
                            {deleteLoading[u.id] ? '...' : <><Trash2 size={12} /> Delete</>}
                          </button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr><td colSpan={isAdmin ? 7 : 6} style={{ textAlign:'center', color:'hsl(var(--text-muted))', padding:'30px' }}>
                    No app users match your filters
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modals */}
      {detailId    && <UserDetail userId={detailId} onClose={() => setDetailId(null)} />}
    </div>
  );
};

export default AppUsers;
