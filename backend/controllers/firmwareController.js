const { get, run, query } = require('../database');
const path = require('path');
const fs = require('fs');

const uploadsDir = path.resolve(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

// ── Semantic version comparison ──────────────────────────────
// Returns true if serverVer is strictly newer than deviceVer
// e.g. compareVersions('1.0.1', '1.0.2') → true
function compareVersions(deviceVer, serverVer) {
  const normalize = v => v.trim().replace(/^v/i, '').split('.').map(Number);
  const d = normalize(deviceVer);
  const s = normalize(serverVer);
  const len = Math.max(d.length, s.length);
  for (let i = 0; i < len; i++) {
    const dPart = d[i] || 0;
    const sPart = s[i] || 0;
    if (sPart > dPart) return true;   // server is newer
    if (sPart < dPart) return false;  // device is somehow ahead
  }
  return false; // same version
}

/**
 * Extract the product family from a device SKU string.
 * e.g. "SKU-WHL-0042" → "WHL", "SKU-MSS-0001" → "MSS"
 * Falls back to "WHL" if the format doesn't match.
 */
function extractFamily(sku) {
  if (!sku) return 'WHL';
  const match = sku.toUpperCase().match(/SKU-(\w+)-/);
  return match ? match[1] : 'WHL';
}

// ============================================================
// FIRMWARE MANAGEMENT (OTA for product families)
// ============================================================

async function listFirmware(req, res) {
  try {
    const list = await query(
      `SELECT f.*, e.name AS uploader_name
       FROM firmware f
       LEFT JOIN crm_employees e ON f.uploaded_by = e.id
       ORDER BY f.uploaded_at DESC`
    );
    res.json(list.rows || list);
  } catch (err) {
    console.error('[Firmware] List error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not fetch firmware list' });
  }
}

async function uploadFirmware(req, res) {
  if (!req.file) {
    return res.status(400).json({ error: 'no_file', message: 'Please upload a .bin firmware file' });
  }

  const { version, description, product_family } = req.body;
  const family = (product_family || 'WHL').toUpperCase();

  if (!version) {
    fs.unlinkSync(req.file.path);
    return res.status(400).json({ error: 'bad_request', message: 'Firmware version string is required' });
  }

  // Validate family
  const validFamilies = ['WHL', 'MSS', 'FSS'];
  if (!validFamilies.includes(family)) {
    fs.unlinkSync(req.file.path);
    return res.status(400).json({ error: 'bad_request', message: `Invalid product family: ${family}. Must be WHL, MSS, or FSS.` });
  }

  try {
    // Check version uniqueness within the same product family
    const existing = await get(
      'SELECT id FROM firmware WHERE version = $1 AND product_family = $2',
      [version, family]
    );
    if (existing) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: 'version_exists', message: `Version ${version} already exists for ${family}` });
    }

    const relativePath = 'uploads/' + req.file.filename;
    const newFirmware = await run(
      `INSERT INTO firmware (version, file_path, file_size, description, product_family, is_active, uploaded_by)
       VALUES ($1, $2, $3, $4, $5, FALSE, $6)
       RETURNING *`,
      [version, relativePath, req.file.size, description || '', family, req.employee.id]
    );

    res.status(201).json({ message: 'Firmware uploaded successfully', firmware: newFirmware });
  } catch (err) {
    console.error('[Firmware] Upload error:', err);
    if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
    res.status(500).json({ error: 'server_error', message: 'Failed to store firmware record' });
  }
}

async function activateFirmware(req, res) {
  const firmId = req.params.id;
  try {
    const firm = await get('SELECT * FROM firmware WHERE id = $1', [firmId]);
    if (!firm) return res.status(404).json({ error: 'not_found', message: 'Firmware not found' });

    const family = firm.product_family || 'WHL';

    // Only deactivate firmware within the same product family
    await query('UPDATE firmware SET is_active = FALSE WHERE product_family = $1', [family]);
    await query('UPDATE firmware SET is_active = TRUE WHERE id = $1', [firmId]);

    res.json({
      message: `${firm.version} is now the active OTA release for ${family}`,
      version: firm.version,
      product_family: family
    });
  } catch (err) {
    console.error('[Firmware] Activate error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not activate firmware' });
  }
}

async function deleteFirmware(req, res) {
  const firmId = req.params.id;
  try {
    const firm = await get('SELECT * FROM firmware WHERE id = $1', [firmId]);
    if (!firm) return res.status(404).json({ error: 'not_found', message: 'Firmware not found' });

    const absolutePath = path.resolve(__dirname, '..', firm.file_path);
    if (fs.existsSync(absolutePath)) fs.unlinkSync(absolutePath);

    await query('DELETE FROM firmware WHERE id = $1', [firmId]);
    res.json({ message: `Firmware ${firm.version} deleted` });
  } catch (err) {
    console.error('[Firmware] Delete error:', err);
    res.status(500).json({ error: 'server_error', message: 'Could not delete firmware' });
  }
}

// ============================================================
// ESP32 OTA ENDPOINTS (Public — no auth needed for hardware)
// ============================================================

async function otaCheck(req, res) {
  const { current_version, device_sku } = req.query;
  if (!current_version) {
    return res.status(400).json({ error: 'bad_request', message: 'current_version query param is required' });
  }

  // Determine the product family from the device SKU
  const family = extractFamily(device_sku);

  try {
    const active = await get(
      'SELECT * FROM firmware WHERE is_active = TRUE AND product_family = $1 LIMIT 1',
      [family]
    );

    console.log(`[OTA] Check — device SKU: "${device_sku || 'unknown'}" (family: ${family}) | reports: "${current_version}" | server active: "${active ? active.version : 'NONE'}"`); 

    if (!active) {
      console.log(`[OTA] No active firmware configured for family ${family}.`);
      return res.json({ update_available: false, message: `No active firmware release for ${family}` });
    }

    const updateNeeded = compareVersions(current_version, active.version);
    console.log(`[OTA] Update needed? ${updateNeeded}`);

    if (updateNeeded) {
      const proto = req.protocol;
      const host  = req.get('host');
      const downloadUrl = `${proto}://${host}/api/firmware/ota/download?family=${family}`;
      console.log(`[OTA] Serving update → ${downloadUrl}`);
      return res.json({
        update_available: true,
        latest_version: active.version,
        firmware_url: downloadUrl,
        version: active.version,
        product_family: family,
        file_size: active.file_size,
        description: active.description || '',
        url: downloadUrl
      });
    }

    console.log(`[OTA] Device (${family}) is already on the latest version.`);
    res.json({ update_available: false, message: 'Device is already on the latest firmware' });
  } catch (err) {
    console.error('[OTA] Check error:', err);
    res.status(500).json({ error: 'server_error', message: 'OTA check failed' });
  }
}

async function otaDownload(req, res) {
  try {
    const family = (req.query.family || 'WHL').toUpperCase();
    const active = await get(
      'SELECT * FROM firmware WHERE is_active = TRUE AND product_family = $1 LIMIT 1',
      [family]
    );
    if (!active) return res.status(404).send(`No active firmware binary configured for ${family}`);

    const absolutePath = path.resolve(__dirname, '..', active.file_path);
    if (!fs.existsSync(absolutePath)) return res.status(404).send('Firmware binary missing on disk');

    const stat = fs.statSync(absolutePath);
    res.writeHead(200, {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename=firmware_${family}_${active.version}.bin`,
      'Content-Length': stat.size
    });
    fs.createReadStream(absolutePath).pipe(res);
  } catch (err) {
    console.error('[OTA] Download error:', err);
    res.status(500).send('OTA download failed');
  }
}

module.exports = { listFirmware, uploadFirmware, activateFirmware, deleteFirmware, otaCheck, otaDownload };
