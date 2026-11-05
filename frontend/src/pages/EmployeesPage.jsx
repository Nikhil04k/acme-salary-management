import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import employeeService from '../services/employeeService'
import referenceDataService from '../services/referenceDataService'
import EmployeeFormModal from '../components/employees/EmployeeFormModal'
import EmployeeCsvImportModal from '../components/employees/EmployeeCsvImportModal'

function EmployeesPage() {
  const [employees, setEmployees] = useState([])
  const [pagination, setPagination] = useState(null)

  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [sortBy, setSortBy] = useState('employee_number')
  const [sortOrder, setSortOrder] = useState('asc')
  const [page, setPage] = useState(1)

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const [countries, setCountries] = useState([])
  const [departments, setDepartments] = useState([])
  const [jobTitles, setJobTitles] = useState([])

  const [countryId, setCountryId] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [jobTitleId, setJobTitleId] = useState('')

  const [searchInput, setSearchInput] = useState('')

  const [showCreateModal, setShowCreateModal] = useState(false)
  const [successMessage, setSuccessMessage] = useState('')

  const [showImportModal, setShowImportModal] = useState(false)
  const [refreshKey, setRefreshKey] = useState(0)

  const handleCreateEmployee = async (employeeData) => {
    await employeeService.createEmployee(employeeData)

    setShowCreateModal(false)
    setSuccessMessage('Employee created successfully.')

    setPage(1)
    setSearchInput('')
    setSearch('')
    setStatus('')
    setCountryId('')
    setDepartmentId('')
    setJobTitleId('')
    setSortBy('employee_number')
    setSortOrder('asc')
  }

  const handleImportComplete = (result) => {
    setSuccessMessage(
      `CSV import completed: ${result.imported_count} employees imported, ${result.failed_count} rows failed.`
    )

    if (result.imported_count > 0) {
      setRefreshKey((current) => current + 1)
    }
  }

  useEffect(() => {
    const fetchEmployees = async () => {
      setLoading(true)
      setError('')

      try {
        const response = await employeeService.getEmployees({
          search: search.trim(),
          employment_status: status,
          country_id: countryId,
          department_id: departmentId,
          job_title_id: jobTitleId,
          sort_by: sortBy,
          sort_order: sortOrder,
          page,
          per_page: 10,
        })

        setEmployees(response.data)
        setPagination(response.pagination)
      } catch (err) {
        setError(
          err.response?.data?.error ||
          'Unable to load employees. Please try again.'
        )
      } finally {
        setLoading(false)
      }
    }

    fetchEmployees()
  }, [search, status, countryId, departmentId, jobTitleId, sortBy, sortOrder, page, refreshKey])

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
      } catch (error) {
        console.error(
          'Unable to load reference data:',
          error.response?.data || error.message
        )
      }
    }

    fetchReferenceData()
  }, [])

  useEffect(() => {
    const timeout = setTimeout(() => {
      setSearch(searchInput.trim())
      setPage(1)
    }, 400)

    return () => clearTimeout(timeout)
  }, [searchInput])

  const handleSearch = (event) => {
    setSearch(event.target.value)
    setPage(1)
  }

  const handleStatusChange = (event) => {
    setStatus(event.target.value)
    setPage(1)
  }

  const handleSortChange = (event) => {
    setSortBy(event.target.value)
    setPage(1)
  }

  const toggleSortOrder = () => {
    setSortOrder((current) => current === 'asc' ? 'desc' : 'asc')
    setPage(1)
  }

  const statusStyles = {
    active: 'bg-green-50 text-green-700',
    inactive: 'bg-orange-50 text-orange-700',
    terminated: 'bg-red-50 text-red-700',
  }

  return (
    <div className="space-y-6">
      {/* Page heading */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">
            Employees
          </h1>

          <p className="mt-1 text-sm text-slate-500">
            Manage and view all organization employees
          </p>
        </div>

        <div className="flex flex-wrap gap-3">
          <button
            type="button"
            onClick={() => {
              setSuccessMessage('')
              setShowImportModal(true)
            }}
            className="rounded-lg border border-slate-300 bg-white px-5 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
          >
            Import CSV
          </button>

          <button
            type="button"
            onClick={() => {
              setSuccessMessage('')
              setShowCreateModal(true)
            }}
            className="rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-indigo-700"
          >
            + Add Employee
          </button>
        </div>
      </div>

      {successMessage && (
        <div className="flex items-center justify-between rounded-lg bg-green-50 p-4 text-sm text-green-700">
          <span>{successMessage}</span>

          <button
            type="button"
            onClick={() => setSuccessMessage('')}
            className="font-medium"
          >
            ×
          </button>
        </div>
      )}

      {/* Search and filters */}
      <div className="grid grid-cols-1 gap-4 rounded-xl border border-slate-200 bg-white p-5 sm:grid-cols-2 xl:grid-cols-4">

        {/* Search */}
        <input
          type="text"
          value={searchInput}
          onChange={(event) => setSearchInput(event.target.value)}
          placeholder="Search name, email or employee number..."
          className="w-full min-w-0 rounded-lg border border-slate-300 px-4 py-2.5 text-sm outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 sm:col-span-2"
        />

        {/* Status */}
        <select
          value={status}
          onChange={handleStatusChange}
          className="select-control w-full min-w-0 rounded-lg border border-slate-300 px-4 py-2.5 text-sm"
        >
          <option value="">All statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
          <option value="terminated">Terminated</option>
        </select>

        {/* Sorting */}
        <select
          value={sortBy}
          onChange={handleSortChange}
          className="select-control w-full min-w-0 rounded-lg border border-slate-300 px-4 py-2.5 text-sm"
        >
          <option value="employee_number">Employee number</option>
          <option value="first_name">First name</option>
          <option value="last_name">Last name</option>
          <option value="hired_on">Hire date</option>
          <option value="created_at">Created date</option>
        </select>

        {/* Country */}
        <select
          value={countryId}
          onChange={(event) => {
            setCountryId(event.target.value)
            setPage(1)
          }}
          className="select-control w-full min-w-0 rounded-lg border border-slate-300 px-4 py-2.5 text-sm"
        >
          <option value="">All countries</option>
          {countries.map((country) => (
            <option key={country.id} value={country.id}>
              {country.name}
            </option>
          ))}
        </select>

        {/* Department */}
        <select
          value={departmentId}
          onChange={(event) => {
            setDepartmentId(event.target.value)
            setPage(1)
          }}
          className="select-control w-full min-w-0 rounded-lg border border-slate-300 px-4 py-2.5 text-sm"
        >
          <option value="">All departments</option>
          {departments.map((department) => (
            <option key={department.id} value={department.id}>
              {department.name}
            </option>
          ))}
        </select>

        {/* Job Title */}
        <select
          value={jobTitleId}
          onChange={(event) => {
            setJobTitleId(event.target.value)
            setPage(1)
          }}
          className="select-control w-full min-w-0 rounded-lg border border-slate-300 px-4 py-2.5 text-sm"
        >
          <option value="">All job titles</option>
          {jobTitles.map((jobTitle) => (
            <option key={jobTitle.id} value={jobTitle.id}>
              {jobTitle.name}
            </option>
          ))}
        </select>

        {/* Sort Order */}
        <button
          type="button"
          onClick={toggleSortOrder}
          className="w-full rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          {sortOrder === 'asc' ? 'Ascending ↑' : 'Descending ↓'}
        </button>

      </div>

      {/* Employee table */}
      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
        <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
          <h2 className="font-semibold text-slate-800">
            Employee Directory
          </h2>

          <span className="text-sm text-slate-500">
            {pagination?.total_count?.toLocaleString('en-IN') || 0} employees
          </span>
        </div>

        {error && (
          <div className="m-5 rounded-lg bg-red-50 p-4 text-sm text-red-600">
            {error}
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full min-w-[1050px] text-left text-sm">
            <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-5 py-4">Employee</th>
                <th className="px-5 py-4">Email</th>
                <th className="px-5 py-4">Country</th>
                <th className="px-5 py-4">Department</th>
                <th className="px-5 py-4">Job Title</th>
                <th className="px-5 py-4">Status</th>
                <th className="px-5 py-4">Action</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan="7" className="px-5 py-12 text-center text-slate-500">
                    Loading employees...
                  </td>
                </tr>
              ) : employees.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-5 py-12 text-center text-slate-500">
                    No employees found.
                  </td>
                </tr>
              ) : (
                employees.map((employee) => (
                  <tr key={employee.id} className="hover:bg-slate-50">
                    <td className="px-5 py-4">
                      <p className="font-medium text-slate-800">
                        {employee.full_name}
                      </p>
                      <p className="mt-1 whitespace-nowrap text-xs text-slate-500">
                        {employee.employee_number}
                      </p>
                    </td>

                    <td className="whitespace-nowrap px-5 py-4 text-slate-600">
                      {employee.email}
                    </td>

                    <td className="px-5 py-4 text-slate-600">
                      {employee.country?.name}
                    </td>

                    <td className="px-5 py-4 text-slate-600">
                      {employee.department?.name}
                    </td>

                    <td className="px-5 py-4 text-slate-600">
                      {employee.job_title?.name}
                    </td>

                    <td className="px-5 py-4">
                      <span className={`rounded-full px-3 py-1 text-xs font-medium capitalize ${
                        statusStyles[employee.employment_status] ||
                        'bg-slate-100 text-slate-600'
                      }`}>
                        {employee.employment_status}
                      </span>
                    </td>

                    <td className="px-5 py-4">
                      <Link
                        to={`/employees/${employee.id}`}
                        className="whitespace-nowrap font-medium text-blue-600 hover:text-blue-800"
                      >
                        View details
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {pagination && (
          <div className="flex flex-col gap-3 border-t border-slate-200 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-sm text-slate-500">
              Page {pagination.current_page} of {pagination.total_pages}
              {' · '}
              {pagination.total_count.toLocaleString('en-IN')} records
            </p>

            <div className="flex gap-2">
              <button
                type="button"
                disabled={page <= 1 || loading}
                onClick={() => setPage((current) => current - 1)}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
              >
                Previous
              </button>

              <button
                type="button"
                disabled={!pagination || page >= pagination.total_pages || loading}
                onClick={() => setPage((current) => current + 1)}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      <EmployeeFormModal
        open={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSubmit={handleCreateEmployee}
        countries={countries}
        departments={departments}
        jobTitles={jobTitles}
      />

      <EmployeeCsvImportModal
        open={showImportModal}
        onClose={() => setShowImportModal(false)}
        onImportComplete={handleImportComplete}
      />
    </div>
  )
}

export default EmployeesPage
