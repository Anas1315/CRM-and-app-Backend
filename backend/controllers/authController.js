require("dotenv").config();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { get, run, query } = require("../database");
const { CRM_JWT_SECRET } = require("../middleware/auth");

// ============================================================
// CRM Employee Authentication
// (These are CRM portal staff — NOT Flutter app users)
// ============================================================

async function login(req, res) {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      error: "bad_request",
      message: "Email and password are required",
    });
  }

  try {
    const employee = await get("SELECT * FROM crm_employees WHERE email = $1", [
      email,
    ]);

    if (!employee) {
      return res.status(401).json({
        error: "invalid_credentials",
        message: "Invalid email or password",
      });
    }

    if (employee.status === "terminated") {
      return res.status(403).json({
        error: "account_terminated",
        message: "Your CRM access has been revoked. Contact administrator.",
      });
    }

    const isMatch = await bcrypt.compare(password, employee.password);
    if (!isMatch) {
      return res.status(401).json({
        error: "invalid_credentials",
        message: "Invalid email or password",
      });
    }

    const token = jwt.sign(
      { id: employee.id, email: employee.email, role: employee.role },
      CRM_JWT_SECRET,
      { expiresIn: "24h" },
    );

    const { password: _, ...safeEmployee } = employee;

    res.json({
      message: "CRM Login successful",
      token,
      employee: safeEmployee,
    });
  } catch (err) {
    console.error("[CRM Auth] Login error:", err);
    res.status(500).json({ error: "server_error", message: "Login failed" });
  }
}

async function signup(req, res) {
  const name = req.body.name || req.body.username;
  const email = req.body.email;
  const password = req.body.password;
  const phone = req.body.phone || req.body.phone_number;
  const department = req.body.department;
  const role_title = req.body.role_title;

  if (!name || !email || !password) {
    return res.status(400).json({
      error: "bad_request",
      message: "Name, email, and password are required",
    });
  }

  try {
    const existing = await get(
      "SELECT id FROM crm_employees WHERE email = $1",
      [email],
    );
    if (existing) {
      return res.status(400).json({
        error: "email_taken",
        message: "This email is already registered as a CRM staff member",
      });
    }

    const hash = await bcrypt.hash(password, 10);
    const assignedRole = "employee"; // enforce employee role

    const newEmployee = await run(
      `INSERT INTO crm_employees (name, email, password, department, role_title, role, status, phone)
       VALUES ($1, $2, $3, $4, $5, $6, 'active', $7)
       RETURNING id, name, email, department, role_title, role, status, hired_date, phone`,
      [
        name,
        email,
        hash,
        department || "Sales",
        role_title || "Sales Agent",
        assignedRole,
        phone || null,
      ],
    );

    const token = jwt.sign(
      { id: newEmployee.id, email: newEmployee.email, role: newEmployee.role },
      CRM_JWT_SECRET,
      { expiresIn: "24h" },
    );

    res.status(201).json({
      message: "CRM staff account created successfully",
      token,
      employee: newEmployee,
    });
  } catch (err) {
    console.error("[CRM Auth] Signup error:", err);
    res
      .status(500)
      .json({ error: "server_error", message: "Registration failed" });
  }
}

async function me(req, res) {
  // req.employee is already populated by middleware
  res.json({ employee: req.employee });
}

module.exports = { login, signup, me };
