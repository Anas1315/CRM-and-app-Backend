const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });
const jwt = require('jsonwebtoken');
const { get } = require('../database');

const CRM_JWT_SECRET = process.env.CRM_JWT_SECRET || 'crm_solar_controller_secret_key_!@#2024';

// ============================================================
// Authenticate CRM Employee (NOT Flutter app users)
// CRM staff log into this web portal separately
// ============================================================
async function authenticateCRMEmployee(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'unauthorized', message: 'CRM access token missing' });
  }

  try {
    const decoded = jwt.verify(token, CRM_JWT_SECRET);

    // Fetch latest CRM employee record from DB
    const employee = await get(
      'SELECT id, name, email, department, role_title, role, status FROM crm_employees WHERE id = $1',
      [decoded.id]
    );

    if (!employee) {
      return res.status(404).json({ error: 'employee_not_found', message: 'CRM staff account not found' });
    }

    if (employee.status === 'terminated') {
      return res.status(403).json({ error: 'account_terminated', message: 'Your CRM access has been revoked' });
    }

    req.employee = employee;
    next();
  } catch (err) {
    return res.status(403).json({ error: 'invalid_token', message: 'CRM session expired or invalid' });
  }
}

// ============================================================
// Require specific CRM role
// ============================================================
function requireCRMRole(...roles) {
  return (req, res, next) => {
    if (!req.employee) {
      return res.status(401).json({ error: 'unauthorized' });
    }
    if (!roles.includes(req.employee.role)) {
      return res.status(403).json({ error: 'forbidden', message: `Requires CRM role: ${roles.join(' or ')}` });
    }
    next();
  };
}

module.exports = { authenticateCRMEmployee, requireCRMRole, CRM_JWT_SECRET };
