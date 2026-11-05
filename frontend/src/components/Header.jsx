import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

function Header() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = async () => {
    await logout()
    navigate('/login', { replace: true })
  }

  const displayName = user?.email?.split('@')[0] || 'User'

  return (
    <header className="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-8">
      <h2 className="text-lg font-semibold text-slate-800">
        Salary Management
      </h2>

      <div className="flex items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-blue-100 font-semibold uppercase text-blue-600">
            {displayName.charAt(0)}
          </div>

          <div>
            <p className="text-sm font-semibold text-slate-800">
              {displayName}
            </p>
            <p className="text-xs text-slate-500">
              {user?.role?.replace('_', ' ')}
            </p>
          </div>
        </div>

        <button
          onClick={handleLogout}
          className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-100"
        >
          Logout
        </button>
      </div>
    </header>
  )
}

export default Header
