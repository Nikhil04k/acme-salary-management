
import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import employeeService from '../services/employeeService'
import salaryService from '../services/salaryService'
import SalaryForm from '../components/SalaryForm'
import referenceDataService from '../services/referenceDataService'
import EmployeeFormModal from '../components/employees/EmployeeFormModal'

function EmployeeDetailsPage() {
  const { id } = useParams()

  const [details, setDetails] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // Salary management state
  const [showSalaryForm, setShowSalaryForm] = useState(false)
  const [editingSalary, setEditingSalary] = useState(null)
  const [savingSalary, setSavingSalary] = useState(false)
  const [salaryError, setSalaryError] = useState('')
  const [salarySuccess, setSalarySuccess] = useState('')

  const [showEmployeeForm, setShowEmployeeForm] = useState(false)
  const [savingEmployee, setSavingEmployee] = useState(false)
  const [employeeSuccess, setEmployeeSuccess] = useState('')
  const [employeeError, setEmployeeError] = useState('')

  const [countries, setCountries] = useState([])
  const [departments, setDepartments] = useState([])
  const [jobTitles, setJobTitles] = useState([])

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

  useEffect(() => {
    const fetchReferenceData = async () => {
      try {
        const [countryData, departmentData, jobTitleData] =
          await Promise.all([
            referenceDataService.getCountries(),
            referenceDataService.getDepartments(),
            referenceDataService.getJobTitles(),
          ])

        setCountries(countryData)
        setDepartments(departmentData)
        setJobTitles(jobTitleData)
      } catch (err) {
        console.error(
          'Unable to load reference data:',
          err.response?.data || err.message
        )
      }
    }

    fetchReferenceData()
  }, [])

  const refreshEmployee = async () => {
    const data = await employeeService.getEmployee(id)
    setDetails(data)
  }

  const handleEmployeeUpdate = async (attributes) => {
    setSavingEmployee(true)
    setEmployeeError('')
    setEmployeeSuccess('')

    try {
      await employeeService.updateEmployee(id, attributes)

      await refreshEmployee()

      setShowEmployeeForm(false)
      setEmployeeSuccess('Employee information updated successfully.')
    } catch (err) {
      setEmployeeError(
        err.response?.data?.error ||
        err.response?.data?.message ||
        'Unable to update employee.'
      )

      throw err
    } finally {
      setSavingEmployee(false)
    }
  }

  const handleSalarySubmit = async (attributes) => {
    setSavingSalary(true)
    setSalaryError('')
    setSalarySuccess('')

    try {
      if (editingSalary) {
        await salaryService.updateSalary(
          id,
          editingSalary.id,
          attributes
        )

        setSalarySuccess('Salary record updated successfully.')
      } else {
        await salaryService.createSalary(id, attributes)

        setSalarySuccess('Salary record created successfully.')
      }

      await refreshEmployee()

      setShowSalaryForm(false)
      setEditingSalary(null)
    } catch (err) {
      setSalaryError(
        err.response?.data?.error ||
        err.response?.data?.message ||
        'Unable to save salary record.'
      )
    } finally {
      setSavingSalary(false)
    }
  }

  const handleEditSalary = (salary) => {
    setEditingSalary(salary)
    setSalaryError('')
    setSalarySuccess('')
    setShowSalaryForm(true)
  }

  const handleCancelSalary = async (salary) => {
    const confirmed = window.confirm(
      'Are you sure you want to cancel this scheduled salary record?'
    )

    if (!confirmed) return

    setSalaryError('')
    setSalarySuccess('')

    try {
      await salaryService.cancelSalary(id, salary.id)
      await refreshEmployee()

      setSalarySuccess(
        'Scheduled salary record cancelled successfully.'
      )
    } catch (err) {
      setSalaryError(
        err.response?.data?.error ||
        err.response?.data?.message ||
        'Unable to cancel salary record.'
      )
    }
  }

  const handleCloseSalaryForm = () => {
    setShowSalaryForm(false)
    setEditingSalary(null)
    setSalaryError('')
  }

  if (loading) {
    return (
      <p className="text-slate-500">
        Loading employee details...
      </p>
    )
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

  // ISO date strings can be compared lexicographically.
  // Generate today's date using local time.
  const today = (() => {
    const date = new Date()
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')

    return `${year}-${month}-${day}`
  })()

  return (
    <div className="space-y-6">

      {employeeSuccess && (
        <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">
          {employeeSuccess}
        </div>
      )}

      {employeeError && !showEmployeeForm && (
        <div className="rounded-lg bg-red-50 p-3 text-sm text-red-600">
          {employeeError}
        </div>
      )}

      {/* Salary success message */}
      {salarySuccess && (
        <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">
          {salarySuccess}
        </div>
      )}

      {/* Salary error message */}
      {salaryError && !showSalaryForm && (
        <div className="rounded-lg bg-red-50 p-3 text-sm text-red-600">
          {salaryError}
        </div>
      )}

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

          <div className="flex flex-wrap items-center gap-3">
            <span
              className={`rounded-full px-4 py-2 text-sm font-medium capitalize ${
                statusStyles[employee.employment_status] ||
                'bg-slate-100 text-slate-600'
              }`}
            >
              {employee.employment_status}
            </span>

            <button
              type="button"
              onClick={() => {
                setEmployeeError('')
                setEmployeeSuccess('')
                setShowEmployeeForm(true)
              }}
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              Edit Employee
            </button>
          </div>

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
              <p className="text-sm text-slate-500">
                Annual Base Salary
              </p>
              <p className="mt-2 text-xl font-bold text-slate-800">
                {formatAmount(
                  current_salary.annual_base_salary,
                  current_salary.currency.code
                )}
              </p>
            </div>

            <div>
              <p className="text-sm text-slate-500">
                Annual Bonus
              </p>
              <p className="mt-2 text-xl font-bold text-slate-800">
                {formatAmount(
                  current_salary.annual_bonus,
                  current_salary.currency.code
                )}
              </p>
            </div>

            <div>
              <p className="text-sm text-slate-500">
                Annual Allowances
              </p>
              <p className="mt-2 text-xl font-bold text-slate-800">
                {formatAmount(
                  current_salary.annual_allowances,
                  current_salary.currency.code
                )}
              </p>
            </div>

            <div>
              <p className="text-sm text-slate-500">
                Effective From
              </p>
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

        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-lg font-semibold text-slate-800">
              Salary History
            </h2>

            <p className="mt-1 text-sm text-slate-500">
              Historical and scheduled compensation records
            </p>
          </div>

          <button
            type="button"
            onClick={() => {
              setEditingSalary(null)
              setSalaryError('')
              setSalarySuccess('')
              setShowSalaryForm(true)
            }}
            className="rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700"
          >
            + Add Salary
          </button>
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
            <table className="w-full min-w-[900px] text-left text-sm">

              <thead className="bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-4 py-3">Effective From</th>
                  <th className="px-4 py-3">Effective To</th>
                  <th className="px-4 py-3">Base Salary</th>
                  <th className="px-4 py-3">Bonus</th>
                  <th className="px-4 py-3">Allowances</th>
                  <th className="px-4 py-3">Change Reason</th>
                  <th className="px-4 py-3">Actions</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {salary_history.map((salary) => {
                  const isFutureSalary = salary.effective_from > today

                  return (
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

                      <td className="px-4 py-4">
                        {isFutureSalary ? (
                          <div className="flex items-center gap-3">
                            <button
                              type="button"
                              onClick={() => handleEditSalary(salary)}
                              className="font-medium text-indigo-600 hover:text-indigo-800"
                            >
                              Edit
                            </button>

                            <button
                              type="button"
                              onClick={() => handleCancelSalary(salary)}
                              className="font-medium text-red-600 hover:text-red-800"
                            >
                              Cancel
                            </button>
                          </div>
                        ) : (
                          <span className="text-slate-400">—</span>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>

            </table>
          </div>
        )}
      </div>

      {/* Salary form modal */}
      {showSalaryForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-white p-6 shadow-xl">

            <div className="mb-6 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-800">
                {editingSalary ? 'Edit Salary' : 'Add Salary'}
              </h2>

              <button
                type="button"
                onClick={handleCloseSalaryForm}
                disabled={savingSalary}
                className="text-2xl text-slate-400 hover:text-slate-700 disabled:opacity-50"
              >
                &times;
              </button>
            </div>

            {salaryError && (
              <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-600">
                {salaryError}
              </div>
            )}

            <SalaryForm
              initialData={editingSalary}
              onSubmit={handleSalarySubmit}
              onCancel={handleCloseSalaryForm}
              loading={savingSalary}
            />

          </div>
        </div>
      )}
      <EmployeeFormModal
        open={showEmployeeForm}
        onClose={() => {
          setShowEmployeeForm(false)
          setEmployeeError('')
        }}
        onSubmit={handleEmployeeUpdate}
        countries={countries}
        departments={departments}
        jobTitles={jobTitles}
        initialData={employee}
      />
    </div>
  )
}

export default EmployeeDetailsPage
