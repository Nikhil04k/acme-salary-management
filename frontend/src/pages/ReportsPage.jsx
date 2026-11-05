
import { useEffect, useState } from 'react'
import employeeService from '../services/employeeService'
import referenceDataService from '../services/referenceDataService'

function ReportsPage() {
  const [employees, setEmployees] = useState([])
  const [pagination, setPagination] = useState({
    current_page: 1,
    per_page: 20,
    total_pages: 0,
    total_count: 0,
  })

  const [countries, setCountries] = useState([])
  const [departments, setDepartments] = useState([])
  const [jobTitles, setJobTitles] = useState([])

  const [filters, setFilters] = useState({
    search: '',
    country_id: '',
    department_id: '',
    job_title_id: '',
    employment_status: '',
  })

  const [loading, setLoading] = useState(true)
  const [exporting, setExporting] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    const loadReferenceData = async () => {
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
        setError(
          err.response?.data?.error ||
          'Unable to load report filters'
        )
      }
    }

    loadReferenceData()
  }, [])

  const fetchEmployees = async (page = 1, currentFilters = filters) => {
    setLoading(true)
    setError('')

    try {
      const response = await employeeService.getEmployees({
        ...currentFilters,
        page,
        per_page: 20,
      })

      setEmployees(response.data)
      setPagination(response.pagination)
    } catch (err) {
      setError(
        err.response?.data?.error ||
        'Unable to load employee report'
      )
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchEmployees(1)
  }, [])

  const handleFilterChange = (event) => {
    const { name, value } = event.target

    setFilters((previous) => ({
      ...previous,
      [name]: value,
    }))
  }

  const handleApplyFilters = () => {
    fetchEmployees(1, filters)
  }

  const handleResetFilters = () => {
    const emptyFilters = {
      search: '',
      country_id: '',
      department_id: '',
      job_title_id: '',
      employment_status: '',
    }

    setFilters(emptyFilters)
    fetchEmployees(1, emptyFilters)
  }

  const handleExport = async () => {
    setExporting(true)
    setError('')

    try {
      const blob = await employeeService.exportEmployees(filters)

      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')

      link.href = url
      link.download = 'acme_employee_report.csv'

      document.body.appendChild(link)
      link.click()
      link.remove()

      window.URL.revokeObjectURL(url)
    } catch (err) {
      setError(
        err.response?.data?.error ||
        'Unable to export employee report'
      )
    } finally {
      setExporting(false)
    }
  }

  const formatDate = (date) => {
    if (!date) return '—'

    return new Date(`${date}T00:00:00`).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    })
  }

  const inputClass =
    'w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100'

  return (
    <div className="space-y-6">

      {/* Page heading */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">
            Reports
          </h1>

          <p className="mt-1 text-sm text-slate-500">
            Employee and compensation reports
          </p>
        </div>

        <button
          type="button"
          onClick={handleExport}
          disabled={exporting || loading}
          className="rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
        >
          {exporting ? 'Exporting...' : 'Export CSV'}
        </button>
      </div>

      {/* Report summary */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <p className="text-sm text-slate-500">
            Matching Employees
          </p>

          <p className="mt-2 text-2xl font-bold text-slate-800">
            {Number(pagination.total_count).toLocaleString('en-IN')}
          </p>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <p className="text-sm text-slate-500">
            Current Page
          </p>

          <p className="mt-2 text-2xl font-bold text-slate-800">
            {pagination.current_page} / {pagination.total_pages}
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="rounded-xl border border-slate-200 bg-white p-6">
        <div className="mb-5">
          <h2 className="text-lg font-semibold text-slate-800">
            Employee Report Filters
          </h2>

          <p className="mt-1 text-sm text-slate-500">
            Filter employees by country, department, job title and status
          </p>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">

          <div>
            <label className="mb-1.5 block text-sm font-medium text-slate-700">
              Search
            </label>

            <input
              type="text"
              name="search"
              value={filters.search}
              onChange={handleFilterChange}
              onKeyDown={(event) => {
                if (event.key === 'Enter') handleApplyFilters()
              }}
              placeholder="Name, email or employee number"
              className={inputClass}
            />
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-slate-700">
              Country
            </label>

            <select
              name="country_id"
              value={filters.country_id}
              onChange={handleFilterChange}
              className={inputClass}
            >
              <option value="">All Countries</option>

              {countries.map((country) => (
                <option key={country.id} value={country.id}>
                  {country.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-slate-700">
              Department
            </label>

            <select
              name="department_id"
              value={filters.department_id}
              onChange={handleFilterChange}
              className={inputClass}
            >
              <option value="">All Departments</option>

              {departments.map((department) => (
                <option key={department.id} value={department.id}>
                  {department.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-slate-700">
              Job Title
            </label>

            <select
              name="job_title_id"
              value={filters.job_title_id}
              onChange={handleFilterChange}
              className={inputClass}
            >
              <option value="">All Job Titles</option>

              {jobTitles.map((jobTitle) => (
                <option key={jobTitle.id} value={jobTitle.id}>
                  {jobTitle.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-slate-700">
              Employment Status
            </label>

            <select
              name="employment_status"
              value={filters.employment_status}
              onChange={handleFilterChange}
              className={inputClass}
            >
              <option value="">All Statuses</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="terminated">Terminated</option>
            </select>
          </div>

        </div>

        <div className="mt-5 flex flex-wrap gap-3">
          <button
            type="button"
            onClick={handleApplyFilters}
            disabled={loading}
            className="rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
          >
            Apply Filters
          </button>

          <button
            type="button"
            onClick={handleResetFilters}
            className="rounded-lg border border-slate-300 px-5 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50"
          >
            Reset
          </button>
        </div>
      </div>

      {/* Error message */}
      {error && (
        <div className="rounded-lg bg-red-50 p-4 text-sm text-red-600">
          {error}
        </div>
      )}

      {/* Employee report table */}
      <div className="rounded-xl border border-slate-200 bg-white p-6">

        <div className="mb-5">
          <h2 className="text-lg font-semibold text-slate-800">
            Employee Report
          </h2>

          <p className="mt-1 text-sm text-slate-500">
            Detailed employee records matching your filters
          </p>
        </div>

        {loading ? (
          <div className="py-10 text-center text-slate-500">
            Loading employee report...
          </div>
        ) : employees.length === 0 ? (
          <div className="rounded-lg bg-slate-50 p-8 text-center">
            <p className="font-medium text-slate-700">
              No employees found
            </p>

            <p className="mt-1 text-sm text-slate-500">
              Try changing your report filters.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1100px] text-left text-sm">

              <thead className="bg-slate-50 text-xs uppercase text-slate-500">
                <tr>
                  <th className="px-4 py-3">Employee No.</th>
                  <th className="px-4 py-3">Employee</th>
                  <th className="px-4 py-3">Email</th>
                  <th className="px-4 py-3">Country</th>
                  <th className="px-4 py-3">Department</th>
                  <th className="px-4 py-3">Job Title</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3">Hire Date</th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {employees.map((employee) => (
                  <tr key={employee.id} className="hover:bg-slate-50">

                    <td className="px-4 py-4 font-medium text-slate-800">
                      {employee.employee_number}
                    </td>

                    <td className="px-4 py-4 font-medium text-slate-800">
                      {employee.full_name}
                    </td>

                    <td className="px-4 py-4 text-slate-600">
                      {employee.email}
                    </td>

                    <td className="px-4 py-4">
                      {employee.country?.name || '—'}
                    </td>

                    <td className="px-4 py-4">
                      {employee.department?.name || '—'}
                    </td>

                    <td className="px-4 py-4">
                      {employee.job_title?.name || '—'}
                    </td>

                    <td className="px-4 py-4">
                      <span
                        className={`rounded-full px-3 py-1 text-xs font-medium capitalize ${
                          employee.employment_status === 'active'
                            ? 'bg-green-50 text-green-700'
                            : employee.employment_status === 'inactive'
                              ? 'bg-orange-50 text-orange-700'
                              : 'bg-red-50 text-red-700'
                        }`}
                      >
                        {employee.employment_status}
                      </span>
                    </td>

                    <td className="px-4 py-4 text-slate-600">
                      {formatDate(employee.hired_on)}
                    </td>

                  </tr>
                ))}
              </tbody>

            </table>
          </div>
        )}

        {/* Pagination */}
        {!loading && employees.length > 0 && (
          <div className="mt-5 flex flex-col gap-4 border-t border-slate-100 pt-5 sm:flex-row sm:items-center sm:justify-between">

            <p className="text-sm text-slate-500">
              Showing page {pagination.current_page} of {pagination.total_pages}
              {' '}({Number(pagination.total_count).toLocaleString('en-IN')} employees)
            </p>

            <div className="flex gap-2">
              <button
                type="button"
                disabled={pagination.current_page <= 1}
                onClick={() => fetchEmployees(pagination.current_page - 1)}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
              >
                Previous
              </button>

              <button
                type="button"
                disabled={pagination.current_page >= pagination.total_pages}
                onClick={() => fetchEmployees(pagination.current_page + 1)}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
              >
                Next
              </button>
            </div>

          </div>
        )}

      </div>
    </div>
  )
}

export default ReportsPage
