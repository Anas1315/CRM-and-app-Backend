import { useEffect, useState } from 'react';
import { api } from '../services/api';
import MetricCard from '../components/MetricCard';
import LineChart   from '../components/LineChart';
import {
  DollarSign, Smartphone, UserX, Cpu, TrendingUp
} from 'lucide-react';

// Simple donut / ring chart drawn in SVG
const RingChart = ({ value, total, color, label }) => {
  const pct = total > 0 ? (value / total) * 100 : 0;
  const r = 44, circ = 2 * Math.PI * r;
  const dash = (pct / 100) * circ;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px' }}>
      <svg width="110" height="110" viewBox="0 0 110 110">
        <circle cx="55" cy="55" r={r} fill="none" stroke="rgba(255,255,255,.04)" strokeWidth="10" />
        <circle cx="55" cy="55" r={r} fill="none" stroke={color} strokeWidth="10"
          strokeDasharray={`${dash} ${circ}`} strokeLinecap="round"
          transform="rotate(-90 55 55)"
          style={{ filter: `drop-shadow(0 0 6px ${color}80)` }} />
        <text x="55" y="51" textAnchor="middle" fill="#fff" fontSize="18" fontWeight="800">{value}</text>
        <text x="55" y="67" textAnchor="middle" fill="hsl(var(--text-muted))" fontSize="9" fontWeight="600">
          {pct.toFixed(0)}%
        </text>
      </svg>
      <span style={{ fontSize: '12px', fontWeight: 600, color: 'hsl(var(--text-secondary))' }}>{label}</span>
    </div>
  );
};

const Dashboard = () => {
  const [stats,   setStats]   = useState(null);
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState('');

  useEffect(() => {
    api.get('/api/dashboard/stats')
      .then(setStats)
      .catch(err => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return (
    <div style={{ display:'flex', justifyContent:'center', alignItems:'center', height:'60vh', flexDirection:'column', gap:'16px' }}>
      <div style={{ width:'40px', height:'40px', border:'3px solid rgba(255,125,0,.1)', borderTopColor:'hsl(var(--primary))', borderRadius:'50%', animation:'spin-slow 1s linear infinite' }} />
      <p style={{ color:'hsl(var(--text-secondary))', fontWeight:500 }}>Syncing analytics...</p>
    </div>
  );

  if (error) return (
    <div className="glass-panel" style={{ padding:'30px', textAlign:'center', color:'#ef4444' }}>
      <h3>Could not load dashboard</h3><p style={{ marginTop:'8px', color:'hsl(var(--text-secondary))' }}>{error}</p>
    </div>
  );

  const { metrics = {}, recentSales = [], salesTrend = [], userGrowth = [] } = stats || {};
  // Normalize backend shapes: older endpoints may return `pipeline` instead of `userGrowth`,
  // and may use different metric keys. Provide safe fallbacks so the UI doesn't crash.
  const safeUserGrowth = userGrowth.length ? userGrowth : (stats?.pipeline || []);
  const normalizedMetrics = {
    totalRevenue: metrics.totalRevenue || 0,
    totalSales: metrics.totalSales || 0,
    totalAppUsers: metrics.totalAppUsers || metrics.totalCustomers || 0,
    deactivatedUsers: metrics.deactivatedUsers || 0,
    activeFirmware: metrics.activeFirmware || 'N/A',
    ...metrics
  };

  return (
    <div className="slide-in">
      {/* ── Page header ── */}
      <header style={{ marginBottom:'28px' }}>
        <h1 style={{ fontSize:'26px', fontWeight:800, color:'#fff', marginBottom:'4px' }}>Analytics Dashboard</h1>
        <p style={{ color:'hsl(var(--text-secondary))', fontSize:'14px' }}>
          Real-time overview of client systems and key energy telemetry metrics
        </p>
      </header>

      {/* ── Metric cards ── */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fit,minmax(200px,1fr))', gap:'18px', marginBottom:'28px' }}>
        <MetricCard title="Total Revenue"     value={`$${normalizedMetrics.totalRevenue.toLocaleString()}`} icon={DollarSign} color="green" />
        <MetricCard title="Completed Sales"   value={normalizedMetrics.totalSales}                          icon={TrendingUp}  color="blue"  />
        <MetricCard title="Mobile App Users"  value={normalizedMetrics.totalAppUsers}                       icon={Smartphone}  color="orange" />
        <MetricCard title="Deactivated Users" value={normalizedMetrics.deactivatedUsers}                    icon={UserX}       color="red"   />
        <MetricCard title="Active Firmware"   value={normalizedMetrics.activeFirmware}                      icon={Cpu}         color="blue"  />
      </div>

      {/* ── Charts row ── */}
      <div style={{ display:'grid', gridTemplateColumns:'2fr 1fr', gap:'22px', marginBottom:'28px' }}>
        {/* Sales revenue trend */}
        <div className="glass-panel" style={{ padding:'24px' }}>
          <h3 style={{ fontSize:'16px', fontWeight:700, marginBottom:'18px', color:'#fff' }}>
            Revenue Trend — Last 5 Months
          </h3>
          <LineChart data={salesTrend} height={220} />
        </div>

        {/* App user distribution donut rings */}
        <div className="glass-panel" style={{ padding:'24px' }}>
          <h3 style={{ fontSize:'16px', fontWeight:700, marginBottom:'18px', color:'#fff' }}>
            App User Breakdown
          </h3>
          <div style={{ display:'flex', justifyContent:'space-around', alignItems:'center', height:'180px' }}>
            <RingChart value={normalizedMetrics.deactivatedUsers} total={normalizedMetrics.totalAppUsers} color="#ef4444" label="Deactivated" />
            <RingChart
              value={normalizedMetrics.totalAppUsers - normalizedMetrics.deactivatedUsers}
              total={normalizedMetrics.totalAppUsers} color="#3b82f6" label="Active" />
          </div>
        </div>
      </div>

      {/* ── User Growth + Recent Sales ── */}
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1.5fr', gap:'22px' }}>
        {/* New user registrations bar */}
        <div className="glass-panel" style={{ padding:'24px' }}>
          <h3 style={{ fontSize:'16px', fontWeight:700, marginBottom:'18px', color:'#fff' }}>
            New App Registrations
          </h3>
          <div style={{ display:'flex', flexDirection:'column', gap:'12px' }}>
            {safeUserGrowth.map((item, i) => {
              const maxVal = Math.max(...safeUserGrowth.map(u => Number(u.count || 0)), 1);
              return (
                <div key={i}>
                  <div style={{ display:'flex', justifyContent:'space-between', fontSize:'12px', fontWeight:600, marginBottom:'5px' }}>
                    <span style={{ color:'hsl(var(--text-secondary))' }}>{item.month}</span>
                    <span style={{ color:'#fff' }}>{Number(item.count || 0)} users</span>
                  </div>
                  <div style={{ width:'100%', height:'6px', background:'rgba(255,255,255,.04)', borderRadius:'3px', overflow:'hidden' }}>
                    <div style={{
                      width: `${(Number(item.count || 0) / maxVal) * 100}%`, height:'100%', borderRadius:'3px',
                      background:'linear-gradient(90deg,hsl(var(--primary)) 0%,#ff4500 100%)'
                    }} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Recent sales */}
        <div className="glass-panel" style={{ padding:'24px' }}>
          <h3 style={{ fontSize:'16px', fontWeight:700, marginBottom:'18px', color:'#fff' }}>
            Recent Sales
          </h3>
          <div className="table-container">
            <table className="custom-table">
              <thead>
                <tr>
                  <th>Customer</th>
                  <th>Product</th>
                  <th style={{ textAlign:'right' }}>Amount</th>
                </tr>
              </thead>
              <tbody>
                {recentSales.length === 0 ? (
                  <tr><td colSpan="3" style={{ textAlign:'center', color:'hsl(var(--text-muted))', padding:'20px' }}>
                    No sales recorded yet
                  </td></tr>
                ) : recentSales.map((s, i) => (
                  <tr key={i}>
                    <td>
                      <div style={{ fontWeight:600, color:'#fff', fontSize:'14px' }}>{s.customer_name || 'Manual customer'}</div>
                      <div style={{ fontSize:'11px', color:'hsl(var(--text-secondary))' }}>{s.customer_email || 'Manual sale'}</div>
                    </td>
                    <td style={{ fontSize:'13px' }}>{s.product_name}</td>
                    <td style={{ textAlign:'right', fontWeight:700, color:'#10b981' }}>
                      ${parseFloat(s.amount).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
