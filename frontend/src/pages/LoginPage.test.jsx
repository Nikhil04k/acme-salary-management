
import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  render,
  screen,
  fireEvent,
  waitFor,
} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'

import LoginPage from './LoginPage'
import { useAuth } from '../context/AuthContext'

vi.mock('../context/AuthContext', () => ({
  useAuth: vi.fn(),
}))

function renderLoginPage() {
  return render(
    <MemoryRouter initialEntries={['/']}>
      <Routes>
        <Route path="/" element={<LoginPage />} />
        <Route
          path="/dashboard"
          element={<h1>Dashboard page</h1>}
        />
      </Routes>
    </MemoryRouter>
  )
}

describe('LoginPage', () => {
  const mockLogin = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()

    useAuth.mockReturnValue({
      login: mockLogin,
    })
  })

  it('renders the login page correctly', () => {
    renderLoginPage()

    expect(
      screen.getByRole('heading', { name: 'Welcome back' })
    ).toBeInTheDocument()

    expect(screen.getByLabelText('Email address')).toBeInTheDocument()
    expect(screen.getByLabelText('Password')).toBeInTheDocument()

    expect(
      screen.getByRole('button', { name: 'Sign in' })
    ).toBeInTheDocument()
  })

  it('shows a validation error when fields are empty', () => {
    renderLoginPage()

    const form = screen.getByRole('button', {
      name: 'Sign in',
    }).closest('form')

    fireEvent.submit(form)

    expect(
      screen.getByText('Email and password are required')
    ).toBeInTheDocument()

    expect(mockLogin).not.toHaveBeenCalled()
  })

  it('toggles password visibility', async () => {
    const user = userEvent.setup()

    renderLoginPage()

    const passwordInput = screen.getByLabelText('Password')

    expect(passwordInput).toHaveAttribute('type', 'password')

    await user.click(screen.getByRole('button', { name: 'Show' }))

    expect(passwordInput).toHaveAttribute('type', 'text')

    await user.click(screen.getByRole('button', { name: 'Hide' }))

    expect(passwordInput).toHaveAttribute('type', 'password')
  })

  it('logs in successfully and navigates to dashboard', async () => {
    const user = userEvent.setup()

    mockLogin.mockResolvedValue({ success: true })

    renderLoginPage()

    await user.type(
      screen.getByLabelText('Email address'),
      '  hr@acme.com  '
    )

    await user.type(
      screen.getByLabelText('Password'),
      'Password@123'
    )

    await user.click(screen.getByRole('button', { name: 'Sign in' }))

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith(
        'hr@acme.com',
        'Password@123'
      )
    })

    expect(
      await screen.findByRole('heading', {
        name: 'Dashboard page',
      })
    ).toBeInTheDocument()
  })

  it('displays the API error when login fails', async () => {
    const user = userEvent.setup()

    mockLogin.mockRejectedValue({
      response: {
        data: {
          error: 'Invalid email or password',
        },
      },
    })

    renderLoginPage()

    await user.type(
      screen.getByLabelText('Email address'),
      'wrong@acme.com'
    )

    await user.type(
      screen.getByLabelText('Password'),
      'WrongPassword'
    )

    await user.click(screen.getByRole('button', { name: 'Sign in' }))

    expect(
      await screen.findByText('Invalid email or password')
    ).toBeInTheDocument()
  })
})
