/**
 * Simple metric card used throughout the CRM dashboard.
 * Props:
 *   - title: string – label of the metric
 *   - value: string | number – value to display
 *   - icon: ReactComponent – lucide icon component
 *   - color: string – CSS colour for the icon (e.g. 'green', '#10b981')
 */
export default function MetricCard({ title, value, icon: Icon, color }) {
  return (
    <div className="glass-panel" style={{
      padding: '18px',
      display: 'flex',
      alignItems: 'center',
      gap: '12px',
      borderRadius: '12px',
    }}>
      <Icon size={26} color={color} />
      <div>
        <div style={{ fontSize: '13px', color: 'hsl(var(--text-secondary))' }}>{title}</div>
        <div style={{ fontSize: '20px', fontWeight: 600, color: '#fff' }}>{value}</div>
      </div>
    </div>
  );
}
