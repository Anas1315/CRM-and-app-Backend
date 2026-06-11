const database = require("../database");
const { get, run, query } = database;
const isSQLite = !process.env.DATABASE_URL;

// ============================================================
// CRM SALES & DASHBOARD
// Sales records reference the shared "users" table (Flutter app users)
// ============================================================

// List all sales — joins with Flutter app users + CRM employees
async function listSales(req, res) {
  try {
    const result = await query(
      `SELECT s.*,
              COALESCE(s.customer_name, u.username) AS display_customer_name,
              u.username AS customer_username,
              u.email    AS customer_email,
              e.name     AS salesperson_name,
              e.department
       FROM sales s
       LEFT JOIN users u ON s.app_user_id = u.id
       LEFT JOIN crm_employees e ON s.crm_employee_id = e.id
       ORDER BY s.sale_date DESC`,
    );
    res.json(result.rows || result);
  } catch (err) {
    console.error("[Sales] List error:", err);
    res
      .status(500)
      .json({
        error: "server_error",
        message: "Could not fetch sales history",
      });
  }
}

// Add a new sale — customer must be an existing Flutter app user
async function addSale(req, res) {
  const {
    app_user_id,
    customer_name,
    product_name,
    quantity,
    amount,
  } = req.body;

  if ((!app_user_id && !customer_name?.trim()) || !product_name || quantity === undefined || amount === undefined) {
    return res.status(400).json({
      error: "bad_request",
      message:
        "Customer name or Flutter app user, product_name, quantity, and amount are required",
    });
  }

  try {
    let appUser = null;
    if (app_user_id) {
      appUser = await get(
        "SELECT id, username, email FROM users WHERE id = $1",
        [app_user_id],
      );
      if (!appUser) {
        return res.status(404).json({
          error: "not_found",
          message:
            "Flutter app user not found. Users must sign up from the Flutter mobile app with a valid Product ID before a sale can be recorded against an app user.",
        });
      }
    }

    const newSale = await run(
      `INSERT INTO sales (app_user_id, customer_name, product_name, quantity, amount, crm_employee_id, status, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        appUser?.id || null,
        customer_name?.trim() || null,
        product_name,
        parseInt(quantity),
        parseFloat(amount),
        req.employee?.id || null,
        "completed",
        null,
      ],
    );

    res.status(201).json({
      message: "Sale recorded successfully",
      sale: {
        ...newSale,
        display_customer_name: newSale.customer_name || appUser?.username || null,
        customer_username: appUser?.username || null,
        customer_email: appUser?.email || null,
      },
    });
  } catch (err) {
    console.error("[Sales] Add error:", err);
    res
      .status(500)
      .json({ error: "server_error", message: "Could not record sale" });
  }
}

async function updateSale(req, res) {
  const saleId = req.params.id;
  const { app_user_id, customer_name, product_name, quantity, amount, status, notes } = req.body;

  try {
    const sale = await get("SELECT * FROM sales WHERE id = $1", [saleId]);
    if (!sale) {
      return res
        .status(404)
        .json({ error: "not_found", message: "Sale record not found" });
    }

    let appUserId = sale.app_user_id;
    if (Object.prototype.hasOwnProperty.call(req.body, "app_user_id")) {
      appUserId = app_user_id || null;
      if (appUserId) {
        const appUser = await get("SELECT id FROM users WHERE id = $1", [
          appUserId,
        ]);
        if (!appUser) {
          return res.status(404).json({
            error: "not_found",
            message: "Flutter app user not found.",
          });
        }
      }
    }

    const nextCustomerName = Object.prototype.hasOwnProperty.call(req.body, "customer_name")
      ? customer_name?.trim() || null
      : sale.customer_name;

    if (!appUserId && !nextCustomerName) {
      return res.status(400).json({
        error: "bad_request",
        message: "Customer name or Flutter app user is required",
      });
    }

    const updated = await run(
      `UPDATE sales
       SET app_user_id = $1, customer_name = $2, product_name = $3, quantity = $4,
           amount = $5, status = $6, notes = $7
       WHERE id = $8
       RETURNING *`,
      [
        appUserId,
        nextCustomerName,
        product_name ?? sale.product_name,
        quantity === undefined ? sale.quantity : parseInt(quantity),
        amount === undefined ? sale.amount : parseFloat(amount),
        status ?? sale.status,
        notes ?? sale.notes,
        saleId,
      ],
    );

    res.json({ message: "Sale updated", sale: updated });
  } catch (err) {
    console.error("[Sales] Update error:", err);
    res
      .status(500)
      .json({ error: "server_error", message: "Could not update sale" });
  }
}

async function deleteSale(req, res) {
  const saleId = req.params.id;

  try {
    const sale = await get("SELECT id FROM sales WHERE id = $1", [saleId]);
    if (!sale) {
      return res
        .status(404)
        .json({ error: "not_found", message: "Sale record not found" });
    }

    await run("DELETE FROM sales WHERE id = $1", [saleId]);
    res.json({ message: "Sale deleted successfully" });
  } catch (err) {
    console.error("[Sales] Delete error:", err);
    res
      .status(500)
      .json({ error: "server_error", message: "Could not delete sale" });
  }
}

// Dashboard analytics — real data from the shared local database
async function getDashboardStats(req, res) {
  try {
    // 1. Total revenue from completed sales
    const revenueRow = await get(
      `SELECT COALESCE(SUM(amount), 0) AS total FROM sales WHERE status = 'completed'`,
    );
    const totalRevenue = parseFloat(revenueRow.total);

    // 2. Total completed sales count
    const salesCountRow = await get(
      `SELECT COUNT(*) AS count FROM sales WHERE status = 'completed'`,
    );
    const totalSales = parseInt(salesCountRow.count);

    // 3. Total Flutter app users
    const appUserRow = await get(
      `SELECT COUNT(*) AS count FROM users WHERE role = 'user'`,
    );
    const totalAppUsers = parseInt(appUserRow.count);

    // 5. Deactivated app users
    const deactivatedRow = await get(
      isSQLite
        ? `SELECT COUNT(*) AS count FROM users WHERE role = 'user' AND is_active = 0`
        : `SELECT COUNT(*) AS count FROM users WHERE role = 'user' AND is_active = FALSE`,
    );
    const deactivatedUsers = parseInt(deactivatedRow.count);

    // 6. Active CRM employees
    const empRow = await get(
      `SELECT COUNT(*) AS count FROM crm_employees WHERE status = 'active'`,
    );
    const activeCRMEmployees = parseInt(empRow.count);

    // 7. Active firmware version
    const firmwareRow = await get(
      isSQLite
        ? `SELECT version FROM firmware WHERE is_active = 1 LIMIT 1`
        : `SELECT version FROM firmware WHERE is_active = TRUE LIMIT 1`,
    );
    const activeFirmware = firmwareRow
      ? firmwareRow.version
      : "No active build";

    // 8. Recent 5 sales with customer info
    const recentSalesResult = await query(
      `SELECT s.amount, s.product_name, s.sale_date, s.status,
              COALESCE(s.customer_name, u.username) AS customer_name,
              u.email AS customer_email
       FROM sales s
       LEFT JOIN users u ON s.app_user_id = u.id
       WHERE s.status = 'completed'
       ORDER BY s.sale_date DESC
       LIMIT 5`,
    );
    const recentSales = recentSalesResult.rows;

    // 9. Sales trend (last 5 months)
    const trendRowsResult = await query(
      isSQLite
        ? `SELECT strftime('%Y-%m', sale_date) AS month_key, COALESCE(SUM(amount), 0) AS sales
           FROM sales
           WHERE status = 'completed'
             AND sale_date >= datetime('now', '-5 months')
           GROUP BY month_key
           ORDER BY month_key ASC`
        : `SELECT
             TO_CHAR(DATE_TRUNC('month', sale_date), 'YYYY-MM') AS month_key,
             COALESCE(SUM(amount), 0) AS sales
           FROM sales
           WHERE status = 'completed'
             AND sale_date >= NOW() - INTERVAL '5 months'
           GROUP BY DATE_TRUNC('month', sale_date)
           ORDER BY DATE_TRUNC('month', sale_date) ASC`,
    );
    const trendRows = trendRowsResult.rows;

    // Fill in any missing months with 0
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    const now = new Date();
    const salesTrend = [];
    for (let i = 4; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const mon = months[d.getMonth()];
      const expectedMonth = d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0");
      const found = trendRows.find((r) => String(r.month_key).trim() === expectedMonth);
      salesTrend.push({
        month: mon,
        sales: found ? parseFloat(found.sales) : 0,
      });
    }

    // 10. New users registered per month (last 5 months)
    const userGrowthRowsResult = await query(
      isSQLite
        ? `SELECT strftime('%Y-%m', created_at) AS month_key, COUNT(*) AS count
           FROM users
           WHERE role = 'user'
             AND created_at >= datetime('now', '-5 months')
           GROUP BY month_key
           ORDER BY month_key ASC`
        : `SELECT
             TO_CHAR(DATE_TRUNC('month', created_at), 'YYYY-MM') AS month_key,
             COUNT(*) AS count
           FROM users
           WHERE role = 'user'
             AND created_at >= NOW() - INTERVAL '5 months'
           GROUP BY DATE_TRUNC('month', created_at)
           ORDER BY DATE_TRUNC('month', created_at) ASC`,
    );
    const userGrowthRows = userGrowthRowsResult.rows;

    const userGrowth = [];
    for (let i = 4; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const mon = months[d.getMonth()];
      const expectedMonth = d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0");
      const found = userGrowthRows.find(
        (r) => String(r.month_key).trim() === expectedMonth,
      );
      userGrowth.push({ month: mon, count: found ? parseInt(found.count) : 0 });
    }

    res.json({
      metrics: {
        totalRevenue,
        totalSales,
        totalAppUsers,
        deactivatedUsers,
        activeCRMEmployees,
        activeFirmware,
      },
      recentSales,
      salesTrend,
      userGrowth,
    });
  } catch (err) {
    console.error("[Dashboard] Stats error:", err);
    res
      .status(500)
      .json({
        error: "server_error",
        message: "Could not fetch dashboard metrics",
      });
  }
}

module.exports = { listSales, addSale, updateSale, deleteSale, getDashboardStats };
