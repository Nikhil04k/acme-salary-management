import { useEffect, useState } from 'react'
import referenceDataService from '../services/referenceDataService'

const initialForm = {
  annual_base_salary: '',
  annual_bonus: '0',
  annual_allowances: '0',
  currency_code: 'INR',
  effective_from: '',
  change_reason: '',
}

function SalaryForm({
  initialData = null,
  onSubmit,
  onCancel,
  loading = false,
}) {
  const [form, setForm] = useState(initialForm)
  const [currencies, setCurrencies] = useState([])
  const [errors, setErrors] = useState({})
  const [currencyLoading, setCurrencyLoading] = useState(true)

  useEffect(() => {
    const loadCurrencies = async () => {
      try {
        const data = await referenceDataService.getCurrencies()
        setCurrencies(data)
      } catch (error) {
        console.error('Failed to load currencies:', error)
      } finally {
        setCurrencyLoading(false)
      }
    }

    loadCurrencies()
  }, [])

  useEffect(() => {
    if (initialData) {
      setForm({
        annual_base_salary: initialData.annual_base_salary ?? '',
        annual_bonus: initialData.annual_bonus ?? '0',
        annual_allowances: initialData.annual_allowances ?? '0',
        currency_code: initialData.currency?.code ?? 'INR',
        effective_from: initialData.effective_from ?? '',
        change_reason: initialData.change_reason ?? '',
      })
    } else {
      setForm(initialForm)
    }
  }, [initialData])

  const selectedCurrency = currencies.find(
    (currency) => currency.code === form.currency_code
  )

  const decimalPlaces = selectedCurrency?.decimal_places ?? 2
  const step = decimalPlaces === 0
    ? '1'
    : `0.${'0'.repeat(decimalPlaces - 1)}1`

  const handleChange = (event) => {
    const { name, value } = event.target

    setForm((previous) => ({
      ...previous,
      [name]: value,
    }))

    setErrors((previous) => ({
      ...previous,
      [name]: '',
    }))
  }

  const validate = () => {
    const newErrors = {}

    if (!form.annual_base_salary || Number(form.annual_base_salary) <= 0) {
      newErrors.annual_base_salary = 'Enter a valid annual base salary.'
    }

    for (const field of ['annual_bonus', 'annual_allowances']) {
      if (form[field] === '' || Number(form[field]) < 0) {
        newErrors[field] = 'Enter a valid non-negative amount.'
      }
    }

    if (!form.currency_code) {
      newErrors.currency_code = 'Select a currency.'
    }

    if (!form.effective_from) {
      newErrors.effective_from = 'Select an effective date.'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (event) => {
    event.preventDefault()

    if (!validate()) return

    onSubmit({
      ...form,
      annual_base_salary: Number(form.annual_base_salary),
      annual_bonus: Number(form.annual_bonus),
      annual_allowances: Number(form.annual_allowances),
    })
  }

  const inputClass =
    'w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100'

  const renderError = (field) =>
    errors[field] && (
      <p className="mt-1 text-xs text-red-600">{errors[field]}</p>
    )

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            Annual Base Salary *
          </label>
          <input
            type="number"
            name="annual_base_salary"
            value={form.annual_base_salary}
            onChange={handleChange}
            min="0"
            step={step}
            className={inputClass}
            placeholder="e.g. 1200000"
          />
          {renderError('annual_base_salary')}
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            Annual Bonus
          </label>
          <input
            type="number"
            name="annual_bonus"
            value={form.annual_bonus}
            onChange={handleChange}
            min="0"
            step={step}
            className={inputClass}
          />
          {renderError('annual_bonus')}
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            Annual Allowances
          </label>
          <input
            type="number"
            name="annual_allowances"
            value={form.annual_allowances}
            onChange={handleChange}
            min="0"
            step={step}
            className={inputClass}
          />
          {renderError('annual_allowances')}
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            Currency *
          </label>
          <select
            name="currency_code"
            value={form.currency_code}
            onChange={handleChange}
            disabled={currencyLoading}
            className={inputClass}
          >
            {currencies.map((currency) => (
              <option key={currency.code} value={currency.code}>
                {currency.code} - {currency.name}
              </option>
            ))}
          </select>
          {renderError('currency_code')}
        </div>

        <div>
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            Effective From *
          </label>
          <input
            type="date"
            name="effective_from"
            value={form.effective_from}
            onChange={handleChange}
            className={inputClass}
          />
          {renderError('effective_from')}
        </div>

        <div className="sm:col-span-2">
          <label className="mb-1.5 block text-sm font-medium text-gray-700">
            Change Reason
          </label>
          <textarea
            name="change_reason"
            value={form.change_reason}
            onChange={handleChange}
            rows={3}
            className={inputClass}
            placeholder="e.g. Annual salary revision"
          />
        </div>
      </div>

      <div className="flex justify-end gap-3 border-t border-gray-100 pt-4">
        <button
          type="button"
          onClick={onCancel}
          disabled={loading}
          className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Cancel
        </button>

        <button
          type="submit"
          disabled={loading || currencyLoading}
          className="rounded-lg bg-indigo-600 px-5 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
        >
          {loading ? 'Saving...' : initialData ? 'Update Salary' : 'Add Salary'}
        </button>
      </div>
    </form>
  )
}

export default SalaryForm
