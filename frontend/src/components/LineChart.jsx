import { useState } from 'react';

const LineChart = ({ data = [], height = 220 }) => {
  const [hoveredPoint, setHoveredPoint] = useState(null);

  if (data.length === 0) return <div style={{ color: 'var(--text-muted)' }}>No data available</div>;

  const numericData = data.map(item => ({
    ...item,
    sales: Number(item.sales || 0)
  }));
  const maxSales = Math.max(...numericData.map(d => d.sales), 0);
  const maxVal = Math.max(maxSales * 1.1, 1);
  const minVal = 0;

  const width = 600;
  const padding = 40;
  const chartWidth = width - padding * 2;
  const chartHeight = height - padding * 2;

  // Calculate coordinates
  const points = numericData.map((d, index) => {
    const x = numericData.length === 1
      ? padding + chartWidth / 2
      : padding + (index / (numericData.length - 1)) * chartWidth;
    const y = padding + chartHeight - ((d.sales - minVal) / (maxVal - minVal)) * chartHeight;
    return { x, y, ...d };
  });

  // Generate SVG path (smooth bezier curve)
  let pathD = '';
  if (points.length > 0) {
    pathD = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const curr = points[i];
      const next = points[i + 1];
      const cpX1 = curr.x + (next.x - curr.x) / 3;
      const cpY1 = curr.y;
      const cpX2 = curr.x + (2 * (next.x - curr.x)) / 3;
      const cpY2 = next.y;
      pathD += ` C ${cpX1} ${cpY1}, ${cpX2} ${cpY2}, ${next.x} ${next.y}`;
    }
  }

  // Generate Area Fill Path
  const areaD = pathD ? `${pathD} L ${points[points.length - 1].x} ${height - padding} L ${points[0].x} ${height - padding} Z` : '';

  return (
    <div style={{ position: 'relative', width: '100%' }}>
      <svg 
        viewBox={`0 0 ${width} ${height}`} 
        className="slide-in"
        style={{ width: '100%', height: 'auto', overflow: 'visible' }}
      >
        <defs>
          {/* Main stroke gradient */}
          <linearGradient id="chartStroke" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor="hsl(var(--primary))" />
            <stop offset="100%" stopColor="#ff4500" />
          </linearGradient>
          
          {/* Neon energy glow */}
          <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="0" dy="4" stdDeviation="6" floodColor="hsl(var(--primary))" floodOpacity="0.4" />
          </filter>

          {/* Under-curve background gradient */}
          <linearGradient id="areaFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="hsl(var(--primary))" stopOpacity="0.25" />
            <stop offset="100%" stopColor="hsl(var(--primary))" stopOpacity="0.0" />
          </linearGradient>
        </defs>

        {/* Gridlines */}
        {[0, 0.25, 0.5, 0.75, 1].map((ratio, idx) => {
          const y = padding + ratio * chartHeight;
          return (
            <line
              key={idx}
              x1={padding}
              y1={y}
              x2={width - padding}
              y2={y}
              stroke="rgba(255, 255, 255, 0.03)"
              strokeDasharray="4 4"
            />
          );
        })}

        {/* X and Y Axes lines */}
        <line
          x1={padding}
          y1={height - padding}
          x2={width - padding}
          y2={height - padding}
          stroke="rgba(255, 255, 255, 0.08)"
          strokeWidth="1"
        />

        {/* Translucent Area Under Curve */}
        {areaD && <path d={areaD} fill="url(#areaFill)" />}

        {/* Bezier Vector Curve */}
        {pathD && (
          <path
            d={pathD}
            fill="none"
            stroke="url(#chartStroke)"
            strokeWidth="3.5"
            filter="url(#glow)"
            style={{ strokeDasharray: 1000, strokeDashoffset: 0, transition: 'stroke-dashoffset 2s ease' }}
          />
        )}

        {/* Data Interactive Nodes */}
        {points.map((pt, idx) => (
          <g key={idx}>
            {/* Pulsing glow ring */}
            <circle
              cx={pt.x}
              cy={pt.y}
              r={hoveredPoint === idx ? 8 : 4}
              fill="rgba(255, 165, 0, 0.2)"
              style={{ transition: 'var(--transition-fast)' }}
            />
            {/* Core dot */}
            <circle
              cx={pt.x}
              cy={pt.y}
              r={hoveredPoint === idx ? 5 : 3.5}
              fill="#fff"
              stroke="hsl(var(--primary))"
              strokeWidth="2"
              style={{ cursor: 'pointer', transition: 'var(--transition-fast)' }}
              onMouseEnter={() => setHoveredPoint(idx)}
              onMouseLeave={() => setHoveredPoint(null)}
            />
            {/* X Labels (Months) */}
            <text
              x={pt.x}
              y={height - padding + 22}
              textAnchor="middle"
              fill="hsl(var(--text-muted))"
              fontSize="11"
              fontWeight="600"
            >
              {pt.month}
            </text>
          </g>
        ))}

        {/* Y Axis Max Label */}
        <text
          x={padding - 10}
          y={padding + 4}
          textAnchor="end"
          fill="hsl(var(--text-muted))"
          fontSize="10"
          fontWeight="700"
        >
          ${Math.round(maxVal)}
        </text>
        <text
          x={padding - 10}
          y={height - padding}
          textAnchor="end"
          fill="hsl(var(--text-muted))"
          fontSize="10"
          fontWeight="700"
        >
          $0
        </text>
      </svg>

      {/* Floating HTML Tooltip */}
      {hoveredPoint !== null && (
        <div style={{
          position: 'absolute',
          left: `${(points[hoveredPoint].x / width) * 100}%`,
          top: `${(points[hoveredPoint].y / height) * 100 - 30}%`,
          transform: 'translateX(-50%) translateY(-100%)',
          background: 'rgba(15, 18, 25, 0.95)',
          border: '1px solid hsl(var(--primary))',
          borderRadius: '8px',
          padding: '6px 12px',
          color: '#fff',
          fontSize: '12px',
          fontWeight: 600,
          pointerEvents: 'none',
          boxShadow: '0 4px 15px rgba(0,0,0,0.5)',
          zIndex: 10,
          whiteSpace: 'nowrap'
        }}>
          {points[hoveredPoint].month}: ${points[hoveredPoint].sales.toLocaleString()}
        </div>
      )}
    </div>
  );
};

export default LineChart;
