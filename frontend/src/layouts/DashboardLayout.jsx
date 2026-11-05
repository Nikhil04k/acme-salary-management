import { Outlet } from 'react-router-dom'
import Sidebar from '../components/Sidebar'
import Header from '../components/Header'

function DashboardLayout() {
  return (
    <div className="flex h-screen overflow-hidden bg-slate-50">
      {/* Fixed sidebar */}
      <aside className="h-screen w-72 shrink-0 border-r border-slate-200 bg-white">
        <Sidebar />
      </aside>

      {/* Main content */}
      <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
        {/* Fixed header */}
        <header className="z-10 shrink-0 border-b border-slate-200 bg-white">
          <Header />
        </header>

        {/* Only this section scrolls */}
        <main className="flex-1 overflow-y-auto p-6 md:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

export default DashboardLayout
