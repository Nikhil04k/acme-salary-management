
import { useState } from 'react'
import employeeService from '../../services/employeeService'

const CSV_HEADERS = [
  'employee_number',
  'first_name',
  'last_name',
  'email',
  'country_code',
  'department',
  'job_title',
  'employment_status',
  'hired_on',
  'terminated_on',
]

function downloadCsvTemplate() {
  const csvContent = `${CSV_HEADERS.join(',')}\n`
  const blob = new Blob([csvContent], {
    type: 'text/csv;charset=utf-8;',
  })

  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')

  link.href = url
  link.download = 'acme_employees_template.csv'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)

  URL.revokeObjectURL(url)
}

function EmployeeCsvImportModal({ open, onClose, onImportComplete }) {
  const [file, setFile] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [result, setResult] = useState(null)

  if (!open) return null

  const handleFileChange = (event) => {
    const selectedFile = event.target.files?.[0]

    setError('')
    setResult(null)

    if (!selectedFile) {
      setFile(null)
      return
    }

    if (!selectedFile.name.toLowerCase().endsWith('.csv')) {
      setFile(null)
      setError('Please select a CSV file.')
      event.target.value = ''
      return
    }

    if (selectedFile.size === 0) {
      setFile(null)
      setError('The selected CSV file is empty.')
      event.target.value = ''
      return
    }

    setFile(selectedFile)
  }

  const handleImport = async () => {
    if (!file) {
      setError('Please select a CSV file first.')
      return
    }

    setLoading(true)
    setError('')
    setResult(null)

    try {
      const response = await employeeService.importEmployees(file)
      const importResult = response.data

      setResult(importResult)
      onImportComplete?.(importResult)
    } catch (err) {
      setError(
        err.response?.data?.error ||
        err.response?.data?.message ||
        'Unable to import employees. Please try again.'
      )
    } finally {
      setLoading(false)
    }
  }

  const handleClose = () => {
    if (loading) return

    setFile(null)
    setError('')
    setResult(null)
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4">
      <div className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold text-slate-800">
              Import Employees
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              Upload a CSV file to add multiple employees.
            </p>
          </div>

          <button
            type="button"
            onClick={handleClose}
            disabled={loading}
            className="text-2xl leading-none text-slate-400 hover:text-slate-700 disabled:opacity-40"
            aria-label="Close"
          >
            ×
          </button>
        </div>

        <div className="space-y-5 p-6">
          <div className="rounded-lg border border-indigo-100 bg-indigo-50 p-4">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-sm font-medium text-indigo-900">
                  CSV template
                </p>
                <p className="mt-1 text-xs text-indigo-700">
                  Use the exact column names and order required by the system.
                </p>
              </div>

              <button
                type="button"
                onClick={downloadCsvTemplate}
                className="shrink-0 rounded-lg border border-indigo-200 bg-white px-4 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-100"
              >
                Download template
              </button>
            </div>
          </div>

          <div>
            <label
              htmlFor="employee-csv-file"
              className="mb-2 block text-sm font-medium text-slate-700"
            >
              Select CSV file
            </label>

            <input
              id="employee-csv-file"
              type="file"
              accept=".csv,text/csv"
              onChange={handleFileChange}
              disabled={loading || Boolean(result)}
              className="block w-full rounded-lg border border-slate-300 text-sm text-slate-600 file:mr-4 file:border-0 file:bg-slate-100 file:px-4 file:py-3 file:text-sm file:font-medium file:text-slate-700 hover:file:bg-slate-200"
            />

            {file && (
              <p className="mt-2 text-sm text-slate-500">
                Selected: <span className="font-medium">{file.name}</span>
                {' '}({(file.size / 1024).toFixed(1)} KB)
              </p>
            )}
          </div>

          <div className="rounded-lg bg-slate-50 p-4">
            <p className="text-sm font-medium text-slate-700">
              Important instructions
            </p>
            <ul className="mt-2 list-disc space-y-1 pl-5 text-xs text-slate-600">
              <li>Employee number and email must be unique.</li>
              <li>Country code must match an existing country.</li>
              <li>Department and job title must match existing records.</li>
              <li>Employment status must be active, inactive, or terminated.</li>
              <li>Leave last name and termination date empty when not applicable.</li>
              <li>Existing employees will not be overwritten.</li>
            </ul>
          </div>

          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">
              {error}
            </div>
          )}

          {result && (
            <div className="space-y-4">
              <div className="rounded-lg border border-slate-200 p-4">
                <p className="font-semibold text-slate-800">
                  Import completed
                </p>

                <div className="mt-3 grid grid-cols-3 gap-3">
                  <div className="rounded-lg bg-slate-50 p-3">
                    <p className="text-xs text-slate-500">Total rows</p>
                    <p className="mt-1 text-xl font-semibold text-slate-800">
                      {result.total_rows}
                    </p>
                  </div>

                  <div className="rounded-lg bg-green-50 p-3">
                    <p className="text-xs text-green-700">Imported</p>
                    <p className="mt-1 text-xl font-semibold text-green-700">
                      {result.imported_count}
                    </p>
                  </div>

                  <div className="rounded-lg bg-red-50 p-3">
                    <p className="text-xs text-red-700">Failed</p>
                    <p className="mt-1 text-xl font-semibold text-red-700">
                      {result.failed_count}
                    </p>
                  </div>
                </div>
              </div>

              {result.errors?.length > 0 && (
                <div>
                  <h3 className="mb-2 text-sm font-semibold text-slate-800">
                    Failed rows
                  </h3>

                  <div className="max-h-60 overflow-auto rounded-lg border border-slate-200">
                    <table className="w-full min-w-[450px] text-left text-sm">
                      <thead className="sticky top-0 bg-slate-50 text-xs uppercase text-slate-500">
                        <tr>
                          <th className="px-3 py-3">Row</th>
                          <th className="px-3 py-3">Employee number</th>
                          <th className="px-3 py-3">Errors</th>
                        </tr>
                      </thead>

                      <tbody className="divide-y divide-slate-100">
                        {result.errors.map((rowError, index) => (
                          <tr key={`${rowError.row}-${index}`}>
                            <td className="px-3 py-3 text-slate-600">
                              {rowError.row}
                            </td>
                            <td className="px-3 py-3 text-slate-600">
                              {rowError.employee_number || '—'}
                            </td>
                            <td className="px-3 py-3 text-red-600">
                              <ul className="list-disc space-y-1 pl-4">
                                {rowError.errors.map((message, errorIndex) => (
                                  <li key={errorIndex}>{message}</li>
                                ))}
                              </ul>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        <div className="flex flex-col-reverse gap-3 border-t border-slate-200 px-6 py-4 sm:flex-row sm:justify-end">
          <button
            type="button"
            onClick={handleClose}
            disabled={loading}
            className="rounded-lg border border-slate-300 px-5 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
          >
            {result ? 'Close' : 'Cancel'}
          </button>

          {!result && (
            <button
              type="button"
              onClick={handleImport}
              disabled={!file || loading}
              className="rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loading ? 'Importing...' : 'Import Employees'}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

export default EmployeeCsvImportModal
