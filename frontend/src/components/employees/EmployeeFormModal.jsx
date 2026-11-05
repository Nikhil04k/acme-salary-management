
import { useEffect, useState } from 'react'

const initialForm = {
  employee_number: '',
  first_name: '',
  last_name: '',
  email: '',
  country_id: '',
  department_id: '',
  job_title_id: '',
  employment_status: 'active',
  hired_on: '',
  terminated_on: '',
}

function EmployeeFormModal({
  open,
  onClose,
  onSubmit,
  countries,
  departments,
  jobTitles,
  initialData = null,
}) {
  const [form, setForm] = useState(initialForm)
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState('')

  const isEditing = Boolean(initialData)

  useEffect(() => {
    if (!open) return

    setForm(
      initialData
        ? {
            employee_number: initialData.employee_number || '',
            first_name: initialData.first_name || '',
            last_name: initialData.last_name || '',
            email: initialData.email || '',
            country_id: String(initialData.country?.id || ''),
            department_id: String(initialData.department?.id || ''),
            job_title_id: String(initialData.job_title?.id || ''),
            employment_status: initialData.employment_status || 'active',
            hired_on: initialData.hired_on || '',
            terminated_on: initialData.terminated_on || '',
          }
        : initialForm
    )

    setErrors({})
    setSubmitError('')
    setSubmitting(false)
  }, [open, initialData])

  if (!open) return null

  const handleChange = (event) => {
    const { name, value } = event.target

    setForm((previous) => ({
      ...previous,
      [name]: value,
      ...(name === 'employment_status' && value !== 'terminated'
        ? { terminated_on: '' }
        : {}),
    }))

    setErrors((previous) => ({
      ...previous,
      [name]: '',
    }))
  }

  const validate = () => {
    const nextErrors = {}

    if (!form.employee_number.trim()) {
      nextErrors.employee_number = 'Employee number is required'
    }

    if (!form.first_name.trim()) {
      nextErrors.first_name = 'First name is required'
    }

    if (!form.email.trim()) {
      nextErrors.email = 'Email is required'
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
      nextErrors.email = 'Enter a valid email address'
    }

    if (!form.country_id) {
      nextErrors.country_id = 'Please select a country'
    }

    if (!form.department_id) {
      nextErrors.department_id = 'Please select a department'
    }

    if (!form.job_title_id) {
      nextErrors.job_title_id = 'Please select a job title'
    }

    if (!form.hired_on) {
      nextErrors.hired_on = 'Hire date is required'
    }

    if (
      form.employment_status === 'terminated' &&
      !form.terminated_on
    ) {
      nextErrors.terminated_on = 'Termination date is required'
    }

    if (
      form.terminated_on &&
      form.hired_on &&
      form.terminated_on < form.hired_on
    ) {
      nextErrors.terminated_on =
        'Termination date cannot be before hire date'
    }

    setErrors(nextErrors)

    return Object.keys(nextErrors).length === 0
  }

  const handleSubmit = async (event) => {
    event.preventDefault()

    if (!validate()) return

    setSubmitting(true)
    setSubmitError('')

    try {
      const payload = {
        ...form,
        employee_number: form.employee_number.trim(),
        first_name: form.first_name.trim(),
        last_name: form.last_name.trim() || null,
        email: form.email.trim(),
        country_id: Number(form.country_id),
        department_id: Number(form.department_id),
        job_title_id: Number(form.job_title_id),
        terminated_on: form.terminated_on || null,
      }

      await onSubmit(payload)
      onClose()
    } catch (error) {
      const responseData = error.response?.data

      if (responseData?.errors && typeof responseData.errors === 'object') {
        setErrors(responseData.errors)
      } else {
        setSubmitError(
          responseData?.error ||
          responseData?.message ||
          `Unable to ${isEditing ? 'update' : 'create'} employee. Please try again.`
        )
      }
    } finally {
      setSubmitting(false)
    }
  }

  const inputClass =
    'w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100'

  const renderError = (name) => {
    if (!errors[name]) return null

    return (
      <p className="mt-1 text-xs text-red-600">
        {Array.isArray(errors[name])
          ? errors[name].join(', ')
          : errors[name]}
      </p>
    )
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !submitting) {
          onClose()
        }
      }}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="employee-form-title"
        className="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-2xl bg-white shadow-xl"
      >
        <div className="sticky top-0 z-10 flex items-center justify-between border-b border-slate-200 bg-white px-6 py-4">
          <div>
            <h2
              id="employee-form-title"
              className="text-xl font-bold text-slate-800"
            >
              {isEditing ? 'Edit Employee' : 'Add Employee'}
            </h2>

            <p className="mt-1 text-sm text-slate-500">
              {isEditing
                ? 'Update employee information'
                : "Enter the employee's information"}
            </p>
          </div>

          <button
            type="button"
            onClick={onClose}
            disabled={submitting}
            aria-label="Close"
            className="rounded-lg px-3 py-2 text-xl text-slate-500 hover:bg-slate-100 disabled:opacity-50"
          >
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="space-y-6 p-6">
            {submitError && (
              <div className="rounded-lg bg-red-50 p-4 text-sm text-red-600">
                {submitError}
              </div>
            )}

            <section>
              <h3 className="mb-4 text-sm font-semibold text-slate-800">
                Personal Information
              </h3>

              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    Employee Number *
                  </label>

                  <input
                    name="employee_number"
                    value={form.employee_number}
                    onChange={handleChange}
                    className={inputClass}
                  />

                  {renderError('employee_number')}
                </div>

                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    Email *
                  </label>

                  <input
                    type="email"
                    name="email"
                    value={form.email}
                    onChange={handleChange}
                    className={inputClass}
                  />

                  {renderError('email')}
                </div>

                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    First Name *
                  </label>

                  <input
                    name="first_name"
                    value={form.first_name}
                    onChange={handleChange}
                    className={inputClass}
                  />

                  {renderError('first_name')}
                </div>

                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    Last Name
                  </label>

                  <input
                    name="last_name"
                    value={form.last_name}
                    onChange={handleChange}
                    className={inputClass}
                  />

                  {renderError('last_name')}
                </div>
              </div>
            </section>

            <section>
              <h3 className="mb-4 text-sm font-semibold text-slate-800">
                Organization Information
              </h3>

              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    Country *
                  </label>

                  <select
                    name="country_id"
                    value={form.country_id}
                    onChange={handleChange}
                    className={inputClass}
                  >
                    <option value="">Select country</option>

                    {countries.map((country) => (
                      <option key={country.id} value={country.id}>
                        {country.name}
                      </option>
                    ))}
                  </select>

                  {renderError('country_id')}
                </div>

                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    Department *
                  </label>

                  <select
                    name="department_id"
                    value={form.department_id}
                    onChange={handleChange}
                    className={inputClass}
                  >
                    <option value="">Select department</option>

                    {departments.map((department) => (
                      <option key={department.id} value={department.id}>
                        {department.name}
                      </option>
                    ))}
                  </select>

                  {renderError('department_id')}
                </div>

                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    Job Title *
                  </label>

                  <select
                    name="job_title_id"
                    value={form.job_title_id}
                    onChange={handleChange}
                    className={inputClass}
                  >
                    <option value="">Select job title</option>

                    {jobTitles.map((jobTitle) => (
                      <option key={jobTitle.id} value={jobTitle.id}>
                        {jobTitle.name}
                      </option>
                    ))}
                  </select>

                  {renderError('job_title_id')}
                </div>
              </div>
            </section>

            <section>
              <h3 className="mb-4 text-sm font-semibold text-slate-800">
                Employment Information
              </h3>

              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    Employment Status *
                  </label>

                  <select
                    name="employment_status"
                    value={form.employment_status}
                    onChange={handleChange}
                    className={inputClass}
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="terminated">Terminated</option>
                  </select>
                </div>

                <div>
                  <label className="mb-1.5 block text-sm font-medium text-slate-700">
                    Hire Date *
                  </label>

                  <input
                    type="date"
                    name="hired_on"
                    value={form.hired_on}
                    onChange={handleChange}
                    className={inputClass}
                  />

                  {renderError('hired_on')}
                </div>

                {form.employment_status === 'terminated' && (
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-slate-700">
                      Termination Date *
                    </label>

                    <input
                      type="date"
                      name="terminated_on"
                      value={form.terminated_on}
                      onChange={handleChange}
                      className={inputClass}
                    />

                    {renderError('terminated_on')}
                  </div>
                )}
              </div>
            </section>

            <p className="text-xs text-slate-500">
              * Required fields
            </p>
          </div>

          <div className="flex flex-col-reverse gap-3 border-t border-slate-200 bg-slate-50 px-6 py-4 sm:flex-row sm:justify-end">
            <button
              type="button"
              onClick={onClose}
              disabled={submitting}
              className="rounded-lg border border-slate-300 px-5 py-2.5 text-sm font-medium text-slate-700 hover:bg-white disabled:opacity-50"
            >
              Cancel
            </button>

            <button
              type="submit"
              disabled={submitting}
              className="rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
            >
              {submitting
                ? isEditing ? 'Updating...' : 'Creating...'
                : isEditing ? 'Update Employee' : 'Create Employee'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default EmployeeFormModal
