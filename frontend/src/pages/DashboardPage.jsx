
import { useEffect, useState } from 'react'
import dashboardService from '../services/dashboardService'
import StatCard from '../components/StatCard'

function DashboardPage() {
  const [overview, setOverview] = useState(null)
  const [distribution, setDistribution] = useState(null)
  const [salaryAnalytics, setSalaryAnalytics] = useState(null)
  const [recentChanges, setRecentChanges] = useState([])

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const [
          overviewData,
          distributionData,
          salaryData,
          recentData,
        ] = await Promise.all([
          dashboardService.getOverview(),
          dashboardService.getEmployeeDistribution(),
          dashboardService.getSalaryAnalytics(),
          dashboardService.getRecentSalaryChanges(8),
        ])

        setOverview(overviewData)
        setDistribution(distributionData)
        setSalaryAnalytics(salaryData)
        setRecentChanges(recentData)
      } catch (err) {
        setError(
          err.response?.data?.error ||
          'Unable to load dashboard information'
        )
      } finally {
        setLoading(false)
      }
    }

    fetchDashboard()
  }, [])

  if (loading) {
    return (
      <div className="py-10 text-center text-slate-500">
        Loading dashboard...
      </div>
    )
  }

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 p-4 text-red-600">
        {error}
      </div>
    )
  }

  if (!overview || !distribution || !salaryAnalytics) {
    return null
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

  const formatNumber = (value, digits = 0) => {
    return Number(value || 0).toLocaleString('en-IN', {
      minimumFractionDigits: digits,
      maximumFractionDigits: digits,
    })
  }

  const formatDateTime = (value) => {
    if (!value) return '—'

    return new Date(value).toLocaleString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const formatAction = (action) => {
    return String(action || '')
      .replaceAll('_', ' ')
      .replace(/\b\w/g, (letter) => letter.toUpperCase())
  }

  const countryData = distribution.by_country || []
  const departmentData = distribution.by_department || []
  const statusData = distribution.by_status || {}

  const maxCountryCount = Math.max(
    ...countryData.map((item) => Number(item.employee_count)),
    1
  )

  const maxDepartmentCount = Math.max(
    ...departmentData.map((item) => Number(item.employee_count)),
    1
  )

  const statusColors = {
    active: 'bg-green-500',
    inactive: 'bg-orange-500',
    terminated: 'bg-red-500',
  }

  const statusTextColors = {
    active: 'text-green-700',
    inactive: 'text-orange-700',
    terminated: 'text-red-700',
  }

  const statusEntries = Object.entries(statusData)

  const totalStatusEmployees = statusEntries.reduce(
    (total, [, count]) => total + Number(count),
    0
  )

  return (
    <div className="space-y-8">

      {/* Page heading */}
      <div>
        <h1 className="text-2xl font-bold text-slate-800">
          Dashboard
        </h1>

        <p className="mt-1 text-sm text-slate-500">
          Overview of employee and salary information
        </p>
      </div>

      {/* Employee overview cards */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => (
          <StatCard key={stat.title} {...stat} />
        ))}
      </div>

      {/* Average annual compensation */}
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <h2 className="text-lg font-semibold text-slate-800">
          Average Annual Compensation
        </h2>

        <p className="mt-1 text-sm text-slate-500">
          Average compensation grouped by currency
        </p>

        <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Object.entries(
            overview.average_compensation_by_currency || {}
          ).map(([currency, amount]) => (
            <div
              key={currency}
              className="rounded-lg bg-slate-50 p-4"
            >
              <p className="text-sm font-medium text-slate-500">
                {currency}
              </p>

              <p className="mt-2 text-xl font-bold text-slate-800">
                {formatNumber(amount, 2)}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* Employee distribution */}
      <section className="space-y-5">
        <div>
          <h2 className="text-xl font-bold text-slate-800">
            Employee Distribution
          </h2>

          <p className="mt-1 text-sm text-slate-500">
            Workforce breakdown across countries, departments and employment status
          </p>
        </div>

        <div className="grid grid-cols-1 gap-6 xl:grid-cols-2">

          {/* Country distribution */}
          <div className="rounded-xl border border-slate-200 bg-white p-6">
            <h3 className="text-base font-semibold text-slate-800">
              Employees by Country
            </h3>

            <p className="mt-1 text-sm text-slate-500">
              Workforce distribution across countries
            </p>

            <div className="mt-6 space-y-5">
              {countryData.map((item) => {
                const percentage =
                  (Number(item.employee_count) / maxCountryCount) * 100

                return (
                  <div key={item.iso_code}>
                    <div className="mb-2 flex items-center justify-between gap-3">
                      <span className="text-sm font-medium text-slate-700">
                        {item.country}
                        <span className="ml-2 text-xs text-slate-400">
                          {item.iso_code}
                        </span>
                      </span>

                      <span className="text-sm font-semibold text-slate-800">
                        {formatNumber(item.employee_count)}
                      </span>
                    </div>

                    <div className="h-2.5 overflow-hidden rounded-full bg-slate-100">
                      <div
                        className="h-full rounded-full bg-indigo-500"
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                  </div>
                )
              })}

              {countryData.length === 0 && (
                <p className="text-sm text-slate-500">
                  No country data available.
                </p>
              )}
            </div>
          </div>

          {/* Department distribution */}
          <div className="rounded-xl border border-slate-200 bg-white p-6">
            <h3 className="text-base font-semibold text-slate-800">
              Employees by Department
            </h3>

            <p className="mt-1 text-sm text-slate-500">
              Employee count across departments
            </p>

            <div className="mt-6 space-y-5">
              {departmentData.map((item) => {
                const percentage =
                  (Number(item.employee_count) / maxDepartmentCount) * 100

                return (
                  <div key={item.department}>
                    <div className="mb-2 flex items-center justify-between gap-3">
                      <span className="text-sm font-medium text-slate-700">
                        {item.department}
                      </span>

                      <span className="text-sm font-semibold text-slate-800">
                        {formatNumber(item.employee_count)}
                      </span>
                    </div>

                    <div className="h-2.5 overflow-hidden rounded-full bg-slate-100">
                      <div
                        className="h-full rounded-full bg-blue-500"
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                  </div>
                )
              })}

              {departmentData.length === 0 && (
                <p className="text-sm text-slate-500">
                  No department data available.
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Employment status */}
        <div className="rounded-xl border border-slate-200 bg-white p-6">
          <h3 className="text-base font-semibold text-slate-800">
            Employment Status
          </h3>

          <p className="mt-1 text-sm text-slate-500">
            Distribution of employees by employment status
          </p>

          <div className="mt-6 flex h-4 overflow-hidden rounded-full bg-slate-100">
            {statusEntries.map(([status, count]) => {
              const percentage = totalStatusEmployees
                ? (Number(count) / totalStatusEmployees) * 100
                : 0

              return (
                <div
                  key={status}
                  className={statusColors[status] || 'bg-slate-400'}
                  style={{ width: `${percentage}%` }}
                  title={`${status}: ${formatNumber(count)}`}
                />
              )
            })}
          </div>

          <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-3">
            {statusEntries.map(([status, count]) => (
              <div key={status} className="flex items-center gap-3">
                <span
                  className={`h-3 w-3 rounded-full ${
                    statusColors[status] || 'bg-slate-400'
                  }`}
                />

                <div>
                  <p className="text-sm capitalize text-slate-500">
                    {status}
                  </p>

                  <p className={`text-lg font-bold ${
                    statusTextColors[status] || 'text-slate-800'
                  }`}>
                    {formatNumber(count)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Salary analytics */}
      <section className="space-y-5">
        <div>
          <h2 className="text-xl font-bold text-slate-800">
            Salary Analytics
          </h2>

          <p className="mt-1 text-sm text-slate-500">
            Current compensation insights for active employees
          </p>
        </div>

        {/* Salary by currency */}
        <div className="rounded-xl border border-slate-200 bg-white p-6">
          <h3 className="text-base font-semibold text-slate-800">
            Compensation by Currency
          </h3>

          <div className="mt-5 overflow-x-auto">
            <table className="w-full min-w-[650px] text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-4 py-3">Currency</th>
                  <th className="px-4 py-3">Employees</th>
                  <th className="px-4 py-3">Average</th>
                  <th className="px-4 py-3">Minimum</th>
                  <th className="px-4 py-3">Maximum</th>
                  <th className="px-4 py-3">Total</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {(salaryAnalytics.by_currency || []).map((item) => (
                  <tr key={item.currency}>
                    <td className="px-4 py-4 font-semibold text-slate-800">
                      {item.currency}
                    </td>

                    <td className="px-4 py-4">
                      {formatNumber(item.employee_count)}
                    </td>

                    <td className="px-4 py-4 font-medium">
                      {formatNumber(item.average_compensation, 2)}
                    </td>

                    <td className="px-4 py-4">
                      {formatNumber(item.minimum_compensation, 2)}
                    </td>

                    <td className="px-4 py-4">
                      {formatNumber(item.maximum_compensation, 2)}
                    </td>

                    <td className="px-4 py-4 font-medium">
                      {formatNumber(item.total_compensation, 2)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Department salary analytics */}
        <div className="rounded-xl border border-slate-200 bg-white p-6">
          <h3 className="text-base font-semibold text-slate-800">
            Average Compensation by Department
          </h3>

          <p className="mt-1 text-sm text-slate-500">
            Values are grouped by currency and should not be compared across different currencies.
          </p>

          {/* Full-width, scrollable table */}
          <div className="mt-5 max-h-[420px] w-full overflow-auto">
            <table className="w-full min-w-[700px] table-fixed text-left text-sm">
              <colgroup>
                <col className="w-[40%]" />
                <col className="w-[20%]" />
                <col className="w-[40%]" />
              </colgroup>

              <thead className="sticky top-0 z-10 bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-4 py-3">Department</th>
                  <th className="px-4 py-3">Currency</th>
                  <th className="px-4 py-3">Average Compensation</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {(salaryAnalytics.by_department || []).map((item, index) => (
                  <tr
                    key={`${item.department}-${item.currency}-${index}`}
                    className="hover:bg-slate-50"
                  >
                    <td className="px-4 py-4 font-medium text-slate-800">
                      {item.department}
                    </td>

                    <td className="px-4 py-4">
                      {item.currency}
                    </td>

                    <td className="px-4 py-4 font-semibold">
                      {formatNumber(item.average_compensation, 2)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* Recent salary changes */}
      <section className="rounded-xl border border-slate-200 bg-white p-6">
        <div>
          <h2 className="text-lg font-semibold text-slate-800">
            Recent Salary Changes
          </h2>

          <p className="mt-1 text-sm text-slate-500">
            Latest salary-related activities recorded in the system
          </p>
        </div>

        {recentChanges.length === 0 ? (
          <div className="mt-5 rounded-lg bg-slate-50 p-6 text-center">
            <p className="text-sm text-slate-500">
              No recent salary changes available.
            </p>
          </div>
        ) : (
          <div className="mt-5 overflow-x-auto">
            <table className="w-full min-w-[650px] text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-4 py-3">Employee</th>
                  <th className="px-4 py-3">Employee Number</th>
                  <th className="px-4 py-3">Action</th>
                  <th className="px-4 py-3">Performed By</th>
                  <th className="px-4 py-3">Date</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {recentChanges.map((item) => (
                  <tr key={item.id}>
                    <td className="px-4 py-4 font-medium text-slate-800">
                      {item.employee?.full_name || '—'}
                    </td>

                    <td className="px-4 py-4 text-slate-600">
                      {item.employee?.employee_number || '—'}
                    </td>

                    <td className="px-4 py-4">
                      <span className="rounded-full bg-indigo-50 px-3 py-1 text-xs font-medium text-indigo-700">
                        {formatAction(item.action)}
                      </span>
                    </td>

                    <td className="px-4 py-4 text-slate-600">
                      {item.performed_by?.email || '—'}
                    </td>

                    <td className="px-4 py-4 text-slate-600">
                      {formatDateTime(item.created_at)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

    </div>
  )
}

export default DashboardPage
