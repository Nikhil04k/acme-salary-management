
import { useEffect, useState } from 'react'
import dashboardService from '../services/dashboardService'
import StatCard from '../components/StatCard'

function DashboardPage() {
  const [overview, setOverview] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchOverview = async () => {
      try {
        const data = await dashboardService.getOverview()
        setOverview(data)
      } catch (err) {
        setError(
          err.response?.data?.error ||
          'Unable to load dashboard statistics'
        )
      } finally {
        setLoading(false)
      }
    }

    fetchOverview()
  }, [])

  if (loading) {
    return <p className="text-slate-500">Loading dashboard...</p>
  }

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 p-4 text-red-600">
        {error}
      </div>
    )
  }

  const employees = overview.employees

  const stats = [
    {
      title: 'Total Employees',
      value: employees.total,
      description: 'All employees',
      color: 'blue',
    },
    {
      title: 'Active Employees',
      value: employees.active,
      description: 'Currently active',
      color: 'green',
    },
    {
      title: 'Inactive Employees',
      value: employees.inactive,
      description: 'Currently inactive',
      color: 'orange',
    },
    {
      title: 'Terminated Employees',
      value: employees.terminated,
      description: 'Employment ended',
      color: 'red',
    },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-slate-800">
          Dashboard
        </h1>

        <p className="mt-1 text-sm text-slate-500">
          Overview of employee and salary information
        </p>
      </div>

      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => (
          <StatCard key={stat.title} {...stat} />
        ))}
      </div>

      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <h2 className="text-lg font-semibold text-slate-800">
          Average Annual Compensation
        </h2>

        <p className="mt-1 text-sm text-slate-500">
          Average compensation grouped by currency
        </p>

        <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Object.entries(
            overview.average_compensation_by_currency
          ).map(([currency, amount]) => (
            <div
              key={currency}
              className="rounded-lg bg-slate-50 p-4"
            >
              <p className="text-sm font-medium text-slate-500">
                {currency}
              </p>

              <p className="mt-2 text-xl font-bold text-slate-800">
                {Number(amount).toLocaleString('en-IN', {
                  maximumFractionDigits: 2,
                })}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default DashboardPage
