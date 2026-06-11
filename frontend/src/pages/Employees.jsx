/* eslint-disable react-hooks/set-state-in-effect */
import { useEffect, useState, useCallback } from 'react';
import { api } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import Modal from '../components/Modal';
import { Plus, Search, X, Pencil, Trash2 } from 'lucide-react';

const statusColor = { active:'success', on_leave:'warning', terminated:'danger' };

const EmployeeModal = ({ mode, employee, onSave, onClose }) => {
  const [name,      setName]      = useState(employee?.name      || '');
  const [email,     setEmail]     = useState(employee?.email     || '');
  const [password,  setPassword]  = useState('');
  const [dept,      setDept]      = useState(employee?.department || 'Sales');
  const [roleTitle, setRoleTitle] = useState(employee?.role_title || '');
  const [phone,     setPhone]     = useState(employee?.phone     || '');
  const [salary,    setSalary]    = useState(employee?.salary    || '');
  const [role,      setRole]      = useState(employee?.role      || 'employee');
  const [status,    setStatus]    = useState(employee?.status    || 'active');
  const [error,     setError]     = useState('');
  const [saving,    setSaving]    = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!name || !email || !dept || !roleTitle) { setError('Name, email, department, and role title are required'); return; }
    setError(''); setSaving(true);
    try {
      await onSave({ name, email, password, department: dept, role_title: roleTitle, phone, salary: parseFloat(salary)||0, role, status });
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal onClose={onClose}>
      <div className="glass-panel modal-content">
        <div className="modal-header">
          <h3 className="modal-title">{mode === 'add' ? 'Add CRM Staff Member' : 'Edit Staff Profile'}</h3>
          <button className="modal-close" onClick={onClose}><X size={18} /></button>
        </div>

        {error && <div style={{ background:'rgba(239,68,68,.12)', border:'1px solid rgba(239,68,68,.3)', color:'#ef4444', padding:'10px', borderRadius:'8px', fontSize:'13px', marginBottom:'14px' }}>{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Full Name</label>
            <input type="text" className="glass-input" value={name} onChange={e => setName(e.target.value)} placeholder="John Doe" />
          </div>

          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'14px' }}>
            <div className="form-group">
              <label>Email</label>
              <input type="email" className="glass-input" value={email} onChange={e => setEmail(e.target.value)} placeholder="john@solar.com" disabled={mode === 'edit'} />
            </div>
            {mode === 'add' && (
              <div className="form-group">
                <label>Password</label>
                <input type="password" className="glass-input" value={password} onChange={e => setPassword(e.target.value)} placeholder="Default: employee123" />
              </div>
            )}
          </div>

          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'14px' }}>
            <div className="form-group">
              <label>Department</label>
              <select className="glass-input" value={dept} onChange={e => setDept(e.target.value)}>
                <option value="Sales">Sales</option>
                <option value="Engineering">Engineering</option>
                <option value="Support">Support</option>
                <option value="Management">Management</option>
              </select>
            </div>
            <div className="form-group">
              <label>Job Title</label>
              <input type="text" className="glass-input" value={roleTitle} onChange={e => setRoleTitle(e.target.value)} placeholder="Senior Sales Executive" />
            </div>
          </div>

          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'14px' }}>
            <div className="form-group">
              <label>Phone</label>
              <input type="text" className="glass-input" value={phone} onChange={e => setPhone(e.target.value)} placeholder="+1 555-0100" />
            </div>
            <div className="form-group">
              <label>Monthly Salary ($)</label>
              <input type="number" className="glass-input" value={salary} onChange={e => setSalary(e.target.value)} placeholder="4500" />
            </div>
          </div>

          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'14px', marginBottom:'22px' }}>
            <div className="form-group">
              <label>CRM Role</label>
              <select className="glass-input" value={role} onChange={e => setRole(e.target.value)}>
                <option value="employee">Employee</option>
                <option value="admin">Admin</option>
              </select>
            </div>
            {mode === 'edit' && (
              <div className="form-group">
                <label>Employment Status</label>
                <select className="glass-input" value={status} onChange={e => setStatus(e.target.value)}>
                  <option value="active">Active</option>
                  <option value="on_leave">On Leave</option>
                  <option value="terminated">Terminated</option>
                </select>
              </div>
            )}
          </div>

          <button type="submit" className="glass-btn primary" style={{ width:'100%', justifyContent:'center' }} disabled={saving}>
            {saving ? 'Saving...' : mode === 'add' ? 'Add Staff Member' : 'Save Changes'}
          </button>
        </form>
      </div>
    </Modal>
  );
};

const Employees = () => {
  const { employee: currentEmp, isAdmin } = useAuth();
  const [employees, setEmployees] = useState([]);
  const [loading,   setLoading]   = useState(true);
  const [search,    setSearch]    = useState('');
  const [modal,     setModal]     = useState(null);  // null | { mode:'add'|'edit', data? }

  const fetchEmployees = useCallback(() => {
    setLoading(true);
    api.get('/api/employees')
      .then(data => setEmployees(Array.isArray(data) ? data : []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchEmployees(); }, [fetchEmployees]);

  const handleSave = async (formData) => {
    if (modal.mode === 'add') {
      await api.post('/api/employees', formData);
    } else {
      await api.put(`/api/employees/${modal.data.id}`, formData);
    }
    setModal(null);
    fetchEmployees();
  };

  const handleDelete = async (emp) => {
    if (!window.confirm(`Remove ${emp.name} from the CRM? This cannot be undone.`)) return;
    try {
      await api.delete(`/api/employees/${emp.id}`);
      setEmployees(prev => prev.filter(e => e.id !== emp.id));
    } catch (err) {
      alert(err.message);
    }
  };

  const filtered = employees.filter(e => {
    const t = search.toLowerCase();
    return !t || e.name.toLowerCase().includes(t) || e.email.toLowerCase().includes(t) ||
      e.department.toLowerCase().includes(t) || e.role_title.toLowerCase().includes(t);
  });

  return (
    <div className="slide-in">
      <header style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'28px' }}>
        <div>
          <h1 style={{ fontSize:'26px', fontWeight:800, color:'#fff', marginBottom:'4px' }}>CRM Staff Directory</h1>
          <p style={{ color:'hsl(var(--text-secondary))', fontSize:'14px' }}>
            Manage team members and role settings.
          </p>
        </div>
        {isAdmin && (
          <button className="glass-btn primary" onClick={() => setModal({ mode:'add' })}>
            <Plus size={16} /> Add Staff
          </button>
        )}
      </header>

      {/* Search */}
      <div className="glass-panel" style={{ padding:'12px 16px', display:'flex', gap:'12px', alignItems:'center', marginBottom:'20px' }}>
        <Search size={18} color="hsl(var(--text-muted))" />
        <input type="text" placeholder="Search staff by name, email, department..." className="glass-input"
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
                  <th>Staff Member</th>
                  <th>Department & Title</th>
                  <th>Phone</th>
                  <th>Salary/mo</th>
                  <th>CRM Role</th>
                  <th>Status</th>
                  {isAdmin && <th style={{ textAlign:'right' }}>Actions</th>}
                </tr>
              </thead>
              <tbody>
                {filtered.map(emp => (
                  <tr key={emp.id}>
                    <td>
                      <div style={{ display:'flex', alignItems:'center', gap:'10px' }}>
                        <div style={{
                          width:'34px', height:'34px', borderRadius:'50%', flexShrink:0,
                          background:'rgba(255,125,0,.08)', border:'1px solid rgba(255,125,0,.15)',
                          display:'flex', alignItems:'center', justifyContent:'center',
                          fontSize:'13px', fontWeight:700, color:'hsl(var(--primary))'
                        }}>
                          {emp.name?.[0]?.toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontWeight:600, color:'#fff', fontSize:'14px', display:'flex', alignItems:'center', gap:'6px' }}>
                            {emp.name}
                            {emp.id === currentEmp?.id && <span style={{ fontSize:'9px', background:'rgba(255,125,0,.15)', color:'hsl(var(--primary))', padding:'1px 6px', borderRadius:'10px', fontWeight:700 }}>YOU</span>}
                          </div>
                          <div style={{ fontSize:'11px', color:'hsl(var(--text-secondary))' }}>{emp.email}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div style={{ fontWeight:500, color:'#fff', fontSize:'13px' }}>{emp.role_title}</div>
                      <div style={{ fontSize:'11px', color:'hsl(var(--text-secondary))', marginTop:'2px' }}>{emp.department}</div>
                    </td>
                    <td style={{ fontSize:'13px', color:'hsl(var(--text-secondary))' }}>{emp.phone || '—'}</td>
                    <td style={{ fontWeight:700, color:'#fff' }}>${parseFloat(emp.salary).toLocaleString()}</td>
                    <td>
                      <span style={{ fontSize:'11px', fontWeight:700, textTransform:'uppercase', letterSpacing:'0.5px',
                        color: emp.role === 'admin' ? 'hsl(var(--primary))' : 'hsl(var(--text-secondary))' }}>
                        {emp.role}
                      </span>
                    </td>
                    <td><span className={`badge ${statusColor[emp.status] || 'info'}`}>{emp.status?.replace('_',' ')}</span></td>
                    {isAdmin && (
                      <td style={{ textAlign:'right' }}>
                        <div style={{ display:'flex', gap:'6px', justifyContent:'flex-end' }}>
                          <button className="glass-btn" style={{ padding:'5px 10px' }}
                            onClick={() => setModal({ mode:'edit', data: emp })}>
                            <Pencil size={13} />
                          </button>
                          {emp.id !== currentEmp?.id && (
                            <button className="glass-btn danger" style={{ padding:'5px 10px' }}
                              onClick={() => handleDelete(emp)}>
                              <Trash2 size={13} />
                            </button>
                          )}
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr><td colSpan={isAdmin ? 7 : 6} style={{ textAlign:'center', color:'hsl(var(--text-muted))', padding:'30px' }}>
                    No CRM staff match your search
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {modal && (
        <EmployeeModal
          mode={modal.mode}
          employee={modal.data}
          onSave={handleSave}
          onClose={() => setModal(null)}
          currentEmployeeId={currentEmp?.id}
        />
      )}
    </div>
  );
};

export default Employees;
