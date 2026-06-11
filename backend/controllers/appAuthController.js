const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { get, run, query } = require("../database");

// Allow delegating to CRM auth when needed
const crmAuthController = require("./authController");

// JWT secret for app users – reuse the one from .env or fallback
const APP_JWT_SECRET =
  process.env.APP_JWT_SECRET || "flutter_app_secret_!@#2024";

/**
 * Sign‑up a new mobile app user.
 * Expected payload: { username, email, password, device_id, product_id }
 * Flow:
 *   1️⃣ Verify the device_id exists in `devices` table.
 *   2️⃣ Ensure the device is not already assigned to another user.
 *   3️⃣ Create the user (store hashed password, link device via `device_id`).
 *   4️⃣ Update the `devices.assigned_user_id` foreign key.
 *   5️⃣ Return JWT + user info.
 */
async function signup(req, res) {
  const { username, email, password, device_id, product_id } = req.body;
  const submittedProductId = String(device_id || product_id || "").trim();
  if (!username || !email || !password || !submittedProductId) {
    return res.status(400).json({
      error: "bad_request",
      message: "Name, email, password, and Product ID / Device ID are required",
    });
  }

  try {
    const existingEmail = await get("SELECT id FROM users WHERE email = $1", [
      email,
    ]);
    if (existingEmail) {
      return res.status(409).json({
        error: "email_taken",
        message: "This email is already registered",
      });
    }

    // 1️⃣ Resolve product type by checking prefix of submittedProductId (case-insensitive)
    let productCodePattern = "SKU-WHL-0001"; // default
    if (/SKU-MSS/i.test(submittedProductId)) {
      productCodePattern = "SKU-MSS-0001";
    } else if (/SKU-FSS/i.test(submittedProductId)) {
      productCodePattern = "SKU-FSS-0001";
    }

    let product = await get(
      "SELECT * FROM products WHERE product_code = $1 OR name = $1",
      [productCodePattern],
    );

    if (!product) {
      // Create fallback products if not present
      const defaultProductId = await run(
        `
        INSERT INTO products (name, product_code, stock)
        VALUES ('Smart Energy Controller', $1, 999)
        RETURNING id
      `,
        [productCodePattern],
      );
      product = {
        id: defaultProductId.id || defaultProductId,
        product_code: productCodePattern,
      };
    }

    // Check if device already exists with this exact UID (e.g. SKU-WHL-0001 or SKU-WHL-1234)
    let device = await get("SELECT * FROM devices WHERE device_uid = $1", [
      submittedProductId,
    ]);

    if (!device) {
      // Register this new device on-the-fly with the exact submitted string as the device_uid
      await run(
        "INSERT INTO devices (device_uid, product_id) VALUES ($1, $2)",
        [submittedProductId, product.id],
      );
      device = await get("SELECT * FROM devices WHERE device_uid = $1", [
        submittedProductId,
      ]);
      console.log(
        `[Signup] Created device on-the-fly with requested UID: ${submittedProductId} for product: ${product.product_code}`,
      );
    }

    // 2️⃣ Ensure device is not already bound to another user
    if (device.assigned_user_id) {
      return res.status(409).json({
        error: "product_already_used",
        message: "Product ID / Device ID is already linked to another user",
      });
    }

    // 3️⃣ Create user
    const hash = await bcrypt.hash(password, 10);
    let newUser = await run(
      `INSERT INTO users (username, email, password, device_id, is_active, role)
       VALUES ($1, $2, $3, $4, TRUE, 'user')
       RETURNING id, username, email, device_id, is_active, role, created_at`,
      [username, email, hash, device.device_uid],
    );

    // Retrieve full user profile details
    newUser = await get(
      `SELECT u.id, u.username, u.email, u.device_id, u.is_active, u.role, u.created_at, p.product_code, p.name AS product_name
       FROM users u
       LEFT JOIN devices d ON d.device_uid = u.device_id
       LEFT JOIN products p ON p.id = d.product_id
       WHERE u.id = $1`,
      [newUser.id],
    );

    // 4️⃣ Bind device and decrement stock
    await query("UPDATE devices SET assigned_user_id = $1 WHERE id = $2", [
      newUser.id,
      device.id,
    ]);

    if (product && product.stock > 0) {
      await query("UPDATE products SET stock = stock - 1 WHERE id = $1", [
        product.id,
      ]);
    }

    // 5️⃣ Issue JWT
    const token = jwt.sign(
      { id: newUser.id, email: newUser.email, role: newUser.role },
      APP_JWT_SECRET,
      { expiresIn: "7d" },
    );

    res.status(201).json({
      message: "Signup successful. Product ID validated.",
      token,
      user: newUser,
    });
  } catch (err) {
    console.error("[App Auth] Signup error:", err);
    if (err.code === "23505") {
      // unique violation
      return res.status(409).json({
        error: "duplicate",
        message: "Email or Product ID already in use",
      });
    }
    res.status(500).json({ error: "server_error", message: "Signup failed" });
  }
}

/**
 * Login for mobile app users (email + password).
 */
async function login(req, res) {
  const { email, password } = req.body;
  console.log("[App Auth] login called for", email);
  if (!email || !password) {
    return res
      .status(400)
      .json({ error: "bad_request", message: "Email and password required" });
  }
  try {
    // First check if this is a regular app user
    const user = await get(
      `SELECT u.*, p.product_code, p.name AS product_name
       FROM users u
       LEFT JOIN devices d ON d.device_uid = u.device_id
       LEFT JOIN products p ON p.id = d.product_id
       WHERE u.email = $1`,
      [email],
    );

    if (user) {
      const match = await bcrypt.compare(password, user.password);
      if (!match) {
        return res.status(401).json({
          error: "invalid_credentials",
          message: "Wrong email or password",
        });
      }
      if (!user.is_active) {
        return res.status(403).json({
          error: "account_blocked",
          message: "User is deactivated. Please contact support.",
        });
      }
      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role },
        APP_JWT_SECRET,
        { expiresIn: "7d" },
      );
      const { password: _, ...safeUser } = user;
      return res.json({ message: "Login successful", token, user: safeUser });
    }

    // If not found in users table, check CRM employees table
    // (CRM admins may also use the mobile app)
    const employee = await get("SELECT * FROM crm_employees WHERE email = $1", [
      email,
    ]);
    if (employee) {
      const match = await bcrypt.compare(password, employee.password);
      if (!match) {
        return res.status(401).json({
          error: "invalid_credentials",
          message: "Wrong email or password",
        });
      }
      if (employee.status === "terminated") {
        return res.status(403).json({
          error: "account_terminated",
          message: "Your access has been revoked. Contact administrator.",
        });
      }
      // Use APP_JWT_SECRET (not CRM secret) so the mobile app can use this token
      const token = jwt.sign(
        { id: employee.id, email: employee.email, role: employee.role },
        APP_JWT_SECRET,
        { expiresIn: "7d" },
      );
      const { password: _, ...safeEmployee } = employee;
      // Return as 'user' key so the Flutter app can parse it uniformly
      return res.json({
        message: "Login successful",
        token,
        user: {
          id: safeEmployee.id,
          username: safeEmployee.name,
          email: safeEmployee.email,
          role: safeEmployee.role,
          device_id: null,
          product_code: null,
          is_active: safeEmployee.status === "active",
        },
      });
    }

    // Neither app user nor CRM employee found
    return res.status(401).json({
      error: "invalid_credentials",
      message: "Wrong email or password",
    });
  } catch (err) {
    console.error("[App Auth] Login error:", err);
    res.status(500).json({ error: "server_error", message: "Login failed" });
  }
}

/**
 * Public ESP32 data endpoint – device authenticates via its UID.
 * Route: POST /api/devices/:deviceId/data
 * Body: any JSON payload from the controller.
 * Behaviour:
 *   • Verify device exists.
 *   • Resolve assigned user (if any).
 *   • Forward payload to a generic handler (`processDeviceData`).
 *   • Respond with 200 OK.
 */
async function receiveDeviceData(req, res) {
  const { deviceId } = req.params;
  const { wapdaAvailable, wapdaRelayState, heavyLoadState, isDayTime } =
    req.body;

  console.log(`\x1b[36m[ESP32 -> Backend]\x1b[0m Device: ${deviceId}`, {
    wapdaAvailable,
    wapdaRelayState,
    heavyLoadState,
    isDayTime,
  });

  try {
    // 1️⃣ Ensure device exists in devices table
    let device = await get("SELECT * FROM devices WHERE device_uid = $1", [
      deviceId,
    ]);
    if (!device) {
      let product = await get("SELECT id FROM products LIMIT 1");
      if (!product) {
        product = await run(`
          INSERT INTO products (name, product_code, stock)
          VALUES ('Default Solar Controller', 'SKU-DEFAULT', 99)
          RETURNING id
        `);
        product = { id: product.id || product };
      }
      await run(
        "INSERT INTO devices (device_uid, product_id) VALUES ($1, $2)",
        [deviceId, product.id],
      );
      // Fetch the newly created device
      device = await get("SELECT * FROM devices WHERE device_uid = $1", [
        deviceId,
      ]);
    }

    // NOTE: Do not auto-pair dummy users. Devices must use real device_uid (e.g. SKU-xxx-xxxx)
    // and be registered/bound via the mobile app/auth flow.

    // 2️⃣ Fetch previous state for comparisons to trigger notifications
    const prevControls = await get(
      "SELECT wapda_available, wapda_relay_actual, heavy_load_actual FROM device_controls WHERE device_uid = $1",
      [deviceId],
    );

    const helperLogEvent = async (type, title, message) => {
      await run(
        "INSERT INTO device_events (device_uid, type, title, message) VALUES ($1, $2, $3, $4)",
        [deviceId, type, title, message],
      );
    };

    if (prevControls) {
      // WAPDA Available Check (Main Grid Line)
      if (wapdaAvailable !== undefined) {
        const isCurrentAvailable = !!wapdaAvailable;
        const isPrevAvailable = !!prevControls.wapda_available;
        if (isCurrentAvailable !== isPrevAvailable) {
          if (isCurrentAvailable) {
            await helperLogEvent(
              "success",
              "WAPDA Grid Connected",
              "WAPDA grid power detected from the main line.",
            );
          } else {
            await helperLogEvent(
              "danger",
              "WAPDA Grid Disconnected",
              "WAPDA grid power outage detected.",
            );
          }
        }
      }

      // WAPDA Relay Actual Check (Home WAPDA Relay Feedback)
      if (wapdaRelayState !== undefined) {
        const isCurrentRelay = !!wapdaRelayState;
        const isPrevRelay = !!prevControls.wapda_relay_actual;
        if (isCurrentRelay !== isPrevRelay) {
          if (isCurrentRelay) {
            await helperLogEvent(
              "success",
              "Home WAPDA Turned ON",
              "Home WAPDA relay is now active (Confirmed by device).",
            );
          } else {
            await helperLogEvent(
              "warning",
              "Home WAPDA Turned OFF",
              "Home WAPDA relay has been turned off (Confirmed by device).",
            );
          }
        }
      }

      // Heavy Load Relay Actual Check (Feedback)
      if (heavyLoadState !== undefined) {
        const isCurrentLoad = !!heavyLoadState;
        const isPrevLoad = !!prevControls.heavy_load_actual;
        if (isCurrentLoad !== isPrevLoad) {
          if (isCurrentLoad) {
            await helperLogEvent(
              "success",
              "Heavy Load Turned ON",
              "Heavy load relay is now active (Confirmed by device).",
            );
          } else {
            await helperLogEvent(
              "warning",
              "Heavy Load Turned OFF",
              "Heavy load relay has been turned off (Confirmed by device).",
            );
          }
        }
      }
    }

    // 3️⃣ Upsert telemetry data in device_controls
    await run(
      `
      INSERT INTO device_controls (
        device_uid, wapda_available, wapda_relay_actual, heavy_load_actual, is_day_time, last_update
      ) VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
      ON CONFLICT (device_uid) DO UPDATE SET
        wapda_available = EXCLUDED.wapda_available,
        wapda_relay_actual = EXCLUDED.wapda_relay_actual,
        heavy_load_actual = EXCLUDED.heavy_load_actual,
        is_day_time = EXCLUDED.is_day_time,
        last_update = CURRENT_TIMESTAMP
    `,
      [
        deviceId,
        wapdaAvailable !== undefined ? !!wapdaAvailable : true,
        wapdaRelayState !== undefined ? !!wapdaRelayState : true,
        heavyLoadState !== undefined ? !!heavyLoadState : true,
        isDayTime !== undefined ? !!isDayTime : true,
      ],
    );

    // 4️⃣ Get latest controls to return to the ESP32
    let controls = await get(
      "SELECT * FROM device_controls WHERE device_uid = $1",
      [deviceId],
    );
    if (!controls) {
      controls = {
        wapda_auto_mode: true,
        wapda_relay_state: true,
        heavy_load_auto_mode: true,
        heavy_load_state: true,
        day_start: "08:00",
        day_end: "18:00",
      };
    }

    res.json({
      status: "success",
      wapdaAutoMode: !!controls.wapda_auto_mode,
      wapdaRelayState: !!controls.wapda_relay_state,
      heavyLoadAutoMode: !!controls.heavy_load_auto_mode,
      heavyLoadState: !!controls.heavy_load_state,
      dayStart: controls.day_start || "08:00",
      dayEnd: controls.day_end || "18:00",
    });
  } catch (err) {
    console.error("[Device Data] Error:", err);
    res.status(500).json({
      error: "server_error",
      message: "Failed to process device data",
    });
  }
}

async function forgotPassword(req, res) {
  const { email, phone } = req.body;
  const target = email || phone;
  if (!target) {
    return res.status(400).json({ error: "bad_request", message: "Email or phone is required" });
  }

  try {
    const user = await get(
      "SELECT * FROM users WHERE email = $1 OR phone_number = $1",
      [target]
    );

    if (!user) {
      return res.status(404).json({ error: "not_found", message: "No account found with this contact info" });
    }

    // Generate a 6-digit random code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date(Date.now() + 15 * 60 * 1000).toISOString(); // 15 mins

    await query(
      "UPDATE users SET reset_code = $1, reset_code_expires = $2 WHERE id = $3",
      [code, expires, user.id]
    );

    console.log(`\x1b[35m[PASSWORD RESET]\x1b[0m Generated code for ${target}: ${code} (expires ${expires})`);

    res.json({
      message: "Reset code generated successfully",
      user_id: user.id,
      code: code
    });
  } catch (err) {
    console.error("[App Auth] Forgot password error:", err);
    res.status(500).json({ error: "server_error", message: "Failed to request reset code" });
  }
}

async function resetPassword(req, res) {
  const { user_id, code, new_password } = req.body;
  if (!user_id || !code || !new_password) {
    return res.status(400).json({ error: "bad_request", message: "user_id, code, and new_password are required" });
  }

  try {
    const user = await get("SELECT * FROM users WHERE id = $1", [user_id]);
    if (!user) {
      return res.status(404).json({ error: "not_found", message: "User not found" });
    }

    if (!user.reset_code || user.reset_code !== code) {
      return res.status(400).json({ error: "invalid_code", message: "Invalid reset code" });
    }

    const expiryTime = new Date(user.reset_code_expires).getTime();
    if (Date.now() > expiryTime) {
      return res.status(400).json({ error: "expired_code", message: "Reset code has expired" });
    }

    // Hash the new password
    const hash = await bcrypt.hash(new_password, 10);
    await query(
      "UPDATE users SET password = $1, reset_code = NULL, reset_code_expires = NULL WHERE id = $2",
      [hash, user.id]
    );

    console.log(`\x1b[35m[PASSWORD RESET]\x1b[0m Password reset successfully for user ID ${user.id}`);
    res.json({ message: "Password reset successful" });
  } catch (err) {
    console.error("[App Auth] Reset password error:", err);
    res.status(500).json({ error: "server_error", message: "Failed to reset password" });
  }
}

module.exports = { signup, login, receiveDeviceData, forgotPassword, resetPassword };

