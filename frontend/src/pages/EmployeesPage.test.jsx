
import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  render,
  screen,
  waitFor,
} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'

import EmployeesPage from './EmployeesPage'
import employeeService from '../services/employeeService'
import referenceDataService from '../services/referenceDataService'

vi.mock('../services/employeeService', () => ({
  default: {
    getEmployees: vi.fn(),
    createEmployee: vi.fn(),
  },
}))

vi.mock('../services/referenceDataService', () => ({
  default: {
    getCountries: vi.fn(),
    getDepartments: vi.fn(),
    getJobTitles: vi.fn(),
  },
}))

vi.mock('../components/employees/EmployeeFormModal', () => ({
  default: () => null,
}))

vi.mock('../components/employees/EmployeeCsvImportModal', () => ({
  default: () => null,
}))

const mockEmployee = {
  id: 1,
  employee_number: 'EMP0001',
  full_name: 'Aarav Sharma',
  email: 'aarav@acme.com',
  employment_status: 'active',
  country: { id: 1, name: 'India' },
  department: { id: 1, name: 'Engineering' },
  job_title: { id: 1, name: 'Software Engineer' },
}

const mockPagination = {
  current_page: 1,
  total_pages: 3,
  total_count: 25,
}

function mockEmployeeResponse(
  employees = [mockEmployee],
  pagination = mockPagination
) {
  return {
    data: employees,
    pagination,
  }
}

function renderEmployeesPage() {
  return render(
    <MemoryRouter>
      <EmployeesPage />
    </MemoryRouter>
  )
}

describe('EmployeesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    employeeService.getEmployees.mockResolvedValue(
      mockEmployeeResponse()
    )

    referenceDataService.getCountries.mockResolvedValue([
      { id: 1, name: 'India' },
      { id: 2, name: 'United States' },
    ])

    referenceDataService.getDepartments.mockResolvedValue([
      { id: 1, name: 'Engineering' },
      { id: 2, name: 'Finance' },
    ])

    referenceDataService.getJobTitles.mockResolvedValue([
      { id: 1, name: 'Software Engineer' },
      { id: 2, name: 'HR Manager' },
    ])
  })

  it('renders the employee directory', async () => {
    renderEmployeesPage()

    expect(
      screen.getByRole('heading', { name: 'Employees' })
    ).toBeInTheDocument()

    expect(
      screen.getByRole('heading', { name: 'Employee Directory' })
    ).toBeInTheDocument()

    expect(
      await screen.findByText('Aarav Sharma')
    ).toBeInTheDocument()

    expect(screen.getByText('aarav@acme.com')).toBeInTheDocument()
    expect(screen.getAllByText('Engineering').length).toBeGreaterThan(0)
    expect(screen.getAllByText('Software Engineer').length).toBeGreaterThan(0)
    expect(screen.getAllByText('India').length).toBeGreaterThan(0)
  })

  it('fetches employees with default pagination and sorting parameters', async () => {
    renderEmployeesPage()

    await screen.findByText('Aarav Sharma')

    await waitFor(() => {
      expect(employeeService.getEmployees).toHaveBeenCalledWith({
        search: '',
        employment_status: '',
        country_id: '',
        department_id: '',
        job_title_id: '',
        sort_by: 'employee_number',
        sort_order: 'asc',
        page: 1,
        per_page: 10,
      })
    })
  })

  it('displays an error when employee loading fails', async () => {
    employeeService.getEmployees.mockRejectedValueOnce({
      response: {
        data: {
          error: 'Unable to fetch employees',
        },
      },
    })

    renderEmployeesPage()

    expect(
      await screen.findByText('Unable to fetch employees')
    ).toBeInTheDocument()
  })

  it('displays an empty state when no employees are found', async () => {
    employeeService.getEmployees.mockResolvedValue(
      mockEmployeeResponse([], {
        current_page: 1,
        total_pages: 0,
        total_count: 0,
      })
    )

    renderEmployeesPage()

    expect(
      await screen.findByText('No employees found.')
    ).toBeInTheDocument()
  })

  it('filters employees by employment status', async () => {
    const user = userEvent.setup()

    renderEmployeesPage()

    await screen.findByText('Aarav Sharma')

    const statusSelect = screen.getAllByRole('combobox')[0]

    await user.selectOptions(statusSelect, 'active')

    await waitFor(() => {
      expect(employeeService.getEmployees).toHaveBeenLastCalledWith(
        expect.objectContaining({
          employment_status: 'active',
          page: 1,
        })
      )
    })
  })

  it('moves to the next page when Next is clicked', async () => {
    const user = userEvent.setup()

    employeeService.getEmployees.mockImplementation(
      async (params) => {
        return mockEmployeeResponse(
          [mockEmployee],
          {
            ...mockPagination,
            current_page: params.page,
          }
        )
      }
    )

    renderEmployeesPage()

    await screen.findByText('Aarav Sharma')

    await user.click(screen.getByRole('button', { name: 'Next' }))

    await waitFor(() => {
      expect(employeeService.getEmployees).toHaveBeenLastCalledWith(
        expect.objectContaining({
          page: 2,
          per_page: 10,
        })
      )
    })

    expect(
      await screen.findByText((_, element) => {
        return (
          element.tagName === 'P' &&
          element.textContent.replace(/\s+/g, ' ').includes('Page 2 of 3')
        )
      })
    ).toBeInTheDocument()
  })


  it('supports debounced employee search', async () => {
    const user = userEvent.setup()

    renderEmployeesPage()

    await screen.findByText('Aarav Sharma')

    const searchInput = screen.getByPlaceholderText(
      'Search name, email or employee number...'
    )

    await user.type(searchInput, 'Aarav')

    await waitFor(
      () => {
        expect(employeeService.getEmployees).toHaveBeenLastCalledWith(
          expect.objectContaining({
            search: 'Aarav',
            page: 1,
          })
        )
      },
      { timeout: 2000 }
    )
  })
})
