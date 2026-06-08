import { Outlet, NavLink, useNavigate } from 'react-router-dom'

const links = [
  { to: '/',           icon: '📊', label: 'Overview'   },
  { to: '/diagnose',   icon: '🔬', label: 'Diagnose'   },
  { to: '/users',      icon: '👥', label: 'Users'       },
  { to: '/diseases',   icon: '🦠', label: 'Diseases'    },
  { to: '/pesticides', icon: '💧', label: 'Pesticides'  },
  { to: '/activities', icon: '🕐', label: 'Activities'  },
]

export default function Layout() {
  const navigate = useNavigate()

  function handleLogout() {
    localStorage.removeItem('adminToken')
    navigate('/login')
  }

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <h2>🌿 CashewCare</h2>
          <small>Admin Dashboard</small>
        </div>

        <nav>
          {links.map(({ to, icon, label }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}
            >
              <span>{icon}</span>{label}
            </NavLink>
          ))}
          <div className="nav-section">AI Config</div>
          <NavLink
            to="/model"
            className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}
          >
            <span>🤖</span>AI Model
          </NavLink>
        </nav>

        <div className="sidebar-footer">
          <button onClick={handleLogout}>↩ Logout</button>
        </div>
      </aside>

      <main className="main">
        <Outlet />
      </main>
    </div>
  )
}
