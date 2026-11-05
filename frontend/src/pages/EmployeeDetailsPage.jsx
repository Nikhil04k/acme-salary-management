
import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import employeeService from '../services/employeeService'

function EmployeeDetailsPage() {
  const { id } = useParams()

  const [details, setDetails] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchEmployee = async () => {
      setLoading(true)
      setError('')

      try {
        const data = await employeeService.getEmployee(id)
        setDetails(data)
      } catch (err) {
        setError(
          err.response?.data?.error ||
          'Unable to load employee details'
        )
      } finally {
        setLoading(false)
      }
    }

    fetchEmployee()
  }, [id])

  if (loading) {
    return <p className="text-slate-500">Loading employee details...</p>
  }

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 p-4 text-red-600">
        {error}
      </div>
    )
  }

  if (!details) return null

  const { employee, current_salary, salary_history } = details

  const statusStyles = {
    active: 'bg-green-50 text-green-700',
    inactive: 'bg-orange-50 text-orange-700',
    terminated: 'bg-red-50 text-red-700',
  }

  const formatDate = (date) => {
    if (!date) return 'Present'

    return new Date(`${date}T00:00:00`).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    })
  }

  const formatAmount = (amount, currency) => {
    return new Intl.NumberFormat('en-IN', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 4,
    }).format(Number(amount)) + ` ${currency}`
  }

  return (
    <div className="space-y-6">

      {/* Back navigation */}
      <Link
        to="/employees"
        className="inline-flex items-center gap-2 text-sm font-medium text-blue-600 hover:text-blue-800"
      >
        ← Back to Employees
      </Link>

      {/* Employee header */}
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">

          <div>
            <h1 className="text-2xl font-bold text-slate-800">
              {employee.full_name}
            </h1>

            <p className="mt-2 text-sm text-slate-500">
              {employee.employee_number}
            </p>

            <p className="mt-1 text-sm text-slate-500">
              {employee.email}
            </p>
          </div>

          <span className={`w-fit rounded-full px-4 py-2 text-sm font-medium capitalize ${
            statusStyles[employee.employment_status] ||
            'bg-slate-100 text-slate-600'
          }`}>
            {employee.employment_status}
          </span>

        </div>
      </div>

      {/* Employment information */}
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <h2 className="text-lg font-semibold text-slate-800">
          Employment Information
        </h2>

        <div className="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">

          <div>
            <p className="text-sm text-slate-500">Country</p>
            <p className="mt-1 font-medium text-slate-800">
              {employee.country?.name || '—'}
            </p>
          </div>

          <div>
            <p className="text-sm text-slate-500">Department</p>
            <p className="mt-1 font-medium text-slate-800">
              {employee.department?.name || '—'}
            </p>
          </div>

          <div>
            <p className="text-sm text-slate-500">Job Title</p>
            <p className="mt-1 font-medium text-slate-800">
              {employee.job_title?.name || '—'}
            </p>
          </div>

          <div>
            <p className="text-sm text-slate-500">Hire Date</p>
            <p className="mt-1 font-medium text-slate-800">
              {formatDate(employee.hired_on)}
            </p>
          </div>

          <div>
            <p className="text-sm text-slate-500">Termination Date</p>
            <p className="mt-1 font-medium text-slate-800">
              {formatDate(employee.terminated_on)}
            </p>
          </div>

          <div>
            <p className="text-sm text-slate-500">Country Code</p>
            <p className="mt-1 font-medium text-slate-800">
              {employee.country?.iso_code || '—'}
            </p>
          </div>

        </div>
      </div>

      {/* Current compensation */}
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <h2 className="text-lg font-semibold text-slate-800">
          Current Compensation
        </h2>

        {current_salary ? (
          <div className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">

            <div>
              <p className="text-sm text-slate-500">Annual Base Salary</p>
              <p className="mt-2 text-xl font-bold text-slate-800">
                {formatAmount(
                  current_salary.annual_base_salary,
                  current_salary.currency.code
                )}
              </p>
            </div>

            <div>
              <p className="text-sm text-slate-500">Annual Bonus</p>
              <p className="mt-2 text-xl font-bold text-slate-800">
                {formatAmount(
                  current_salary.annual_bonus,
                  current_salary.currency.code
                )}
              </p>
            </div>

            <div>
              <p className="text-sm text-slate-500">Annual Allowances</p>
              <p className="mt-2 text-xl font-bold text-slate-800">
                {formatAmount(
                  current_salary.annual_allowances,
                  current_salary.currency.code
                )}
              </p>
            </div>

            <div>
              <p className="text-sm text-slate-500">Effective From</p>
              <p className="mt-2 text-xl font-bold text-slate-800">
                {formatDate(current_salary.effective_from)}
              </p>
            </div>

          </div>
        ) : (
          <div className="mt-5 rounded-lg bg-slate-50 p-5">
            <p className="font-medium text-slate-700">
              No current salary assigned
            </p>
            <p className="mt-1 text-sm text-slate-500">
              No salary record is currently effective for this employee.
            </p>
          </div>
        )}
      </div>

      {/* Salary history */}
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <div>
          <h2 className="text-lg font-semibold text-slate-800">
            Salary History
          </h2>

          <p className="mt-1 text-sm text-slate-500">
            Historical compensation records
          </p>
        </div>

        {salary_history.length === 0 ? (
          <div className="mt-5 rounded-lg bg-slate-50 p-8 text-center">
            <p className="font-medium text-slate-700">
              No salary history available
            </p>
            <p className="mt-1 text-sm text-slate-500">
              Salary records will appear here once assigned.
            </p>
          </div>
        ) : (
          <div className="mt-5 overflow-x-auto">
            <table className="w-full min-w-[750px] text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-4 py-3">Effective From</th>
                  <th className="px-4 py-3">Effective To</th>
                  <th className="px-4 py-3">Base Salary</th>
                  <th className="px-4 py-3">Bonus</th>
                  <th className="px-4 py-3">Allowances</th>
                  <th className="px-4 py-3">Change Reason</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {salary_history.map((salary) => (
                  <tr key={salary.id}>
                    <td className="px-4 py-4">
                      {formatDate(salary.effective_from)}
                    </td>

                    <td className="px-4 py-4">
                      {formatDate(salary.effective_to)}
                    </td>

                    <td className="px-4 py-4 font-medium">
                      {formatAmount(
                        salary.annual_base_salary,
                        salary.currency.code
                      )}
                    </td>

                    <td className="px-4 py-4">
                      {formatAmount(
                        salary.annual_bonus,
                        salary.currency.code
                      )}
                    </td>

                    <td className="px-4 py-4">
                      {formatAmount(
                        salary.annual_allowances,
                        salary.currency.code
                      )}
                    </td>

                    <td className="px-4 py-4 text-slate-600">
                      {salary.change_reason || '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

    </div>
  )
}

export default EmployeeDetailsPage
