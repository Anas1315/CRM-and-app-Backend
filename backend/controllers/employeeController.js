const bcrypt = require('bcryptjs');
const { get, run, query } = require('../database');

// ============================================================
// CRM EMPLOYEE MANAGEMENT
// Manages internal CRM staff (admins, sales agents)
// These are NOT Flutter app users — they are CRM portal staff
// ============================================================

async function listEmployees(req, res) {
  try {
    const result = await query(
      `SELECT id, name, email, department, role_title, phone, salary, role, status, hired_date
       FROM crm_employees
       ORDER BY hired_date DESC`
    );
    res.json(result.rows || result);
  } catch (err) {
    console.error('[Employees] List error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not fetch employee list' });
  }
}

async function addEmployee(req, res) {
  const { name, email, password, department, role_title, phone, salary, role } = req.body;

  if (!name || !email || !department || !role_title) {
    return res.status(400).json({ error: 'bad_request', message: 'Name, email, department, and role title are required' });
  }

  try {
    const existing = await get('SELECT id FROM crm_employees WHERE email = $1', [email]);
    if (existing) {
      return res.status(400).json({ error: 'email_taken', message: 'This email is already in use' });
    }

    const hash = await bcrypt.hash(password || 'employee123', 10);
    const assignedRole = role && ['admin', 'employee'].includes(role) ? role : 'employee';

    const newEmp = await run(
      `INSERT INTO crm_employees (name, email, password, department, role_title, phone, salary, role, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'active')
       RETURNING id, name, email, department, role_title, phone, salary, role, status, hired_date`,
      [name, email, hash, department, role_title, phone || null, salary || 0, assignedRole]
    );

    res.status(201).json({ message: 'CRM employee created successfully', employee: newEmp });
  } catch (err) {
    console.error('[Employees] Add error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not create employee' });
  }
}

async function updateEmployee(req, res) {
  const empId = req.params.id;
  const { department, role_title, phone, salary, status } = req.body;

  try {
    const emp = await get('SELECT * FROM crm_employees WHERE id = $1', [empId]);
    if (!emp) {
      return res.status(404).json({ error: 'not_found', message: 'Employee not found' });
    }

    const updated = await run(
      `UPDATE crm_employees
       SET department = $1, role_title = $2, phone = $3, salary = $4, status = $5
       WHERE id = $6
       RETURNING id, name, email, department, role_title, phone, salary, role, status, hired_date`,
      [
        department ?? emp.department,
        role_title ?? emp.role_title,
        phone ?? emp.phone,
        salary ?? emp.salary,
        status ?? emp.status,
        empId
      ]
    );

    res.json({ message: 'Employee updated successfully', employee: updated });
  } catch (err) {
    console.error('[Employees] Update error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not update employee' });
  }
}

async function deleteEmployee(req, res) {
  const empId = req.params.id;

  // Prevent self-deletion
  if (parseInt(empId) === req.employee.id) {
    return res.status(400).json({ error: 'bad_request', message: 'You cannot delete your own CRM account' });
  }

  try {
    const emp = await get('SELECT id FROM crm_employees WHERE id = $1', [empId]);
    if (!emp) {
      return res.status(404).json({ error: 'not_found', message: 'Employee not found' });
    }

    await query('DELETE FROM crm_employees WHERE id = $1', [empId]);
    res.json({ message: 'CRM employee removed successfully' });
  } catch (err) {
    console.error('[Employees] Delete error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not delete employee' });
  }
}

// ============================================================
// FLUTTER APP USER MANAGEMENT
// Reads and manages actual mobile app users from the shared
// Local "users" table (same DB as Smart Energy backend)
// ============================================================

async function listAppUsers(req, res) {
  try {
    const result = await query(
      `SELECT u.id, u.username, u.email, u.phone_number, u.role, u.is_active, u.is_verified,
              u.created_at, u.device_id, p.product_code
       FROM users u
       LEFT JOIN devices d ON d.device_uid = u.device_id
       LEFT JOIN products p ON p.id = d.product_id
       WHERE u.role IN ('user', 'admin', 'master_admin')
       ORDER BY u.created_at DESC`
    );
    res.json(result.rows || result);
  } catch (err) {
    console.error('[AppUsers] List error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not fetch app users' });
  }
}

async function getAppUser(req, res) {
  const userId = req.params.id;
  try {
    const user = await get(
      `SELECT u.id, u.username, u.email, u.phone_number, u.role, u.is_active, u.is_verified,
              u.two_factor_enabled, u.created_at, u.device_id, p.product_code, p.name AS product_name,
              (SELECT COUNT(*) FROM sales WHERE app_user_id = $1) AS total_sales,
              (SELECT COALESCE(SUM(amount),0) FROM sales WHERE app_user_id = $1 AND status = 'completed') AS total_spent
       FROM users u
       LEFT JOIN devices d ON d.device_uid = u.device_id
       LEFT JOIN products p ON p.id = d.product_id
       WHERE u.id = $1`,
      [userId]
    );
    if (!user) {
      return res.status(404).json({ error: 'not_found', message: 'App user not found' });
    }
    res.json(user);
  } catch (err) {
    console.error('[AppUsers] Get error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not fetch user details' });
  }
}

// Deactivate or reactivate a Flutter app user
// When deactivated → user cannot login to the mobile app
async function setAppUserStatus(req, res) {
  const userId = req.params.id;
  const { is_active } = req.body;

  if (is_active === undefined || ![0, 1, true, false].includes(is_active)) {
    return res.status(400).json({ error: 'bad_request', message: 'is_active must be 0 (deactivate) or 1 (activate)' });
  }

  const activeVal = is_active ? 1 : 0;

  try {
    const user = await get('SELECT id, username, email, is_active FROM users WHERE id = $1', [userId]);
    if (!user) {
      return res.status(404).json({ error: 'not_found', message: 'App user not found' });
    }

    await query(
      'UPDATE users SET is_active = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [activeVal, userId]
    );

    res.json({
      message: `App user ${activeVal ? 'reactivated' : 'deactivated'} successfully`,
      user_id: userId,
      is_active: activeVal,
      note: activeVal === 0
        ? 'This user will be blocked from logging into the Flutter mobile app.'
        : 'This user can now log into the Flutter mobile app again.'
    });
  } catch (err) {
    console.error('[AppUsers] Status toggle error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not update user status' });
  }
}

async function deleteAppUser(req, res) {
  const userId = req.params.id;

  try {
    const user = await get(
      'SELECT id, username, email, role FROM users WHERE id = $1',
      [userId]
    );
    if (!user) {
      return res.status(404).json({ error: 'not_found', message: 'App user not found' });
    }
    if (user.role === 'master_admin') {
      return res.status(400).json({ error: 'bad_request', message: 'Master admin app users cannot be deleted' });
    }

    await query(
      `UPDATE sales
       SET customer_name = COALESCE(customer_name, $1), app_user_id = NULL
       WHERE app_user_id = $2`,
      [user.username || user.email || 'Deleted app user', userId]
    );
    await query('UPDATE devices SET assigned_user_id = NULL WHERE assigned_user_id = $1', [userId]);
    await query('DELETE FROM users WHERE id = $1', [userId]);

    res.json({ message: 'App user deleted successfully' });
  } catch (err) {
    console.error('[AppUsers] Delete error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not delete app user' });
  }
}



module.exports = {
  listEmployees,
  addEmployee,
  updateEmployee,
  deleteEmployee,
  listAppUsers,
  getAppUser,
  setAppUserStatus,
  deleteAppUser
};
