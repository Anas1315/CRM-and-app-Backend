const jwt = require("jsonwebtoken");
const { get, run, query } = require("../database");
const APP_JWT_SECRET =
  process.env.APP_JWT_SECRET || "flutter_app_secret_!@#2024";

// Helper to get device_uid from authenticated app user's JWT token
async function getDeviceUid(req) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];
  if (token) {
    try {
      const decoded = jwt.verify(token, APP_JWT_SECRET);
      const user = await get("SELECT device_id FROM users WHERE id = $1", [
        decoded.id,
      ]);
      if (user && user.device_id) {
        return user.device_id;
      }
    } catch (err) {
      console.error("JWT verification failed, falling back:", err.message);
    }
  }

  // Fallback: get the first device registered in devices
  const firstDev = await get("SELECT device_uid FROM devices LIMIT 1");
  return firstDev ? firstDev.device_uid : "default_device";
}

async function getStatus(req, res) {
  try {
    const deviceId = await getDeviceUid(req);

    // Ensure we have a row in device_controls for this device
    let controls = await get(
      "SELECT * FROM device_controls WHERE device_uid = $1",
      [deviceId],
    );
    if (!controls) {
      await run(
        `
        INSERT INTO device_controls (
          device_uid, wapda_auto_mode, wapda_relay_state, heavy_load_auto_mode, heavy_load_state, day_start, day_end
        ) VALUES ($1, TRUE, TRUE, TRUE, TRUE, '08:00', '18:00')
        ON CONFLICT (device_uid) DO NOTHING
      `,
        [deviceId],
      );
      controls = await get(
        "SELECT * FROM device_controls WHERE device_uid = $1",
        [deviceId],
      );
    }

    const now = new Date();
    const currentHour = now.getHours();

    // Determine if ESP32 is online (last update within last 45 seconds)
    let esp32Online = false;
    if (controls.last_update) {
      const lastUpdateMs = new Date(controls.last_update).getTime();
      const diffSeconds = Math.abs((Date.now() - lastUpdateMs) / 1000);
      esp32Online = diffSeconds < 45;
    }

    const wapdaAvailable = !!controls.wapda_available;

    // isDayTime: use value reported by ESP32 (from its RTC + schedule).
    // Fallback to schedule-based computation if ESP32 hasn't reported yet.
    let isDayTime;
    if (
      esp32Online &&
      controls.is_day_time !== undefined &&
      controls.is_day_time !== null
    ) {
      isDayTime = !!controls.is_day_time;
    } else {
      const dayStartStr = controls.day_start || "08:00";
      const dayEndStr = controls.day_end || "18:00";
      const [dsH, dsM] = dayStartStr.split(":").map(Number);
      const [deH, deM] = dayEndStr.split(":").map(Number);
      const currentMinutes = now.getHours() * 60 + now.getMinutes();
      const startMinutes = (dsH || 8) * 60 + (dsM || 0);
      const endMinutes = (deH || 18) * 60 + (deM || 0);
      isDayTime =
        startMinutes < endMinutes
          ? currentMinutes >= startMinutes && currentMinutes < endMinutes
          : currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }

    res.json({
      wapdaAvailable: wapdaAvailable,
      isDayTime: isDayTime,
      wapdaRelayState:
        controls.wapda_relay_actual !== undefined &&
        controls.wapda_relay_actual !== null
          ? !!controls.wapda_relay_actual
          : !!controls.wapda_relay_state,
      heavyLoadState:
        controls.heavy_load_actual !== undefined &&
        controls.heavy_load_actual !== null
          ? !!controls.heavy_load_actual
          : !!controls.heavy_load_state,
      wapdaAutoMode: !!controls.wapda_auto_mode,
      heavyLoadAutoMode: !!controls.heavy_load_auto_mode,
      dayStart: controls.day_start || "08:00",
      dayEnd: controls.day_end || "18:00",
      currentHour,
      lastUpdate: controls.last_update
        ? new Date(controls.last_update).getTime()
        : now.getTime(),
      esp32Online,
    });
  } catch (err) {
    console.error("[Energy API] Status fetch error:", err);
    res
      .status(500)
      .json({
        error: "server_error",
        message: "Failed to fetch device status",
      });
  }
}

async function getDailyStats(_req, res) {
  const now = new Date();
  const date = `${now.getMonth() + 1}/${now.getDate()}/${now.getFullYear()}`;

  res.json({
    date,
    wapdaUsageHours: 6.2,
    loadOnHours: 9.5,
    solarSavingHours: 14.3,
    totalSwitches: 18,
    peakPower: 4.1,
    avgVoltage: 221.7,
    energyGenerated: 5200,
    energyConsumed: 9800,
    unitsConsumed: "9.8",
    unitsSaved: "5.2",
    costUsed: "294",
    costSaved: "156",
    lastWapdaOnTime: new Date(now.getTime() - 4 * 60 * 60 * 1000).toISOString(),
    lastWapdaOffTime: new Date(
      now.getTime() - 2 * 60 * 60 * 1000,
    ).toISOString(),
    lastLoadOnTime: new Date(now.getTime() - 3 * 60 * 60 * 1000).toISOString(),
    lastLoadOffTime: new Date(now.getTime() - 1 * 60 * 60 * 1000).toISOString(),
  });
}

async function getHourlyData(_req, res) {
  const now = new Date();
  const data = Array.from({ length: 12 }, (_, index) => {
    const hour = (now.getHours() - (11 - index) + 24) % 24;
    return {
      hour,
      voltage: 214 + Math.sin(index / 2) * 5,
      current: 2.3 + Math.cos(index / 3) * 0.4,
      power: 280000 + index * 9000,
      ldrValue: hour >= 8 && hour <= 18 ? 2100 + index * 20 : 800,
    };
  });

  res.json(data);
}

async function getEvents(req, res) {
  try {
    const deviceId = await getDeviceUid(req);
    const rows = await query(
      "SELECT * FROM device_events WHERE device_uid = $1 ORDER BY created_at DESC LIMIT 50",
      [deviceId],
    );

    const events = (rows.rows || rows).map((row) => ({
      id: row.id.toString(),
      type: row.type || "info",
      title: row.title,
      message: row.message,
      timestamp: row.created_at
        ? new Date(row.created_at).toISOString()
        : new Date().toISOString(),
      isRead: !!row.is_read,
    }));

    res.json(events);
  } catch (err) {
    console.error("[Energy Controller] getEvents error:", err);
    res
      .status(500)
      .json({ error: "server_error", message: "Failed to get events" });
  }
}

async function getAlerts(req, res) {
  try {
    const deviceId = await getDeviceUid(req);
    const rows = await query(
      "SELECT * FROM device_events WHERE device_uid = $1 AND type IN ('danger', 'warning') ORDER BY created_at DESC LIMIT 50",
      [deviceId],
    );

    const alerts = (rows.rows || rows).map((row) => ({
      id: row.id.toString(),
      type: row.type || "warning",
      title: row.title,
      message: row.message,
      timestamp: row.created_at
        ? new Date(row.created_at).toISOString()
        : new Date().toISOString(),
      isRead: !!row.is_read,
    }));

    res.json(alerts);
  } catch (err) {
    console.error("[Energy Controller] getAlerts error:", err);
    res
      .status(500)
      .json({ error: "server_error", message: "Failed to get alerts" });
  }
}

async function sendCommand(req, res) {
  const { type, value } = req.body;
  if (!type || value === undefined) {
    return res.status(400).json({
      error: "bad_request",
      message: "Command type and value are required",
    });
  }

  try {
    const deviceId = await getDeviceUid(req);
    console.log(
      `[Energy API] Received command: ${type} = ${JSON.stringify(value)} for Device: ${deviceId}`,
    );

    // Ensure device_controls row exists before updating
    await run(
      `
      INSERT INTO device_controls (device_uid, wapda_auto_mode, wapda_relay_state, heavy_load_auto_mode, heavy_load_state, day_start, day_end)
      VALUES ($1, TRUE, TRUE, TRUE, TRUE, '08:00', '18:00')
      ON CONFLICT (device_uid) DO NOTHING
    `,
      [deviceId],
    );

    const helperLogEvent = async (evtType, title, message) => {
      await run(
        "INSERT INTO device_events (device_uid, type, title, message) VALUES ($1, $2, $3, $4)",
        [deviceId, evtType, title, message],
      );
    };

    // Update state based on command type and log the action
    if (type === "WAPDA_MODE") {
      const auto = value === 1;
      if (!auto) {
        await run(
          `UPDATE device_controls SET wapda_auto_mode = false, wapda_relay_state = COALESCE(wapda_relay_actual, wapda_relay_state) WHERE device_uid = $1`,
          [deviceId],
        );
      } else {
        await run(
          `UPDATE device_controls SET wapda_auto_mode = true WHERE device_uid = $1`,
          [deviceId],
        );
      }
      await helperLogEvent(
        "info",
        auto ? "Home WAPDA Auto Mode" : "Home WAPDA Manual Mode",
        auto
          ? "Home WAPDA Control switched to Automatic mode."
          : "Home WAPDA Control switched to Manual mode.",
      );
    } else if (type === "WAPDA_RELAY") {
      const state = value === 1;
      await run(
        `UPDATE device_controls SET wapda_relay_state = $1 WHERE device_uid = $2`,
        [state, deviceId],
      );
      await helperLogEvent(
        "info",
        state ? "Home WAPDA ON Command Sent" : "Home WAPDA OFF Command Sent",
        state
          ? "Manual command sent to turn Home WAPDA connection ON."
          : "Manual command sent to turn Home WAPDA connection OFF.",
      );
    } else if (type === "HEAVY_LOAD_MODE") {
      const auto = value === 1;
      if (!auto) {
        await run(
          `UPDATE device_controls SET heavy_load_auto_mode = false, heavy_load_state = COALESCE(heavy_load_actual, heavy_load_state) WHERE device_uid = $1`,
          [deviceId],
        );
      } else {
        await run(
          `UPDATE device_controls SET heavy_load_auto_mode = true WHERE device_uid = $1`,
          [deviceId],
        );
      }
      await helperLogEvent(
        "info",
        auto ? "Heavy Load Auto Mode" : "Heavy Load Manual Mode",
        auto
          ? "Heavy Load Relay switched to Automatic mode."
          : "Heavy Load Relay switched to Manual mode.",
      );
    } else if (type === "HEAVY_LOAD") {
      const state = value === 1;
      await run(
        `UPDATE device_controls SET heavy_load_state = $1 WHERE device_uid = $2`,
        [state, deviceId],
      );
      await helperLogEvent(
        "info",
        state ? "Heavy Load ON Command Sent" : "Heavy Load OFF Command Sent",
        state
          ? "Manual command sent to turn Heavy Load relay ON."
          : "Manual command sent to turn Heavy Load relay OFF.",
      );
    } else if (type === "WAPDA_TIME") {
      const dayStart = value.dayStart || "08:00";
      const dayEnd = value.dayEnd || "18:00";
      await run(
        `UPDATE device_controls SET day_start = $1, day_end = $2 WHERE device_uid = $3`,
        [dayStart, dayEnd, deviceId],
      );
      await helperLogEvent(
        "info",
        "Schedule Updated",
        `Day time range configured: ${dayStart} to ${dayEnd}.`,
      );
    }

    res.json({
      message: "Command received and applied",
      type,
      value,
    });
  } catch (err) {
    console.error("[Energy API] Command application error:", err);
    res
      .status(500)
      .json({ error: "server_error", message: "Failed to apply command" });
  }
}

async function clearEvents(req, res) {
  try {
    const deviceId = await getDeviceUid(req);
    await run("DELETE FROM device_events WHERE device_uid = $1", [deviceId]);
    res.json({ message: "Events cleared" });
  } catch (err) {
    console.error("clearEvents error:", err);
    res.status(500).json({ error: "server_error" });
  }
}

async function markAlertsRead(req, res) {
  try {
    const deviceId = await getDeviceUid(req);
    await run("UPDATE device_events SET is_read = TRUE WHERE device_uid = $1", [
      deviceId,
    ]);
    res.json({ message: "Alerts marked read" });
  } catch (err) {
    console.error("markAlertsRead error:", err);
    res.status(500).json({ error: "server_error" });
  }
}

async function markAlertRead(req, res) {
  const { id } = req.body;
  if (!id) {
    return res.status(400).json({
      error: "bad_request",
      message: "Alert id is required",
    });
  }
  try {
    await run("UPDATE device_events SET is_read = TRUE WHERE id = $1", [id]);
    res.json({ message: "Alert marked read", id });
  } catch (err) {
    console.error("markAlertRead error:", err);
    res.status(500).json({ error: "server_error" });
  }
}

module.exports = {
  getStatus,
  getDailyStats,
  getHourlyData,
  getEvents,
  getAlerts,
  sendCommand,
  clearEvents,
  markAlertsRead,
  markAlertRead,
};
