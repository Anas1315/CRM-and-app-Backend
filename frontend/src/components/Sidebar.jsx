import { useAuth } from '../contexts/AuthContext';
import {
  LayoutDashboard, Briefcase, Cpu, LogOut, Award,
  Activity, ShoppingCart, Smartphone, Boxes
} from 'lucide-react';

const NAV = [
  { id: 'dashboard',  label: 'Dashboard',        icon: LayoutDashboard, roles: ['admin','employee'] },
  { id: 'app-users',  label: 'App Users',         icon: Smartphone,      roles: ['admin','employee'] },
  { id: 'products',   label: 'Products',          icon: Boxes,           roles: ['admin','employee'] },
  { id: 'sales',      label: 'Sales Records',     icon: ShoppingCart,    roles: ['admin','employee'] },
  { id: 'employees',  label: 'CRM Staff',         icon: Briefcase,       roles: ['admin'] },
  { id: 'firmware',   label: 'Firmware OTA',      icon: Cpu,             roles: ['admin','employee'] },
];

const Sidebar = ({ activePage, setActivePage }) => {
  const { employee, logout } = useAuth();
  if (!employee) return null;

  const visible = NAV.filter(n => n.roles.includes(employee.role));

  return (
    <aside className="glass-panel" style={{
      width: '260px', height: 'calc(100vh - 40px)',
      position: 'fixed', top: '20px', left: '20px',
      display: 'flex', flexDirection: 'column',
      justifyContent: 'space-between', padding: '24px', zIndex: 100
    }}>
      {/* Brand */}
      <div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: '12px',
          marginBottom: '32px', paddingBottom: '20px',
          borderBottom: '1px solid var(--glass-border)'
        }}>
          <div style={{
            background: 'linear-gradient(135deg, hsl(var(--primary)) 0%, #ff5500 100%)',
            width: '40px', height: '40px', borderRadius: '10px',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(255,125,0,0.3)'
          }}>
            <Activity size={22} className="spin-slow" color="#fff" />
          </div>
          <div>
            <h1 style={{
              fontSize: '17px', fontWeight: 800, letterSpacing: '1px',
              textTransform: 'uppercase',
              background: 'linear-gradient(135deg,#fff 0%,#aaa 100%)',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent'
            }}>SOLAR CRM</h1>
            <span style={{ fontSize: '10px', color: 'hsl(var(--text-muted))', fontWeight: 700, letterSpacing: '1px' }}>
              MANAGEMENT PORTAL
            </span>
          </div>
        </div>

        {/* Nav items */}
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          {visible.map(({ id, label, icon: Icon, badge }) => {
            const active = activePage === id;
            return (
              <button key={id} onClick={() => setActivePage(id)} style={{
                background: active
                  ? 'linear-gradient(135deg,rgba(255,125,0,.15) 0%,rgba(255,69,0,.05) 100%)'
                  : 'transparent',
                border: active ? '1px solid rgba(255,125,0,.25)' : '1px solid transparent',
                borderRadius: '10px',
                color: active ? '#fff' : 'hsl(var(--text-secondary))',
                padding: '11px 14px', display: 'flex', alignItems: 'center',
                gap: '12px', cursor: 'pointer', width: '100%', textAlign: 'left',
                fontSize: '14px', fontWeight: active ? 600 : 500,
                fontFamily: 'var(--font-main)', transition: 'var(--transition-fast)'
              }}>
                <Icon size={17} color={active ? 'hsl(var(--primary))' : 'currentColor'} />
                <span style={{ flex: 1 }}>{label}</span>
                {badge && (
                  <span style={{
                    fontSize: '9px', fontWeight: 700, padding: '2px 6px',
                    background: 'rgba(59,130,246,.15)', color: '#3b82f6',
                    border: '1px solid rgba(59,130,246,.2)', borderRadius: '10px',
                    letterSpacing: '0.3px'
                  }}>{badge}</span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Profile card + logout */}
      <div>
        <div style={{
          background: 'rgba(255,255,255,.02)', border: '1px solid var(--glass-border)',
          borderRadius: '12px', padding: '12px', marginBottom: '14px',
          display: 'flex', alignItems: 'center', gap: '10px', position: 'relative'
        }}>
          {employee.role === 'admin' && (
            <div style={{
              position: 'absolute', top: '-8px', right: '-8px',
              background: 'linear-gradient(135deg,#ffd700,#ffa500)',
              padding: '2px 7px', borderRadius: '20px',
              display: 'flex', alignItems: 'center', gap: '3px',
              boxShadow: '0 2px 8px rgba(255,215,0,.4)'
            }}>
              <Award size={9} color="#000" />
              <span style={{ fontSize: '8px', fontWeight: 800, color: '#000' }}>ADMIN</span>
            </div>
          )}
          <div style={{
            width: '36px', height: '36px', borderRadius: '50%', flexShrink: 0,
            background: 'rgba(255,125,0,.1)', border: '1px solid rgba(255,125,0,.2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 700, fontSize: '13px', color: 'hsl(var(--primary))'
          }}>
            {employee.name?.split(' ').map(n => n[0]).join('').toUpperCase().slice(0,2)}
          </div>
          <div style={{ overflow: 'hidden', flex: 1 }}>
            <div style={{ fontSize: '13px', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {employee.name}
            </div>
            <div style={{ fontSize: '11px', color: 'hsl(var(--text-muted))', marginTop: '1px' }}>
              {employee.department} · {employee.role_title || employee.role}
            </div>
          </div>
        </div>

        <button onClick={logout} className="glass-btn danger" style={{ width: '100%', justifyContent: 'center', padding: '10px' }}>
          <LogOut size={15} />
          Sign Out
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
