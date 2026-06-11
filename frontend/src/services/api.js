const API_BASE = import.meta.env.VITE_API_BASE_URL || '';

// ── Token / Session helpers ──────────────────────────────
export const session = {
  getToken: () => localStorage.getItem('crm_token'),
  setToken: t => localStorage.setItem('crm_token', t),
  clearToken: () => localStorage.removeItem('crm_token'),
  getEmployee: () => {
    try { return JSON.parse(localStorage.getItem('crm_employee')); }
    catch { return null; }
  },
  setEmployee: e => localStorage.setItem('crm_employee', JSON.stringify(e)),
  clearEmployee: () => localStorage.removeItem('crm_employee'),
  clear: () => { localStorage.removeItem('crm_token'); localStorage.removeItem('crm_employee'); }
};

// ── Core fetch wrapper ───────────────────────────────────
async function request(endpoint, options = {}) {
  const token = session.getToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers
  };

  const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });

  // Only treat 401 as a global CRM session expiry for protected CRM routes
  if (res.status === 401) {
    const crmProtected = /\/auth\/|\/employees\/|\/firmware\/|\/products|\/app-users/.test(endpoint);
    if (crmProtected) {
      session.clear();
      window.dispatchEvent(new Event('crm_session_expired'));
    }
  }

  const text = await res.text();
  let data;
  try { data = text ? JSON.parse(text) : null; } catch { data = { message: text }; }

  if (!res.ok) {
    const err = new Error(data?.message || 'Request failed');
    err.status = res.status;
    err.code = data?.error;
    throw err;
  }
  return data;
}

export const api = {
  get: (url, opts) => request(url, { ...opts, method: 'GET' }),
  post: (url, body, opts) => request(url, { ...opts, method: 'POST', body: JSON.stringify(body) }),
  put: (url, body, opts) => request(url, { ...opts, method: 'PUT', body: JSON.stringify(body) }),
  patch: (url, body, opts) => request(url, { ...opts, method: 'PATCH', body: JSON.stringify(body) }),
  delete: (url, opts) => request(url, { ...opts, method: 'DELETE' }),

  // Multipart binary upload for .bin firmware files
  uploadFirmware: async (formData) => {
    const token = session.getToken();
    const res = await fetch(`${API_BASE}/api/firmware/upload`, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData
    });
    const text = await res.text();
    let data;
    try { data = text ? JSON.parse(text) : null; } catch { data = { message: text }; }
    if (!res.ok) { const e = new Error(data?.message || 'Upload failed'); e.status = res.status; throw e; }
    return data;
  }
};
