
import { NavLink } from 'react-router-dom'

const navigation = [
  { name: 'Dashboard', path: '/dashboard', icon: '▦' },
  { name: 'Employees', path: '/employees', icon: '♙' },
  { name: 'Reports', path: '/reports', icon: '▤' },
]

function Sidebar() {
  return (
    <aside className="flex h-screen w-64 shrink-0 flex-col border-r border-slate-200 bg-white">
      <div className="border-b border-slate-200 px-6 py-6">
        <h1 className="text-xl font-bold text-blue-600">
          ACME
        </h1>
        <p className="mt-1 text-xs text-slate-500">
          Salary Management
        </p>
      </div>

      <nav className="flex-1 space-y-1 px-3 py-6">
        <p className="mb-3 px-3 text-xs font-semibold uppercase tracking-wider text-slate-400">
          Main Menu
        </p>

        {navigation.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-lg px-3 py-3 text-sm font-medium transition ${
                isActive
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-slate-600 hover:bg-slate-100'
              }`
            }
          >
            <span className="text-lg">{item.icon}</span>
            {item.name}
          </NavLink>
        ))}
      </nav>

      <div className="border-t border-slate-200 p-4">
        <p className="text-xs text-slate-400">
          ACME Salary Management v1.0
        </p>
      </div>
    </aside>
  )
}

export default Sidebar
