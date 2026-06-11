const bcrypt = require("bcryptjs");
const path = require("path");
const sqlite3 = require("sqlite3").verbose();
const { Pool } = require("pg");

require("dotenv").config({ path: path.resolve(__dirname, ".env") });

const usePostgres = !!process.env.DATABASE_URL;
let sqliteDb = null;
let pgPool = null;

// ── Dialect Helpers ──────────────────────────────────────────────

/**
 * Convert PostgreSQL-style $1, $2, ... placeholders to SQLite's ? placeholders.
 */
function pgToSqlite(text, params = []) {
  if (!params.length) return { text: text, params };
  const expanded = [];
  const converted = text.replace(/\$(\d+)/g, (_match, num) => {
    const idx = parseInt(num, 10) - 1; // $1 → index 0
    if (idx >= 0 && idx < params.length) {
      expanded.push(params[idx]);
    }
    return '?';
  });
  return { text: converted, params: expanded.length > 0 ? expanded : params };
}

/**
 * Adapts schema queries dynamically for Postgres vs SQLite.
 */
function adaptSchema(queryText) {
  if (usePostgres) {
    // Postgres dialect adaptations
    return queryText
      .replace(/INTEGER PRIMARY KEY AUTOINCREMENT/gi, "SERIAL PRIMARY KEY")
      .replace(/DATETIME/gi, "TIMESTAMP")
      .replace(/BOOLEAN DEFAULT 1/gi, "BOOLEAN DEFAULT TRUE")
      .replace(/BOOLEAN DEFAULT 0/gi, "BOOLEAN DEFAULT FALSE");
  }
  return queryText;
}

// ── DB Interface ────────────────────────────────────────────────

const db = {
  query: async (text, params = []) => {
    if (usePostgres) {
      if (!pgPool) throw new Error("Database not initialized");
      const res = await pgPool.query(text, params);
      return { rows: res.rows };
    } else {
      if (!sqliteDb) throw new Error("Database not initialized");
      const converted = pgToSqlite(text, params);
      return new Promise((resolve, reject) => {
        sqliteDb.all(converted.text, converted.params, (err, rows) => {
          if (err) reject(err);
          else resolve({ rows });
        });
      });
    }
  },

  get: async (text, params = []) => {
    if (usePostgres) {
      if (!pgPool) throw new Error("Database not initialized");
      const res = await pgPool.query(text, params);
      return res.rows[0];
    } else {
      if (!sqliteDb) throw new Error("Database not initialized");
      const converted = pgToSqlite(text, params);
      return new Promise((resolve, reject) => {
        sqliteDb.get(converted.text, converted.params, (err, row) => {
          if (err) reject(err);
          else resolve(row);
        });
      });
    }
  },

  run: async (text, params = []) => {
    if (usePostgres) {
      if (!pgPool) throw new Error("Database not initialized");
      const res = await pgPool.query(text, params);
      // For insert returning id, pg returns rows[0].id usually, we simulate the sqlite lastID if we can
      let lastID = null;
      if (res.rows && res.rows.length > 0 && res.rows[0].id) {
        lastID = res.rows[0].id;
      }
      return { id: lastID, changes: res.rowCount };
    } else {
      if (!sqliteDb) throw new Error("Database not initialized");
      const converted = pgToSqlite(text, params);
      if (/\bRETURNING\b/i.test(converted.text)) {
        return new Promise((resolve, reject) => {
          sqliteDb.get(converted.text, converted.params, (err, row) => {
            if (err) reject(err);
            else resolve(row); // Actually return the row like Postgres does
          });
        });
      }
      return new Promise((resolve, reject) => {
        sqliteDb.run(converted.text, converted.params, function (err) {
          if (err) reject(err);
          else resolve({ id: this.lastID, changes: this.changes });
        });
      });
    }
  },
};

// ── Initialization ──────────────────────────────────────────────

function initSQLite() {
  return new Promise((resolve, reject) => {
    const dbPath = path.resolve(__dirname, "..", "database.sqlite");
    const database = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error("[Database] Failed to open SQLite DB:", err);
        reject(err);
      } else {
        console.log("[Database] SQLite DB ready:", dbPath);
        resolve(database);
      }
    });
  });
}

function initPostgres() {
  return new Promise((resolve, reject) => {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
    pool.connect((err, client, release) => {
      if (err) {
        console.error("[Database] Failed to connect to PostgreSQL:", err);
        reject(err);
      } else {
        console.log("[Database] PostgreSQL DB connected");
        release();
        resolve(pool);
      }
    });
  });
}

// ── Migrations & Schema ────────────────────────────────────────

async function getTableColumns(table) {
  if (usePostgres) {
    const info = await db.query(
      `SELECT column_name as name FROM information_schema.columns WHERE table_name = $1`,
      [table]
    );
    return info.rows.map((row) => row.name);
  } else {
    const info = await db.query(`PRAGMA table_info(${table})`);
    return info.rows.map((row) => row.name);
  }
}

async function ensureTableColumn(table, column, definition) {
  const columns = await getTableColumns(table);
  if (!columns.includes(column)) {
    await db.query(adaptSchema(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`));
  }
}

async function migrateUsersTableSchema() {
  const columns = await getTableColumns("users");
  if (!columns.length) return;

  if (!columns.includes("username") && columns.includes("name")) {
    await db.query("ALTER TABLE users RENAME COLUMN name TO username");
  }

  await ensureTableColumn("users", "phone_number", "VARCHAR(20)");
  await ensureTableColumn("users", "is_active", "BOOLEAN DEFAULT 1");
  await ensureTableColumn("users", "is_verified", "BOOLEAN DEFAULT 0");
  await ensureTableColumn("users", "device_id", "VARCHAR(100)");
  await ensureTableColumn("users", "two_factor_enabled", "BOOLEAN DEFAULT 0");
  await ensureTableColumn("users", "reset_code", "VARCHAR(10)");
  await ensureTableColumn("users", "reset_code_expires", "TIMESTAMP");
  await ensureTableColumn("users", "updated_at", "DATETIME");
}

async function migrateSalesTableSchema() {
  const columns = await getTableColumns("sales");
  if (!columns.length) return;

  if (!columns.includes("app_user_id") && columns.includes("customer_id")) {
    await db.query("ALTER TABLE sales RENAME COLUMN customer_id TO app_user_id");
  }
  if (!columns.includes("crm_employee_id") && columns.includes("salesperson_id")) {
    await db.query(
      "ALTER TABLE sales RENAME COLUMN salesperson_id TO crm_employee_id",
    );
  }
  await ensureTableColumn("sales", "notes", "TEXT");
  await ensureTableColumn("sales", "customer_name", "VARCHAR(150)");
}

async function migrateProductsTableSchema() {
  const columns = await getTableColumns("products");
  if (!columns.length) return;

  await ensureTableColumn("products", "product_code", "VARCHAR(100)");
  await ensureTableColumn("products", "price", "NUMERIC DEFAULT 0");
  await ensureTableColumn("products", "brand", "VARCHAR(100)");
  await ensureTableColumn("products", "category", "VARCHAR(100)");
  await ensureTableColumn("products", "variant", "VARCHAR(100)");
  await ensureTableColumn("products", "stock", "INTEGER DEFAULT 0");
  await ensureTableColumn("products", "valid_until", "TIMESTAMP");
}

const initializeDatabase = (async () => {
  if (usePostgres) {
    pgPool = await initPostgres();
  } else {
    sqliteDb = await initSQLite();
  }

  await db.query(adaptSchema(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username VARCHAR(100) NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL,
      phone_number VARCHAR(20),
      role VARCHAR(20) DEFAULT 'user',
      is_active BOOLEAN DEFAULT 1,
      is_verified BOOLEAN DEFAULT 0,
      premium_status VARCHAR(20) DEFAULT 'free',
      device_id VARCHAR(100) UNIQUE,
      two_factor_enabled BOOLEAN DEFAULT 0,
      reset_code VARCHAR(10),
      reset_code_expires TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `));

  await migrateUsersTableSchema();

  await db.query(adaptSchema(`
    CREATE TABLE IF NOT EXISTS crm_employees (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL,
      department VARCHAR(100),
      role_title VARCHAR(100),
      phone VARCHAR(20),
      salary NUMERIC DEFAULT 0,
      role VARCHAR(20) DEFAULT 'employee',
      status VARCHAR(20) DEFAULT 'active',
      hired_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `));

  const adminExists = await db.get(
    "SELECT id FROM crm_employees WHERE email = $1",
    ["crm-admin@solar.com"],
  );
  if (!adminExists) {
    const hash = await bcrypt.hash("admin123", 10);
    await db.run(
      `
      INSERT INTO crm_employees (name, email, password, department, role_title, role, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    `,
      [
        "Admin",
        "crm-admin@solar.com",
        hash,
        "Administration",
        "Administrator",
        "admin",
        "active",
      ],
    );
    console.log("[Database] Default CRM admin seeded");
  }

  await db.query(adaptSchema(`
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(150) NOT NULL,
      product_code VARCHAR(100) UNIQUE,
      description TEXT,
      price NUMERIC DEFAULT 0,
      brand VARCHAR(100),
      category VARCHAR(100),
      variant VARCHAR(100),
      stock INTEGER DEFAULT 0,
      valid_until TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `));

  await migrateProductsTableSchema();

  await db.query(adaptSchema(`
    CREATE TABLE IF NOT EXISTS devices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      device_uid VARCHAR(100) UNIQUE NOT NULL,
      product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
      assigned_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `));

  await db.query(adaptSchema(`
    CREATE TABLE IF NOT EXISTS device_controls (
      device_uid VARCHAR(100) PRIMARY KEY,
      wapda_auto_mode BOOLEAN DEFAULT TRUE,
      wapda_relay_state BOOLEAN DEFAULT TRUE,
      heavy_load_auto_mode BOOLEAN DEFAULT TRUE,
      heavy_load_state BOOLEAN DEFAULT TRUE,
      day_start VARCHAR(10) DEFAULT '08:00',
      day_end VARCHAR(10) DEFAULT '18:00',
      voltage NUMERIC DEFAULT 220.0,
      current NUMERIC DEFAULT 0.0,
      power NUMERIC DEFAULT 0.0,
      ldr_value INTEGER DEFAULT 1000,
      wapda_available BOOLEAN DEFAULT TRUE,
      wapda_relay_actual BOOLEAN DEFAULT TRUE,
      heavy_load_actual BOOLEAN DEFAULT TRUE,
      is_day_time BOOLEAN DEFAULT TRUE,
      last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `));

  await ensureTableColumn(
    "device_controls",
    "wapda_relay_actual",
    "BOOLEAN DEFAULT TRUE",
  );
  await ensureTableColumn(
    "device_controls",
    "heavy_load_actual",
    "BOOLEAN DEFAULT TRUE",
  );
  await ensureTableColumn(
    "device_controls",
    "is_day_time",
    "BOOLEAN DEFAULT TRUE",
  );

  await db.query(adaptSchema(`
    CREATE TABLE IF NOT EXISTS device_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      device_uid VARCHAR(100) NOT NULL,
      type VARCHAR(50) DEFAULT 'info',
      title VARCHAR(150) NOT NULL,
      message TEXT NOT NULL,
      is_read BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `));

  await db.query(adaptSchema(`
    CREATE TABLE IF NOT EXISTS sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      app_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      customer_name VARCHAR(150),
      product_name VARCHAR(150),
      quantity INTEGER,
      amount NUMERIC,
      crm_employee_id INTEGER REFERENCES crm_employees(id),
      status VARCHAR(20) DEFAULT 'completed',
      notes TEXT,
      sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `));

  await migrateSalesTableSchema();

  await db.query(adaptSchema(`
    CREATE TABLE IF NOT EXISTS firmware (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version VARCHAR(50) NOT NULL,
      file_path VARCHAR(255) NOT NULL,
      file_size INTEGER,
      description TEXT,
      product_family VARCHAR(10) DEFAULT 'WHL',
      is_active BOOLEAN DEFAULT 0,
      uploaded_by INTEGER REFERENCES crm_employees(id),
      uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `));

  await ensureTableColumn('firmware', 'product_family', "VARCHAR(10) DEFAULT 'WHL'");

  console.log(\`[Database] \${usePostgres ? 'PostgreSQL' : 'SQLite'} schema ensured\`);
})();

module.exports = {
  query: db.query,
  get: db.get,
  run: db.run,
  initializeDatabase,
};
