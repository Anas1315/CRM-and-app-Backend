import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { ShieldAlert, Award, CreditCard, Lock, Sparkles, LogOut, Check } from 'lucide-react';

const Deactivated = () => {
  const { user, logout, processPremiumReactivation } = useAuth();
  
  // Card states
  const [cardName, setCardName] = useState(user?.name || '');
  const [cardNumber, setCardNumber] = useState('');
  const [cardExpiry, setCardExpiry] = useState('');
  const [cardCVV, setCardCVV] = useState('');
  
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleCardNumberChange = (e) => {
    let value = e.target.value.replace(/\D/g, ''); // Numbers only
    if (value.length > 16) value = value.slice(0, 16);
    // Format in groups of 4: XXXX XXXX XXXX XXXX
    const matches = value.match(/\d{1,4}/g);
    setCardNumber(matches ? matches.join(' ') : value);
  };

  const handleExpiryChange = (e) => {
    let value = e.target.value.replace(/\D/g, ''); // Numbers only
    if (value.length > 4) value = value.slice(0, 4);
    if (value.length > 2) {
      setCardExpiry(`${value.slice(0, 2)}/${value.slice(2)}`);
    } else {
      setCardExpiry(value);
    }
  };

  const handleCVVChange = (e) => {
    const value = e.target.value.replace(/\D/g, '');
    if (value.length <= 3) setCardCVV(value);
  };

  const handlePayment = async (e) => {
    e.preventDefault();
    if (!cardNumber || !cardName || !cardExpiry || !cardCVV) {
      setError('Please fill in all checkout payment details.');
      return;
    }
    if (cardNumber.replace(/\s/g, '').length < 16) {
      setError('Credit card number must be a valid 16-digit sequence.');
      return;
    }
    if (cardExpiry.length < 5) {
      setError('Expiration date must be formatted as MM/YY.');
      return;
    }
    if (cardCVV.length < 3) {
      setError('CVV security code must be 3 digits.');
      return;
    }

    setError('');
    setSubmitting(true);

    try {
      // Simulate network request delays
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      await processPremiumReactivation();
      setSuccess(true);
    } catch (err) {
      setError(err.message || 'Payment simulation failed. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="auth-wrapper" style={{ minHeight: '100vh', padding: '40px 20px' }}>
      <div className="glass-panel slide-in" style={{
        width: '100%',
        maxWidth: '780px',
        padding: '40px',
        display: 'grid',
        gridTemplateColumns: '1fr 1.2fr',
        gap: '40px',
        alignItems: 'center'
      }}>
        
        {/* Left column: suspended announcement info */}
        <div>
          <div style={{
            background: 'rgba(239, 68, 68, 0.1)',
            border: '1px solid rgba(239, 68, 68, 0.2)',
            width: '48px',
            height: '48px',
            borderRadius: '12px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#ef4444',
            marginBottom: '20px'
          }}>
            <ShieldAlert size={26} />
          </div>

          <h2 style={{ fontSize: '24px', fontWeight: 800, color: '#fff', marginBottom: '12px' }}>
            Access Suspended
          </h2>
          
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', lineHeight: '1.6', marginBottom: '24px' }}>
            Hello <strong style={{ color: '#fff' }}>{user?.name}</strong>, your employee agent profile is currently set as <strong style={{ color: '#ef4444' }}>Deactivated</strong> by the System Administrator.
          </p>

          <div style={{
            background: 'rgba(255, 255, 255, 0.02)',
            border: '1px solid var(--glass-border)',
            borderRadius: '12px',
            padding: '16px',
            marginBottom: '24px'
          }}>
            <h4 style={{ fontSize: '13px', fontWeight: 700, color: 'hsl(var(--primary))', display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '6px' }}>
              <Sparkles size={14} /> CRM Premium Unlock
            </h4>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)', lineHeight: '1.5' }}>
              To bypass administrative suspension immediately and reactivate your profile, upgrade to the <strong>CRM Premium Package</strong>. Unlocks:
            </p>
            <ul style={{ fontSize: '11px', color: 'var(--text-secondary)', marginTop: '8px', paddingLeft: '16px', display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <li>Full Solar CRM Pipeline Ledger</li>
              <li>Real-time Sales Conversion Telemetry</li>
              <li>Flashed Firmware OTA updates & Bin Uploads</li>
            </ul>
          </div>

          <button
            onClick={logout}
            className="glass-btn danger"
            style={{ width: '100%', justifyContent: 'center', gap: '8px' }}
          >
            <LogOut size={16} />
            Sign Out
          </button>
        </div>

        {/* Right column: checkout payment portal */}
        <div style={{ borderLeft: '1px solid var(--glass-border)', paddingLeft: '40px' }}>
          {success ? (
            <div style={{ textAlign: 'center', padding: '30px 10px', animation: 'scaleUp 0.3s ease' }}>
              <div style={{
                width: '64px',
                height: '64px',
                borderRadius: '50%',
                background: 'rgba(16, 185, 129, 0.15)',
                border: '2px solid #10b981',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#10b981',
                margin: '0 auto 20px auto',
                boxShadow: '0 0 20px rgba(16, 185, 129, 0.3)'
              }}>
                <Check size={36} />
              </div>
              <h3 style={{ fontSize: '20px', fontWeight: 800, color: '#fff', marginBottom: '8px' }}>Payment Approved</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: '13px', lineHeight: '1.5' }}>
                Your solar controller CRM account has been successfully upgraded to Premium! Access has been restored. Enjoy full telemetry operations.
              </p>
            </div>
          ) : (
            <form onSubmit={handlePayment}>
              {/* Premium Header */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                <span style={{ fontSize: '13px', fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '1px' }}>
                  Secure Payment Gateway
                </span>
                <span style={{ fontSize: '14px', fontWeight: 800, color: 'hsl(var(--primary))', display: 'flex', alignItems: 'center', gap: '3px' }}>
                  <Award size={16} /> $49.00
                </span>
              </div>

              {/* Glowing Credit Card component */}
              <div className="credit-card">
                <div className="credit-card-header">
                  <span style={{ fontWeight: 800, fontSize: '14px', letterSpacing: '2px', color: '#ffb56b' }}>SOLAR PRO</span>
                  <Award size={20} color="#ffd700" className="pulse-soft" />
                </div>
                <div className="card-number">
                  {cardNumber || '•••• •••• •••• ••••'}
                </div>
                <div className="card-footer">
                  <div>
                    <div className="card-holder-label">Cardholder</div>
                    <div className="card-holder-name">{cardName || 'NAME SURNAME'}</div>
                  </div>
                  <div>
                    <div className="card-holder-label">Expiry</div>
                    <div className="card-holder-name" style={{ fontSize: '13px' }}>{cardExpiry || 'MM/YY'}</div>
                  </div>
                </div>
              </div>

              {error && (
                <div style={{ background: 'rgba(239, 68, 68, 0.15)', border: '1px solid rgba(239, 68, 68, 0.3)', borderRadius: '8px', color: '#ef4444', padding: '10px', fontSize: '12px', marginBottom: '14px', textAlign: 'center', fontWeight: 500 }}>
                  {error}
                </div>
              )}

              {/* Card Inputs */}
              <div className="form-group">
                <label>Cardholder Name</label>
                <input
                  type="text"
                  className="glass-input"
                  placeholder="John Doe"
                  value={cardName}
                  onChange={(e) => setCardName(e.target.value.toUpperCase())}
                  disabled={submitting}
                />
              </div>

              <div className="form-group">
                <label>Card Number</label>
                <div style={{ position: 'relative' }}>
                  <span style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--text-muted)' }}><CreditCard size={16} /></span>
                  <input
                    type="text"
                    className="glass-input"
                    placeholder="4000 1234 5678 9010"
                    style={{ paddingLeft: '40px' }}
                    value={cardNumber}
                    onChange={handleCardNumberChange}
                    disabled={submitting}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '24px' }}>
                <div className="form-group">
                  <label>Expiry Date</label>
                  <input
                    type="text"
                    className="glass-input"
                    placeholder="MM/YY"
                    value={cardExpiry}
                    onChange={handleExpiryChange}
                    disabled={submitting}
                  />
                </div>

                <div className="form-group">
                  <label>CVV Code</label>
                  <div style={{ position: 'relative' }}>
                    <span style={{ position: 'absolute', left: '12px', top: '12px', color: 'var(--text-muted)' }}><Lock size={16} /></span>
                    <input
                      type="password"
                      className="glass-input"
                      style={{ paddingLeft: '40px' }}
                      placeholder="•••"
                      value={cardCVV}
                      onChange={handleCVVChange}
                      disabled={submitting}
                    />
                  </div>
                </div>
              </div>

              <button
                type="submit"
                className="glass-btn primary"
                style={{ width: '100%', padding: '12px', justifyContent: 'center' }}
                disabled={submitting}
              >
                {submitting ? 'Processing Payment...' : 'Unlock CRM Premium ($49)'}
              </button>
            </form>
          )}
        </div>

      </div>
    </div>
  );
};

export default Deactivated;
