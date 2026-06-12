/**
 * ============================================================
 *  ESP32 Smart Solar Controller — Relay Controller
 *  With DS3231 RTC, WiFi AP Provisioning & Dynamic Scheduler
 * ============================================================
 */

#include <ArduinoJson.h>
#include <HTTPClient.h>
#include <HTTPUpdate.h>
#include <Preferences.h>
#include <RTClib.h>
#include <WebServer.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <Wire.h>

// ========================
// OTA & Telemetry API Configuration
// ========================
// Production cloud backend (Render). ESP32 can reach this from any WiFi.
// Can be overridden per-device via the AP provisioning portal.
const char *defaultApiBaseUrl = "https://crm-backend-ukfa.onrender.com";
String apiBaseUrl = defaultApiBaseUrl;
String deviceUid = ""; // Dynamically loaded from NVS or MAC address

// ========================
// Pin Declarations
// ========================
const int WAPDA_RELAY_PIN = 23;
const int HEAVY_LOAD_RELAY_PIN = 19;
const int WAPDA_SENSE_PIN = 34;
const int STATUS_LED_PIN = 2;

// ============================================================
// WAPDA Detection Logic (H11AA1 Optocoupler)
// Active LOW = pin LOW when WAPDA present
// ============================================================
const bool WAPDA_PRESENCE_ACTIVE_LOW = true;

// ========================
// Dynamic Control Settings (Synced from backend)
// ========================
bool serverWapdaAutoMode = true;
bool serverWapdaRelayState = true;
bool serverHeavyLoadAutoMode = true;
bool serverHeavyLoadState = true;
String serverDayStart = "08:00";
String serverDayEnd = "18:00";

// ========================
// Hardware Instances
// ========================
WebServer server(80);
Preferences preferences;
RTC_DS3231 rtc;
bool rtcPresent = false;
bool apMode = false; // true when running as Access Point

// ========================
// Timing Variables
// ========================
unsigned long previousMillis = 0;
const long heartbeatInterval = 500;
bool ledState = false;

unsigned long previousOtaMillis = 0;
const long otaInterval = 60000;

unsigned long previousTelemetryMillis = 0;
const long telemetryInterval = 15000;

// ============================================================
//  NVS CONFIG HELPERS
// ============================================================

String nvsGetString(const char *key, const String &fallback = "") {
  preferences.begin("ota", true);
  String val = preferences.getString(key, fallback);
  preferences.end();
  return val;
}

void nvsSetString(const char *key, const String &value) {
  preferences.begin("ota", false);
  preferences.putString(key, value);
  preferences.end();
}

String getCurrentVersion() { return nvsGetString("version", "0.0.0"); }
void saveVersion(const String &v) {
  nvsSetString("version", v);
  Serial.println("[NVS] Saved version: " + v);
}
void saveDeviceUid(const String &uid) {
  nvsSetString("device_uid", uid);
  Serial.println("[NVS] Saved device_uid: " + uid);
}
void saveApiBaseUrl(const String &url) {
  nvsSetString("api_base_url", url);
  Serial.println("[NVS] Saved API base URL: " + url);
}

String getSavedSSID() { return nvsGetString("wifi_ssid", ""); }
String getSavedPass() { return nvsGetString("wifi_pass", ""); }
void saveWiFiCreds(const String &ssid, const String &pass) {
  nvsSetString("wifi_ssid", ssid);
  nvsSetString("wifi_pass", pass);
  Serial.println("[NVS] Saved WiFi: " + ssid);
}

String normalizeApiBaseUrl(String url) {
  url.trim();
  if (url.length() == 0)
    return url;
  while (url.endsWith("/")) {
    url.remove(url.length() - 1);
  }
  if (!url.startsWith("http://") && !url.startsWith("https://")) {
    url = "http://" + url;
  }
  return url;
}

// ============================================================
//  RTC HELPER FUNCTIONS
// ============================================================

void initRTC() {
  Serial.println("\n[RTC] Checking for DS3231 module...");
  Wire.begin(21, 22);
  Wire.setClock(100000);
  Wire.beginTransmission(0x68);
  byte error = Wire.endTransmission();
  if (error == 0) {
    Serial.println("[RTC] DS3231 detected!");
    if (rtc.begin()) {
      rtcPresent = true;
      Serial.println("[RTC] Initialized OK");
      if (rtc.lostPower()) {
        Serial.println("[RTC] Lost power, setting to compile time");
        rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
      }
      DateTime now = rtc.now();
      Serial.printf("[RTC] Time: %04d-%02d-%02d %02d:%02d:%02d\n", now.year(),
                    now.month(), now.day(), now.hour(), now.minute(),
                    now.second());
    } else {
      rtcPresent = false;
    }
  } else {
    Serial.println("[RTC] No DS3231 found");
    rtcPresent = false;
  }
}

String getFormattedTime() {
  if (!rtcPresent)
    return "RTC_NOT_AVAILABLE";
  DateTime now = rtc.now();
  char buf[25];
  sprintf(buf, "%04d-%02d-%02d %02d:%02d:%02d", now.year(), now.month(),
          now.day(), now.hour(), now.minute(), now.second());
  return String(buf);
}

void syncRTCWithNTP() {
  if (!rtcPresent || WiFi.status() != WL_CONNECTED)
    return;
  Serial.println("[RTC] Syncing with NTP...");
  configTime(18000, 0, "pool.ntp.org", "time.nist.gov"); // UTC+5 (Pakistan)
  struct tm timeinfo;
  if (getLocalTime(&timeinfo, 10000)) {
    rtc.adjust(DateTime(timeinfo.tm_year + 1900, timeinfo.tm_mon + 1,
                        timeinfo.tm_mday, timeinfo.tm_hour, timeinfo.tm_min,
                        timeinfo.tm_sec));
    Serial.println("[RTC] Synced: " + getFormattedTime());
  } else {
    Serial.println("[RTC] NTP sync failed");
  }
}

// ============================================================
//  OTA CHECK & FLASH
// ============================================================

void checkForOTAUpdate() {
  if (WiFi.status() != WL_CONNECTED)
    return;
  String timeStr = rtcPresent ? getFormattedTime() : "NO_RTC";
  Serial.println("\n------ OTA Check ------ [" + timeStr + "]");
  String currentVersion = getCurrentVersion();
  Serial.println("[OTA] Installed: " + currentVersion);

  HTTPClient http;
  String checkUrl =
      apiBaseUrl + "/api/firmware/ota/check?current_version=" + currentVersion;
  http.begin(checkUrl);
  int httpCode = http.GET();

  if (httpCode != 200) {
    Serial.println("[OTA] Server error. Skipping.");
    http.end();
    return;
  }

  String payload = http.getString();
  http.end();

  DynamicJsonDocument doc(1024);
  if (deserializeJson(doc, payload)) {
    Serial.println("[OTA] JSON parse error.");
    return;
  }

  bool updateAvailable = doc["update_available"] | false;
  String latestVersion = doc["latest_version"] | doc["version"] | String("");
  String firmwareUrl = doc["firmware_url"] | doc["url"] | String("");

  if (!updateAvailable) {
    Serial.println("[OTA] Up to date (" + currentVersion + ").");
    return;
  }
  if (latestVersion.isEmpty() || firmwareUrl.isEmpty()) {
    Serial.println("[OTA] Missing version/URL. Aborting.");
    return;
  }

  Serial.println("[OTA] New firmware: " + latestVersion);
  saveVersion(latestVersion);
  
  WiFiClientSecure client;
  client.setInsecure();
  httpUpdate.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);
  httpUpdate.rebootOnUpdate(true);
  
  t_httpUpdate_return ret = httpUpdate.update(client, firmwareUrl);

  switch (ret) {
  case HTTP_UPDATE_OK:
    break;
  case HTTP_UPDATE_FAILED:
    saveVersion(currentVersion);
    Serial.printf("[OTA] FAILED (%d): %s\n", httpUpdate.getLastError(),
                  httpUpdate.getLastErrorString().c_str());
    break;
  case HTTP_UPDATE_NO_UPDATES:
    saveVersion(currentVersion);
    Serial.println("[OTA] No updates (binary identical).");
    break;
  }
}

// ============================================================
//  RELAY SCHEDULER LOGIC
// ============================================================

bool parseTimeStr(const String &timeStr, int &hour, int &minute) {
  int c = timeStr.indexOf(':');
  if (c == -1)
    return false;
  hour = timeStr.substring(0, c).toInt();
  minute = timeStr.substring(c + 1).toInt();
  return true;
}

bool isTimeInDayRange(int cH, int cM, int sH, int sM, int eH, int eM) {
  int cur = cH * 60 + cM;
  int s = sH * 60 + sM;
  int e = eH * 60 + eM;
  return (s < e) ? (cur >= s && cur < e) : (cur >= s || cur < e);
}

void controlRelaysLogic(bool isDay, bool wapdaAvailable) {
  bool finalWapda = false;
  bool finalHeavyLoad = false;

  if (serverWapdaAutoMode) {
    if (isDay) {
      finalWapda = false;
    } else {
      finalWapda = wapdaAvailable;
    }
  } else {
    finalWapda = serverWapdaRelayState;
  }

  if (serverHeavyLoadAutoMode) {
    if (isDay) {
      finalHeavyLoad = true;
    } else {
      finalHeavyLoad = wapdaAvailable;
    }
  } else {
    finalHeavyLoad = serverHeavyLoadState;
  }

  digitalWrite(WAPDA_RELAY_PIN, finalWapda ? HIGH : LOW);
  digitalWrite(HEAVY_LOAD_RELAY_PIN, finalHeavyLoad ? HIGH : LOW);

  // Rate-limit prints to only output when there's an actual state change
  static bool lastDay = false;
  static bool lastWapdaAvailable = false;
  static bool lastFinalWapda = false;
  static bool lastFinalHeavyLoad = false;
  static bool lastWapdaAuto = true;
  static bool lastHeavyLoadAuto = true;

  if (isDay != lastDay || wapdaAvailable != lastWapdaAvailable ||
      finalWapda != lastFinalWapda || finalHeavyLoad != lastFinalHeavyLoad ||
      serverWapdaAutoMode != lastWapdaAuto ||
      serverHeavyLoadAutoMode != lastHeavyLoadAuto) {

    lastDay = isDay;
    lastWapdaAvailable = wapdaAvailable;
    lastFinalWapda = finalWapda;
    lastFinalHeavyLoad = finalHeavyLoad;
    lastWapdaAuto = serverWapdaAutoMode;
    lastHeavyLoadAuto = serverHeavyLoadAutoMode;

    Serial.printf("[Relays] Day=%d WAPDA_Sense=%d | Relay: WAPDA=%d(auto=%d) "
                  "HeavyLoad=%d(auto=%d)\n",
                  isDay, wapdaAvailable, finalWapda, serverWapdaAutoMode,
                  finalHeavyLoad, serverHeavyLoadAutoMode);
  }
}

void applyRelayControls() {
  bool pinRead = (digitalRead(WAPDA_SENSE_PIN) == LOW);
  bool wapdaAvailable = WAPDA_PRESENCE_ACTIVE_LOW ? pinRead : !pinRead;

  if (!rtcPresent) {
    controlRelaysLogic(true, wapdaAvailable);
    return;
  }

  DateTime now = rtc.now();
  int sH = 8, sM = 0, eH = 18, eM = 0;
  parseTimeStr(serverDayStart, sH, sM);
  parseTimeStr(serverDayEnd, eH, eM);
  bool isDay = isTimeInDayRange(now.hour(), now.minute(), sH, sM, eH, eM);
  controlRelaysLogic(isDay, wapdaAvailable);
}

void sendTelemetryAndGetControls() {
  if (WiFi.status() != WL_CONNECTED || apMode)
    return;

  bool pinRead = (digitalRead(WAPDA_SENSE_PIN) == LOW);
  bool wapdaAvailable = WAPDA_PRESENCE_ACTIVE_LOW ? pinRead : !pinRead;
  bool wapdaRelayState = (digitalRead(WAPDA_RELAY_PIN) == HIGH);
  bool heavyLoadState = (digitalRead(HEAVY_LOAD_RELAY_PIN) == HIGH);

  // Compute isDayTime from RTC + user-defined schedule (NOT LDR)
  bool isDayTime = true; // default if no RTC
  if (rtcPresent) {
    DateTime now = rtc.now();
    int sH = 8, sM = 0, eH = 18, eM = 0;
    parseTimeStr(serverDayStart, sH, sM);
    parseTimeStr(serverDayEnd, eH, eM);
    isDayTime = isTimeInDayRange(now.hour(), now.minute(), sH, sM, eH, eM);
  }

  DynamicJsonDocument doc(256);
  doc["wapdaAvailable"] = wapdaAvailable;
  doc["wapdaRelayState"] = wapdaRelayState;
  doc["heavyLoadState"] = heavyLoadState;
  doc["isDayTime"] = isDayTime;
  String jsonStr;
  serializeJson(doc, jsonStr);

  HTTPClient http;
  String url = apiBaseUrl + "/api/devices/" + deviceUid + "/data";

  Serial.print("\n[Telemetry] Sending to: ");
  Serial.println(url);

  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int httpCode = http.POST(jsonStr);

  if (httpCode == 200) {
    String response = http.getString();

    DynamicJsonDocument respDoc(512);
    DeserializationError error = deserializeJson(respDoc, response);
    if (!error) {
      serverWapdaAutoMode = respDoc.containsKey("wapdaAutoMode") ? respDoc["wapdaAutoMode"].as<bool>() : true;
      serverWapdaRelayState = respDoc.containsKey("wapdaRelayState") ? respDoc["wapdaRelayState"].as<bool>() : true;
      serverHeavyLoadAutoMode = respDoc.containsKey("heavyLoadAutoMode") ? respDoc["heavyLoadAutoMode"].as<bool>() : true;
      serverHeavyLoadState = respDoc.containsKey("heavyLoadState") ? respDoc["heavyLoadState"].as<bool>() : true;
      serverDayStart = respDoc["dayStart"] | String("08:00");
      serverDayEnd = respDoc["dayEnd"] | String("18:00");
      Serial.println("[Telemetry] Sync OK");
    } else {
      Serial.print("[Telemetry] JSON error: ");
      Serial.println(error.c_str());
    }
  } else {
    Serial.println("[Telemetry] Failed, HTTP: " + String(httpCode));
  }
  http.end();
}

// ============================================================
//  AP MODE — WiFi Provisioning Portal
// ============================================================

const char AP_HTML[] PROGMEM = R"rawliteral(
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:system-ui,sans-serif;background:#0f172a;color:#e2e8f0;
       display:flex;align-items:center;justify-content:center;min-height:100vh}
  .card{background:#1e293b;border-radius:20px;padding:32px;max-width:380px;width:90%;
        box-shadow:0 20px 60px rgba(0,0,0,.4)}
  h2{text-align:center;margin-bottom:6px;font-size:22px;color:#38bdf8}
  .sub{text-align:center;font-size:13px;color:#94a3b8;margin-bottom:24px}
  label{display:block;font-size:13px;font-weight:600;margin-bottom:6px;color:#94a3b8}
  input{width:100%;padding:12px 14px;border-radius:12px;border:1px solid #334155;
        background:#0f172a;color:#e2e8f0;font-size:15px;margin-bottom:16px;outline:none}
  input:focus{border-color:#38bdf8}
  button{width:100%;padding:14px;border:none;border-radius:12px;
         background:linear-gradient(135deg,#2563eb,#38bdf8);color:#fff;
         font-size:16px;font-weight:700;cursor:pointer;margin-top:8px}
  button:hover{opacity:.9}
  .info{font-size:11px;color:#64748b;text-align:center;margin-top:16px}
</style>
</head><body>
<div class="card">
  <h2>ESP32 Setup</h2>
  <p class="sub">Configure WiFi & Device Identity</p>
  <form action="/save-config" method="GET">
    <label>WiFi Name (SSID)</label>
    <input name="ssid" placeholder="Enter WiFi name" required>
    <label>WiFi Password</label>
    <input name="pass" type="password" placeholder="Enter WiFi password" required>
    <label>Device UID (from mobile app)</label>
    <input name="device_uid" placeholder="e.g. SKU-WHL-0001" value="%DEVICE_UID%">
    <button type="submit">Save & Connect</button>
  </form>
  <p class="info">After saving, the ESP32 will restart and connect to your WiFi.</p>
</div>
</body></html>
)rawliteral";

void startAPMode() {
  apMode = true;
  String apName = "SolarController-" + WiFi.macAddress().substring(9);
  apName.replace(":", "");

  WiFi.mode(WIFI_AP);
  WiFi.softAP(apName.c_str(), "solar1234");

  Serial.println("\n╔════════════════════════════════════╗");
  Serial.println("║   WiFi PROVISIONING MODE (AP)     ║");
  Serial.println("╠════════════════════════════════════╣");
  Serial.println("║ Connect to: " + apName);
  Serial.println("║ Password:   solar1234");
  Serial.println("║ Open:       http://192.168.4.1");
  Serial.println("╚════════════════════════════════════╝\n");

  server.on("/", HTTP_GET, []() {
    String html = String(AP_HTML);
    String safeUid = deviceUid;
    safeUid.replace("&", "&amp;");
    safeUid.replace("<", "&lt;");
    safeUid.replace(">", "&gt;");
    safeUid.replace("\"", "&quot;");
    safeUid.replace("'", "&#39;");
    html.replace("%DEVICE_UID%", safeUid);
    server.send(200, "text/html", html);
  });

  server.on("/save-config", HTTP_GET, []() {
    String ssid = server.arg("ssid");
    String pass = server.arg("pass");
    String uid = server.arg("device_uid");

    if (ssid.length() == 0) {
      server.send(400, "text/plain", "SSID is required");
      return;
    }

    saveWiFiCreds(ssid, pass);
    if (uid.length() > 0) {
      saveDeviceUid(uid);
    }

    server.send(
        200, "text/html",
        "<html><body "
        "style='background:#0f172a;color:#38bdf8;display:flex;align-items:"
        "center;"
        "justify-content:center;min-height:100vh;font-family:system-ui'>"
        "<div style='text-align:center'><h2>Saved!</h2>"
        "<p>Restarting and connecting to " +
            ssid + "...</p></div></body></html>");
    delay(2000);
    ESP.restart();
  });

  server.begin();
  Serial.println("[AP] WebServer started on http://192.168.4.1");
}

// ============================================================
//  WIFI CONNECTION
// ============================================================

bool connectToWiFi() {
  String savedSSID = getSavedSSID();
  String savedPass = getSavedPass();

  if (savedSSID.length() == 0) {
    Serial.println("[WiFi] No saved WiFi credentials");
    return false;
  }

  Serial.print("[WiFi] Connecting to " + savedSSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(savedSSID.c_str(), savedPass.c_str());

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 40) {
    delay(500);
    Serial.print(".");
    retry++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("[WiFi] Connected! IP: " + WiFi.localIP().toString());
    return true;
  }

  Serial.println("[WiFi] Connection failed to " + savedSSID);
  return false;
}

// ============================================================
//  SETUP
// ============================================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n╔════════════════════════════════════╗");
  Serial.println("║   ESP32 Solar Controller Relays   ║");
  Serial.println("║    with WiFi AP Provisioning       ║");
  Serial.println("╚════════════════════════════════════╝\n");

  pinMode(WAPDA_RELAY_PIN, OUTPUT);
  pinMode(HEAVY_LOAD_RELAY_PIN, OUTPUT);
  pinMode(WAPDA_SENSE_PIN, INPUT_PULLUP);
  pinMode(STATUS_LED_PIN, OUTPUT);

  digitalWrite(WAPDA_RELAY_PIN, LOW);
  digitalWrite(HEAVY_LOAD_RELAY_PIN, LOW);
  digitalWrite(STATUS_LED_PIN, LOW);

  // Load device UID from NVS or generate from MAC
  deviceUid = nvsGetString("device_uid", "");
  if (deviceUid.length() == 0) {
    String mac = WiFi.macAddress();
    mac.replace(":", "");
    deviceUid = "ESP32-" + mac;
    Serial.println("[System] Default UID from MAC: " + deviceUid);
  } else {
    Serial.println("[System] Loaded device_uid: " + deviceUid);
  }

  apiBaseUrl = defaultApiBaseUrl;
  Serial.println("[System] API base URL: " + apiBaseUrl);

  initRTC();

  String ver = getCurrentVersion();
  Serial.println("[System] Firmware version: " + ver);

  // Try connecting to saved WiFi
  bool wifiOk = connectToWiFi();

  if (!wifiOk) {
    // No WiFi configured or connection failed — start AP mode for provisioning
    startAPMode();
    return; // AP mode runs in loop() via server.handleClient()
  }

  // WiFi connected — sync RTC and set up normal operation
  if (rtcPresent) {
    syncRTCWithNTP();
  }

  // Normal STA-mode WebServer endpoints
  server.on("/update-check", HTTP_GET, []() {
    server.send(200, "text/plain", "OTA check triggered");
    checkForOTAUpdate();
  });

  server.on("/version", HTTP_GET, []() {
    String v = getCurrentVersion();
    String json = "{\"version\":\"" + v + "\",\"ip\":\"" +
                  WiFi.localIP().toString() + "\",\"device_uid\":\"" +
                  deviceUid + "\"}";
    server.send(200, "application/json", json);
  });

  server.on("/configure", HTTP_GET, []() {
    bool changed = false;
    if (server.hasArg("device_uid")) {
      String newUid = server.arg("device_uid");
      newUid.trim();
      if (newUid.length() > 0) {
        saveDeviceUid(newUid);
        deviceUid = newUid;
        changed = true;
      }
    }
    if (!changed) {
      server.send(400, "application/json",
                  "{\"error\":\"Missing device_uid\"}");
      return;
    }
    String json = "{\"status\":\"success\",\"device_uid\":\"" + deviceUid + "\"}";
    server.send(200, "application/json", json);
  });

  server.on("/reset-wifi", HTTP_GET, []() {
    saveWiFiCreds("", "");
    server.send(200, "text/plain",
                "WiFi credentials cleared. Restarting to AP mode...");
    delay(1000);
    ESP.restart();
  });

  server.on("/time", HTTP_GET, []() {
    if (rtcPresent) {
      String t = getFormattedTime();
      float temp = rtc.getTemperature();
      String json = "{\"time\":\"" + t + "\",\"temperature\":" + String(temp) +
                    ",\"rtc_present\":true}";
      server.send(200, "application/json", json);
    } else {
      server.send(200, "application/json",
                  "{\"error\":\"RTC not found\",\"rtc_present\":false}");
    }
  });

  server.on("/sync-time", HTTP_GET, []() {
    if (!rtcPresent) {
      server.send(400, "application/json", "{\"error\":\"RTC not available\"}");
      return;
    }
    if (WiFi.status() == WL_CONNECTED) {
      syncRTCWithNTP();
      server.send(200, "application/json",
                  "{\"status\":\"success\",\"time\":\"" + getFormattedTime() +
                      "\"}");
    } else {
      server.send(503, "application/json",
                  "{\"error\":\"WiFi not connected\"}");
    }
  });

  server.begin();
  Serial.println("[HTTP] WebServer started on port 80");

  sendTelemetryAndGetControls();
  checkForOTAUpdate();
}

// ============================================================
//  LOOP
// ============================================================

void loop() {
  server.handleClient();
  unsigned long now = millis();

  // Heartbeat LED — fast blink in AP mode, slow in STA mode
  long blink = apMode ? 200 : heartbeatInterval;
  if (now - previousMillis >= (unsigned long)blink) {
    previousMillis = now;
    ledState = !ledState;
    digitalWrite(STATUS_LED_PIN, ledState ? HIGH : LOW);
  }

  // Skip all normal operations if in AP provisioning mode
  if (apMode)
    return;

  // Apply Relay Controls every 1 second (1000ms) to prevent I2C/RTC bus
  // overload
  static unsigned long previousRelayMillis = 0;
  if (now - previousRelayMillis >= 1000) {
    previousRelayMillis = now;
    applyRelayControls();
  }

  // Send telemetry every 15s
  if (now - previousTelemetryMillis >= telemetryInterval) {
    previousTelemetryMillis = now;
    sendTelemetryAndGetControls();
  }

  // OTA check every 60s
  if (now - previousOtaMillis >= otaInterval) {
    previousOtaMillis = now;
    checkForOTAUpdate();
  }
}
