import { useEffect, useState } from 'react';
import { api } from '../services/api';
import { Cpu, Upload, Trash2, CheckCircle, Wifi, Zap, Sun, Wind, ChevronRight } from 'lucide-react';

/* ─── Product Family Definitions ─────────────────────────── */
const FAMILIES = [
  {
    key: 'WHL',
    label: 'WHL — Wapda Heavy Load',
    skuPrefix: 'SKU-WHL',
    description: 'Firmware for all SKU-WHL-0001 through SKU-WHL-9999+ variants',
    icon: Zap,
    gradient: 'linear-gradient(135deg, #ff6b2b 0%, #ff2d55 100%)',
    glowColor: 'rgba(255, 107, 43, 0.4)',
    accentColor: '#ff6b2b',
    bgAccent: 'rgba(255, 107, 43, 0.06)',
    borderAccent: 'rgba(255, 107, 43, 0.18)',
  },
  {
    key: 'MSS',
    label: 'MSS — Medium Solar System',
    skuPrefix: 'SKU-MSS',
    description: 'Firmware for all SKU-MSS-0001 through SKU-MSS-9999+ variants',
    icon: Sun,
    gradient: 'linear-gradient(135deg, #f5a623 0%, #f7dc6f 100%)',
    glowColor: 'rgba(245, 166, 35, 0.4)',
    accentColor: '#f5a623',
    bgAccent: 'rgba(245, 166, 35, 0.06)',
    borderAccent: 'rgba(245, 166, 35, 0.18)',
  },
  {
    key: 'FSS',
    label: 'FSS — Full Solar System',
    skuPrefix: 'SKU-FSS',
    description: 'Firmware for all SKU-FSS-0001 through SKU-FSS-9999+ variants',
    icon: Wind,
    gradient: 'linear-gradient(135deg, #00c6ff 0%, #0072ff 100%)',
    glowColor: 'rgba(0, 198, 255, 0.4)',
    accentColor: '#00c6ff',
    bgAccent: 'rgba(0, 198, 255, 0.06)',
    borderAccent: 'rgba(0, 198, 255, 0.18)',
  },
];

/* ─── Individual Family Section Component ──────────────── */
const FamilySection = ({ family, firmwares, onRefresh }) => {
  const [version, setVersion] = useState('');
  const [description, setDescription] = useState('');
  const [file, setFile] = useState(null);
  const [uploadError, setUploadError] = useState('');
  const [uploadSuccess, setUploadSuccess] = useState('');
  const [uploading, setUploading] = useState(false);
  const [expanded, setExpanded] = useState(false);

  const Icon = family.icon;
  const familyFirmwares = firmwares.filter(
    f => (f.product_family || '').toUpperCase() === family.key
  );
  const activeFirmware = familyFirmwares.find(
    f => Number(f.is_active) === 1 || f.is_active === true
  );

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile) {
      if (selectedFile.name.endsWith('.bin')) {
        setFile(selectedFile);
        setUploadError('');
        const match = selectedFile.name.match(/v?\d+\.\d+\.\d+/);
        if (match && !version) {
          setVersion(match[0].startsWith('v') ? match[0] : 'v' + match[0]);
        }
      } else {
        setFile(null);
        setUploadError('Only .bin firmware files are supported!');
      }
    }
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file || !version) {
      setUploadError('Please select a .bin file and specify the version.');
      return;
    }

    setUploadError('');
    setUploadSuccess('');
    setUploading(true);

    const formData = new FormData();
    formData.append('firmware', file);
    formData.append('version', version);
    formData.append('description', description);
    formData.append('product_family', family.key);

    try {
      await api.uploadFirmware(formData);
      setUploadSuccess(`Firmware ${version} uploaded for ${family.label}!`);
      setVersion('');
      setDescription('');
      setFile(null);

      const fileInput = document.getElementById(`firmware-file-${family.key}`);
      if (fileInput) fileInput.value = '';

      await onRefresh();
    } catch (err) {
      setUploadError(err.message || 'Upload failed');
    } finally {
      setUploading(false);
    }
  };

  const handleActivate = async (id) => {
    try {
      await api.patch(`/api/firmware/${id}/activate`, {});
      await onRefresh();
    } catch (err) {
      console.error('Failed to activate:', err);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this firmware version? Devices will no longer be able to download this release.')) return;
    try {
      await api.delete(`/api/firmware/${id}`);
      await onRefresh();
    } catch (err) {
      console.error('Failed to delete:', err);
    }
  };

  return (
    <div
      className="glass-panel"
      style={{
        padding: 0,
        overflow: 'hidden',
        border: `1px solid ${family.borderAccent}`,
        background: family.bgAccent,
        transition: 'all 0.3s ease',
      }}
    >
      {/* ── Family Header ── */}
      <div
        onClick={() => setExpanded(!expanded)}
        style={{
          padding: '20px 24px',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          gap: '16px',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Glow background */}
        <div style={{
          position: 'absolute',
          top: '-50%',
          right: '-10%',
          width: '200px',
          height: '200px',
          borderRadius: '50%',
          background: family.glowColor,
          filter: 'blur(80px)',
          opacity: 0.3,
          pointerEvents: 'none',
        }} />

        {/* Icon */}
        <div style={{
          width: '52px',
          height: '52px',
          borderRadius: '14px',
          background: family.gradient,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0,
          boxShadow: `0 4px 20px ${family.glowColor}`,
        }}>
          <Icon size={26} color="#fff" />
        </div>

        {/* Title & Status */}
        <div style={{ flex: 1, zIndex: 1 }}>
          <h2 style={{
            fontSize: '18px',
            fontWeight: 800,
            color: '#fff',
            margin: 0,
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
          }}>
            {family.label}
            {activeFirmware && (
              <span style={{
                fontSize: '10px',
                fontWeight: 700,
                padding: '3px 10px',
                background: 'rgba(0, 255, 160, 0.12)',
                color: '#00ffa0',
                border: '1px solid rgba(0, 255, 160, 0.25)',
                borderRadius: '20px',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
              }}>
                <span style={{
                  width: '6px',
                  height: '6px',
                  background: '#00ffa0',
                  borderRadius: '50%',
                  boxShadow: '0 0 6px #00ffa0',
                  display: 'inline-block',
                }} />
                {activeFirmware.version} LIVE
              </span>
            )}
          </h2>
          <p style={{
            fontSize: '12px',
            color: 'var(--text-secondary)',
            margin: '4px 0 0',
            fontWeight: 500,
          }}>
            {family.description} · {familyFirmwares.length} version{familyFirmwares.length !== 1 ? 's' : ''} uploaded
          </p>
        </div>

        {/* Expand chevron */}
        <ChevronRight
          size={20}
          color="var(--text-muted)"
          style={{
            transition: 'transform 0.3s ease',
            transform: expanded ? 'rotate(90deg)' : 'rotate(0deg)',
            zIndex: 1,
          }}
        />
      </div>

      {/* ── Expanded Content ── */}
      {expanded && (
        <div style={{
          padding: '0 24px 24px',
          animation: 'fadeInDown 0.3s ease',
        }}>
          {/* Active Status Strip */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            padding: '14px 18px',
            borderRadius: '12px',
            background: activeFirmware
              ? 'rgba(0, 255, 160, 0.04)'
              : 'rgba(255, 255, 255, 0.02)',
            border: activeFirmware
              ? '1px solid rgba(0, 255, 160, 0.15)'
              : '1px solid rgba(255, 255, 255, 0.06)',
            marginBottom: '20px',
          }}>
            <Wifi
              size={20}
              color={activeFirmware ? '#00ffa0' : 'var(--text-muted)'}
              style={activeFirmware ? { filter: 'drop-shadow(0 0 6px #00ffa080)' } : {}}
            />
            <div style={{ flex: 1 }}>
              <span style={{ fontSize: '11px', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.8px' }}>
                Active OTA Release
              </span>
              <div style={{ fontSize: '16px', fontWeight: 800, color: '#fff', marginTop: '2px' }}>
                {activeFirmware ? activeFirmware.version : 'No active release'}
              </div>
            </div>
            {activeFirmware && (
              <span style={{
                fontSize: '11px',
                color: '#00ffa0',
                fontWeight: 600,
                padding: '4px 12px',
                background: 'rgba(0, 255, 160, 0.1)',
                borderRadius: '20px',
              }}>
                All {family.skuPrefix}-XXXX devices will receive this update
              </span>
            )}
          </div>

          {/* Upload + History Grid */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1.6fr',
            gap: '20px',
            alignItems: 'start',
          }}>
            {/* Upload Form */}
            <div style={{
              background: 'rgba(255, 255, 255, 0.02)',
              borderRadius: '14px',
              border: '1px solid rgba(255, 255, 255, 0.06)',
              padding: '20px',
            }}>
              <h3 style={{
                fontSize: '15px',
                fontWeight: 700,
                marginBottom: '16px',
                color: '#fff',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
              }}>
                <Upload size={16} color={family.accentColor} />
                Upload Firmware
              </h3>

              {uploadError && (
                <div style={{
                  background: 'rgba(239, 68, 68, 0.12)',
                  border: '1px solid rgba(239, 68, 68, 0.25)',
                  borderRadius: '8px',
                  color: '#ef4444',
                  padding: '10px',
                  fontSize: '12px',
                  marginBottom: '12px',
                  fontWeight: 500,
                }}>
                  {uploadError}
                </div>
              )}

              {uploadSuccess && (
                <div style={{
                  background: 'rgba(16, 185, 129, 0.12)',
                  border: '1px solid rgba(16, 185, 129, 0.25)',
                  borderRadius: '8px',
                  color: '#10b981',
                  padding: '10px',
                  fontSize: '12px',
                  marginBottom: '12px',
                  fontWeight: 500,
                }}>
                  {uploadSuccess}
                </div>
              )}

              <form onSubmit={handleUpload}>
                <div className="form-group" style={{ marginBottom: '12px' }}>
                  <label style={{ fontSize: '12px', fontWeight: 600 }}>Version</label>
                  <input
                    type="text"
                    placeholder="e.g. v1.2.0"
                    className="glass-input"
                    value={version}
                    onChange={(e) => setVersion(e.target.value)}
                    disabled={uploading}
                    style={{ fontSize: '13px' }}
                  />
                </div>

                <div className="form-group" style={{ marginBottom: '12px' }}>
                  <label style={{ fontSize: '12px', fontWeight: 600 }}>Firmware Binary (.bin)</label>
                  <div
                    style={{
                      border: `2px dashed ${file ? family.accentColor : 'var(--glass-border)'}`,
                      borderRadius: '10px',
                      padding: '18px 12px',
                      textAlign: 'center',
                      cursor: 'pointer',
                      background: file ? family.bgAccent : 'transparent',
                      transition: 'all 0.2s ease',
                    }}
                    onClick={() => document.getElementById(`firmware-file-${family.key}`).click()}
                  >
                    <Cpu size={20} style={{ color: file ? family.accentColor : 'var(--text-muted)', marginBottom: '6px' }} />
                    <div style={{ fontSize: '12px', fontWeight: 600, color: '#fff' }}>
                      {file ? file.name : 'Select firmware.bin'}
                    </div>
                    <div style={{ fontSize: '10px', color: 'var(--text-secondary)', marginTop: '3px' }}>
                      {file ? `${(file.size / (1024 * 1024)).toFixed(2)} MB` : 'Compiled .bin file'}
                    </div>
                    <input
                      id={`firmware-file-${family.key}`}
                      type="file"
                      accept=".bin"
                      style={{ display: 'none' }}
                      onChange={handleFileChange}
                      disabled={uploading}
                    />
                  </div>
                </div>

                <div className="form-group" style={{ marginBottom: '14px' }}>
                  <label style={{ fontSize: '12px', fontWeight: 600 }}>Release Notes</label>
                  <textarea
                    placeholder="What changed in this version..."
                    className="glass-input"
                    style={{ height: '60px', resize: 'none', fontSize: '12px' }}
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    disabled={uploading}
                  />
                </div>

                <button
                  type="submit"
                  className="glass-btn primary"
                  style={{
                    width: '100%',
                    justifyContent: 'center',
                    background: family.gradient,
                    border: 'none',
                    fontWeight: 700,
                  }}
                  disabled={uploading}
                >
                  {uploading ? 'Uploading...' : `Upload to ${family.key}`}
                </button>
              </form>
            </div>

            {/* Version History */}
            <div style={{
              background: 'rgba(255, 255, 255, 0.02)',
              borderRadius: '14px',
              border: '1px solid rgba(255, 255, 255, 0.06)',
              padding: '20px',
            }}>
              <h3 style={{
                fontSize: '15px',
                fontWeight: 700,
                marginBottom: '16px',
                color: '#fff',
              }}>
                Version History
              </h3>

              {familyFirmwares.length === 0 ? (
                <div style={{
                  textAlign: 'center',
                  color: 'var(--text-muted)',
                  padding: '40px 20px',
                  fontSize: '13px',
                }}>
                  <Cpu size={28} style={{ opacity: 0.3, marginBottom: '8px' }} />
                  <div>No firmware uploaded for {family.label} yet</div>
                </div>
              ) : (
                <div className="table-container">
                  <table className="custom-table">
                    <thead>
                      <tr>
                        <th>Version</th>
                        <th>Size</th>
                        <th>Uploaded</th>
                        <th style={{ textAlign: 'right' }}>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {familyFirmwares.map((firm) => (
                        <tr key={firm.id}>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                              <span style={{ fontWeight: 700, color: '#fff', fontSize: '14px' }}>
                                {firm.version}
                              </span>
                              {(Number(firm.is_active) === 1 || firm.is_active === true) && (
                                <span className="badge success" style={{ padding: '2px 6px', fontSize: '9px' }}>
                                  ACTIVE
                                </span>
                              )}
                            </div>
                            <div style={{
                              fontSize: '11px',
                              color: 'var(--text-secondary)',
                              marginTop: '3px',
                              maxWidth: '200px',
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap',
                            }}>
                              {firm.description || 'No release notes'}
                            </div>
                          </td>
                          <td style={{ fontSize: '12px' }}>
                            {(firm.file_size / (1024 * 1024)).toFixed(2)} MB
                          </td>
                          <td>
                            <div style={{ fontSize: '12px', color: '#fff' }}>
                              {firm.uploader_name || 'Admin'}
                            </div>
                            <div style={{ fontSize: '10px', color: 'var(--text-secondary)', marginTop: '2px' }}>
                              {new Date(firm.uploaded_at).toLocaleDateString(undefined, {
                                month: 'short',
                                day: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit',
                              })}
                            </div>
                          </td>
                          <td style={{ textAlign: 'right' }}>
                            <div style={{ display: 'flex', gap: '5px', justifyContent: 'flex-end' }}>
                              {Number(firm.is_active) !== 1 && firm.is_active !== true ? (
                                <button
                                  className="glass-btn primary"
                                  style={{ padding: '4px 10px', fontSize: '10px' }}
                                  onClick={() => handleActivate(firm.id)}
                                >
                                  Activate
                                </button>
                              ) : (
                                <span style={{
                                  fontSize: '10px',
                                  color: '#00ffa0',
                                  fontStyle: 'italic',
                                  padding: '0 6px',
                                  display: 'flex',
                                  alignItems: 'center',
                                  gap: '3px',
                                }}>
                                  <CheckCircle size={10} /> Live
                                </span>
                              )}
                              <button
                                className="glass-btn danger"
                                style={{ padding: '4px 8px', display: 'flex', alignItems: 'center' }}
                                onClick={() => handleDelete(firm.id)}
                              >
                                <Trash2 size={11} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

/* ─── Main Firmware Page ───────────────────────────────── */
const Firmware = () => {
  const [firmwares, setFirmwares] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchFirmware();
  }, []);

  async function fetchFirmware() {
    try {
      setLoading(true);
      const data = await api.get('/api/firmware/list');
      setFirmwares(Array.isArray(data) ? data : []);
    } catch (err) {
      console.error('Failed to load firmware:', err);
    } finally {
      setLoading(false);
    }
  }

  const totalVersions = firmwares.length;
  const activeCount = firmwares.filter(f => Number(f.is_active) === 1 || f.is_active === true).length;

  return (
    <div className="slide-in">
      {/* ── Hero Header ── */}
      <header style={{ marginBottom: '28px' }}>
        <h1 style={{
          fontSize: '28px',
          fontWeight: 800,
          color: '#fff',
          marginBottom: '6px',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
        }}>
          <div style={{
            width: '42px',
            height: '42px',
            borderRadius: '12px',
            background: 'linear-gradient(135deg, hsl(var(--primary)) 0%, #ff5500 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 4px 16px rgba(255, 125, 0, 0.3)',
          }}>
            <Cpu size={22} color="#fff" />
          </div>
          Firmware OTA Center
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '14px', maxWidth: '700px' }}>
          Deploy over-the-air firmware updates to your devices. Each product line (WHL, MSS, FSS) 
          has its own firmware channel — updating one family only affects matching device variants.
        </p>
      </header>

      {/* ── Overview Stats ── */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: '16px',
        marginBottom: '28px',
      }}>
        {FAMILIES.map(fam => {
          const famFirm = firmwares.filter(f => (f.product_family || '').toUpperCase() === fam.key);
          const activeVer = famFirm.find(f => Number(f.is_active) === 1 || f.is_active === true);
          return (
            <div
              key={fam.key}
              className="glass-panel"
              style={{
                padding: '20px',
                position: 'relative',
                overflow: 'hidden',
                border: `1px solid ${fam.borderAccent}`,
              }}
            >
              {/* Glow */}
              <div style={{
                position: 'absolute',
                top: '-30px',
                right: '-30px',
                width: '120px',
                height: '120px',
                borderRadius: '50%',
                background: fam.glowColor,
                filter: 'blur(50px)',
                opacity: 0.15,
                pointerEvents: 'none',
              }} />

              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '14px', position: 'relative' }}>
                <div style={{
                  width: '38px',
                  height: '38px',
                  borderRadius: '10px',
                  background: fam.gradient,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  boxShadow: `0 2px 12px ${fam.glowColor}`,
                }}>
                  <fam.icon size={20} color="#fff" />
                </div>
                <div>
                  <div style={{ fontSize: '14px', fontWeight: 700, color: '#fff' }}>{fam.key}</div>
                  <div style={{ fontSize: '10px', color: 'var(--text-secondary)', fontWeight: 500 }}>
                    {famFirm.length} version{famFirm.length !== 1 ? 's' : ''}
                  </div>
                </div>
              </div>

              <div style={{ position: 'relative' }}>
                <div style={{ fontSize: '10px', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.8px', marginBottom: '4px' }}>
                  Active Release
                </div>
                <div style={{
                  fontSize: '20px',
                  fontWeight: 800,
                  color: activeVer ? '#fff' : 'var(--text-muted)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                }}>
                  {activeVer ? activeVer.version : '—'}
                  {activeVer && (
                    <span style={{
                      width: '8px',
                      height: '8px',
                      background: '#00ffa0',
                      borderRadius: '50%',
                      boxShadow: '0 0 8px #00ffa0',
                      display: 'inline-block',
                    }} />
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* ── Product Family Sections ── */}
      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: '60px', flexDirection: 'column', alignItems: 'center', gap: '14px' }}>
          <div style={{
            width: '36px',
            height: '36px',
            border: '3px solid rgba(255, 125, 0, 0.1)',
            borderTopColor: 'hsl(var(--primary))',
            borderRadius: '50%',
            animation: 'spin-slow 1s linear infinite',
          }} />
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px', fontWeight: 500 }}>
            Loading firmware data...
          </p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {FAMILIES.map(fam => (
            <FamilySection
              key={fam.key}
              family={fam}
              firmwares={firmwares}
              onRefresh={fetchFirmware}
            />
          ))}
        </div>
      )}

      {/* ── Bottom Info Note ── */}
      <div style={{
        marginTop: '24px',
        padding: '16px 20px',
        borderRadius: '12px',
        background: 'rgba(255, 255, 255, 0.02)',
        border: '1px solid rgba(255, 255, 255, 0.06)',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
      }}>
        <Wifi size={18} color="hsl(var(--primary))" />
        <div>
          <span style={{ fontSize: '13px', fontWeight: 600, color: '#fff' }}>
            How OTA works:
          </span>
          <span style={{ fontSize: '12px', color: 'var(--text-secondary)', marginLeft: '8px' }}>
            Devices automatically check for new firmware. When you activate a version under a product family, 
            all matching devices (e.g. all SKU-WHL variants) will receive the update on their next check-in.
          </span>
        </div>
      </div>
    </div>
  );
};

export default Firmware;
