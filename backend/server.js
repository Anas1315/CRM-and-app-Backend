const express = require("express");
const cors = require("cors");
const path = require("path");
const multer = require("multer");
const fs = require("fs");

require("dotenv").config({ path: path.resolve(__dirname, ".env") });

// Initialize database (creates tables if missing)
const { initializeDatabase } = require("./database");

// Middleware & Controllers
const {
  authenticateCRMEmployee,
  requireCRMRole,
} = require("./middleware/auth");
const crmAuthController = require("./controllers/authController"); // CRM staff auth
const appAuthController = require("./controllers/appAuthController"); // Mobile app auth & device data
const energyController = require("./controllers/energyController");
const employeeController = require("./controllers/employeeController");
const crmController = require("./controllers/crmController");
const firmwareController = require("./controllers/firmwareController");
const productController = require("./controllers/productController");

const app = express();
const PORT = process.env.PORT || 5000;

// ── Middleware ──────────────────────────────────────────────
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  }),
);
app.use(express.json());

// Multer setup for firmware uploads
const uploadsPath = path.resolve(__dirname, "uploads");
if (!fs.existsSync(uploadsPath)) fs.mkdirSync(uploadsPath, { recursive: true });
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsPath),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `firmware-${Date.now()}-${Math.round(Math.random() * 1e6)}${ext}`);
  },
});
const upload = multer({
  storage,
  fileFilter: (_req, file, cb) => {
    if (path.extname(file.originalname).toLowerCase() === ".bin")
      cb(null, true);
    else cb(new Error("Only .bin files are allowed"));
  },
  limits: { fileSize: 10 * 1024 * 1024 },
});
app.use("/uploads", express.static(uploadsPath));

// ── 1️⃣ Mobile App Auth (public) ────────────────────────────────
app.post("/api/app/auth/signup", appAuthController.signup);
app.post("/api/app/auth/login", appAuthController.login);

// ── 2️⃣ Public ESP32 data endpoint ───────────────────────────────
app.post("/api/devices/:deviceId/data", appAuthController.receiveDeviceData);

// ── 2️⃣.a Energy API for Flutter app compatibility ──────────────────
app.get("/api/status", energyController.getStatus);
app.get("/api/daily-stats", energyController.getDailyStats);
app.get("/api/hourly-data", energyController.getHourlyData);
app.get("/api/events", energyController.getEvents);
app.get("/api/alerts", energyController.getAlerts);
app.post("/api/command", energyController.sendCommand);
app.delete("/api/clear-events", energyController.clearEvents);
app.post("/api/mark-alerts-read", energyController.markAlertsRead);
app.post("/api/mark-alert-read", energyController.markAlertRead);

// ── 3️⃣ CRM EMPLOYEE AUTH (portal) ───────────────────────────────
// CRM login/signup routes — wrapped to help debug routing mismatches
app.post("/api/auth/login", (req, res) => {
  console.log("[Server] Received POST /api/auth/login");
  return crmAuthController.login(req, res);
});
app.post("/api/auth/signup", (req, res) => {
  console.log("[Server] Received POST /api/auth/signup");
  return crmAuthController.signup(req, res);
});
app.post("/api/auth/google-login", (_req, res) => {
  res.status(501).json({
    error: "not_supported",
    message: "Google login is not supported by the CRM backend.",
  });
});
app.get("/api/auth/setup-status", (_req, res) => {
  res.json({ needsSetup: false });
});
app.post("/api/auth/setup", (_req, res) => {
  res.status(501).json({
    error: "not_supported",
    message: "Setup is managed through the CRM portal backend.",
  });
});
app.post("/api/auth/forgot-password", appAuthController.forgotPassword);
app.post("/api/auth/reset-password", appAuthController.resetPassword);
app.get("/api/auth/me", authenticateCRMEmployee, (req, res) => {
  console.log("[Server] Received GET /api/auth/me");
  return crmAuthController.me(req, res);
});

// ── 4️⃣ CRM EMPLOYEES (internal staff) ───────────────────────────
app.get(
  "/api/employees",
  authenticateCRMEmployee,
  employeeController.listEmployees,
);
app.post(
  "/api/employees",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  employeeController.addEmployee,
);
app.put(
  "/api/employees/:id",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  employeeController.updateEmployee,
);
app.delete(
  "/api/employees/:id",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  employeeController.deleteEmployee,
);

// ── 5️⃣ FLUTTER APP USER MANAGEMENT (shared DB) ───────────────────
app.get(
  "/api/app-users",
  authenticateCRMEmployee,
  employeeController.listAppUsers,
);
app.get(
  "/api/app-users/:id",
  authenticateCRMEmployee,
  employeeController.getAppUser,
);
app.patch(
  "/api/app-users/:id/status",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  employeeController.setAppUserStatus,
);
app.delete(
  "/api/app-users/:id",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  employeeController.deleteAppUser,
);

// ── 6️⃣ PRODUCTS & DEVICES (CRM side) ───────────────────────────
app.get(
  "/api/products",
  authenticateCRMEmployee,
  productController.listProducts,
);
app.post(
  "/api/products",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  productController.addProduct,
);
app.put(
  "/api/products/:id",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  productController.updateProduct,
);
app.delete(
  "/api/products/:id",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  productController.deleteProduct,
);
app.post(
  "/api/devices/register",
  authenticateCRMEmployee,
  requireCRMRole("admin"),
  productController.registerDevice,
);

// ── 7️⃣ SALES RECORDS ────────────────────────────────────────
app.get("/api/sales", authenticateCRMEmployee, crmController.listSales);
app.post("/api/sales", authenticateCRMEmployee, crmController.addSale);
app.patch("/api/sales/:id", authenticateCRMEmployee, crmController.updateSale);
app.delete("/api/sales/:id", authenticateCRMEmployee, crmController.deleteSale);

// ── 8️⃣ DASHBOARD ANALYTICS ───────────────────────────────────
app.get(
  "/api/dashboard/stats",
  authenticateCRMEmployee,
  crmController.getDashboardStats,
);

// ── 9️⃣ FIRMWARE OTA ─────────────────────────────────────────────
app.get(
  "/api/firmware/list",
  authenticateCRMEmployee,
  firmwareController.listFirmware,
);
app.post(
  "/api/firmware/upload",
  authenticateCRMEmployee,
  upload.single("firmware"),
  firmwareController.uploadFirmware,
);
app.patch(
  "/api/firmware/:id/activate",
  authenticateCRMEmployee,
  firmwareController.activateFirmware,
);
app.delete(
  "/api/firmware/:id",
  authenticateCRMEmployee,
  firmwareController.deleteFirmware,
);
// Public OTA endpoints (no auth – ESP32 cannot send JWT)
app.get("/api/firmware/ota/check", firmwareController.otaCheck);
app.get("/api/firmware/ota/download", firmwareController.otaDownload);

// Global error handler for multer & others
app.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError || err.message?.includes(".bin")) {
    return res
      .status(400)
      .json({ error: "upload_error", message: err.message });
  }
  console.error("[Server] Unhandled error:", err);
  res.status(500).json({ error: "server_error", message: err.message });
});

initializeDatabase
  .then(() => {
    app.listen(PORT, "0.0.0.0", () => {
      console.log(
        "\n╔══════════════════════════════════════════════════════════╗",
      );
      console.log(
        "║      SOLAR CRM - BACKEND SERVER (SQLite/local)           ║",
      );
      console.log(
        "╠══════════════════════════════════════════════════════════╣",
      );
      console.log(
        `║  CRM Portal:      http://localhost:${PORT}                  ║`,
      );
      console.log("║  Mobile App Auth: /api/app/auth/*                     ║");
      console.log("║  ESP32 OTA:       /api/firmware/ota/*                  ║");
      console.log(
        "╚══════════════════════════════════════════════════════════╝\n",
      );
    });
  })
  .catch((err) => {
    console.error("[Server] Failed to initialize database:", err);
    process.exit(1);
  });
