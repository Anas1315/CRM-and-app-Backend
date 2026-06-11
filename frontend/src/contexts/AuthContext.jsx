/* eslint-disable react-refresh/only-export-components */
import { createContext, useState, useEffect, useContext } from 'react';
import { api, session } from '../services/api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [employee, setEmployee] = useState(null); // logged-in CRM staff member
  const [loading,  setLoading]  = useState(true);

  // ── Logout ────────────────────────────────────────────
  const logout = () => {
    session.clear();
    setEmployee(null);
  };

  // ── Restore session on mount ──────────────────────────
  useEffect(() => {
    async function restore() {
      const storedToken = session.getToken();
      const storedEmp   = session.getEmployee();

      if (storedToken && storedEmp) {
        // If the stored object looks like a mobile `user` (has `premium_status`),
        // it's not compatible with the CRM `/api/auth/me` route — clear session.
        if (storedEmp.premium_status) {
          logout();
        } else {
          setEmployee(storedEmp);
          try {
            const data = await api.get('/api/auth/me');
            setEmployee(data.employee);
            session.setEmployee(data.employee);
          } catch {
            logout();
          }
        }
      }
      setLoading(false);
    }
    restore();

    // Handle global session expiry (401 from any API call)
    const onExpired = () => logout();
    window.addEventListener('crm_session_expired', onExpired);
    return () => window.removeEventListener('crm_session_expired', onExpired);
  }, []);

  // ── Login ─────────────────────────────────────────────
  const login = async (email, password) => {
    setLoading(true);
    try {
      const res = await api.post('/api/auth/login', { email, password });
        // Support backend returning either `employee` (CRM) or `user` (mobile app).
        // When a `user` is returned for CRM login, map it to the internal `employee`
        // shape so the admin can sign in immediately while we fix the backend.
        const src = res.employee || res.user || null;
        session.setToken(res.token);
        if (src) {
          // Map `user` -> `employee` if necessary (fields may overlap)
          const mapped = {
            id: src.id,
            name: src.name || src.username || 'Unknown',
            email: src.email,
            role: src.role || 'employee',
            status: src.status || (src.is_active ? 'active' : 'inactive'),
            premium_status: src.premium_status
          };
          session.setEmployee(mapped);
          setEmployee(mapped);
        }
        return src;
    } finally {
      setLoading(false);
    }
  };

  // ── Signup ────────────────────────────────────────────
  const signup = async (name, email, password, role, department, role_title) => {
    setLoading(true);
    try {
      const res = await api.post('/api/auth/signup', { name, email, password, role, department, role_title });
        if (res.user && !res.employee) {
          const err = new Error('Server returned app user token; CRM signup expected');
          throw err;
        }
        const emp = res.employee || null;
        session.setToken(res.token);
        if (emp) {
          session.setEmployee(emp);
          setEmployee(emp);
        }
        return emp;
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthContext.Provider value={{
      employee,
      loading,
      isAuthenticated: !!employee,
      isAdmin: employee?.role === 'admin',
      isDeactivated: employee?.status === 'terminated' || employee?.status === 'suspended',
      login,
      signup,
      logout,
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
};
