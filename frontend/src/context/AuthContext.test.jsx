
import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  render,
  screen,
  waitFor,
  fireEvent,
} from '@testing-library/react'

import { AuthProvider, useAuth } from './AuthContext'
import authService from '../services/authService'
import userService from '../services/userService'

vi.mock('../services/authService', () => ({
  default: {
    login: vi.fn(),
    logout: vi.fn(),
  },
}))

vi.mock('../services/userService', () => ({
  default: {
    getCurrentUser: vi.fn(),
  },
}))

function AuthConsumer() {
  const {
    token,
    user,
    loading,
    isAuthenticated,
    login,
    logout,
  } = useAuth()

  return (
    <div>
      <p data-testid="token">{token || 'no-token'}</p>
      <p data-testid="user">{user?.email || 'no-user'}</p>
      <p data-testid="loading">{String(loading)}</p>
      <p data-testid="authenticated">{String(isAuthenticated)}</p>

      <button
        onClick={() => login('hr@acme.com', 'Password@123')}
      >
        Login
      </button>

      <button onClick={() => logout().catch(() => {})}>
        Logout
      </button>
    </div>
  )
}

function renderAuthProvider() {
  return render(
    <AuthProvider>
      <AuthConsumer />
    </AuthProvider>
  )
}

describe('AuthContext', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('keeps the user logged out when no token exists', async () => {
    renderAuthProvider()

    expect(screen.getByTestId('token')).toHaveTextContent('no-token')
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')

    await waitFor(() => {
      expect(screen.getByTestId('loading')).toHaveTextContent('false')
    })

    expect(userService.getCurrentUser).not.toHaveBeenCalled()
  })

  it('loads the current user when a valid token exists', async () => {
    localStorage.setItem('authToken', 'valid-test-token')

    userService.getCurrentUser.mockResolvedValue({
      id: 1,
      email: 'hr@acme.com',
      role: 'hr_manager',
    })

    renderAuthProvider()

    expect(await screen.findByTestId('user')).toHaveTextContent(
      'hr@acme.com'
    )

    expect(screen.getByTestId('authenticated')).toHaveTextContent('true')
    expect(screen.getByTestId('token')).toHaveTextContent(
      'valid-test-token'
    )

    expect(userService.getCurrentUser).toHaveBeenCalledOnce()
  })

  it('clears an invalid token when loading the current user fails', async () => {
    localStorage.setItem('authToken', 'invalid-test-token')

    userService.getCurrentUser.mockRejectedValue(
      new Error('Unauthorized')
    )

    renderAuthProvider()

    await waitFor(() => {
      expect(screen.getByTestId('authenticated')).toHaveTextContent(
        'false'
      )
    })

    expect(screen.getByTestId('token')).toHaveTextContent('no-token')
    expect(screen.getByTestId('user')).toHaveTextContent('no-user')
    expect(localStorage.getItem('authToken')).toBeNull()
  })

  it('updates authentication state after successful login', async () => {
    authService.login.mockImplementation(async () => {
      localStorage.setItem('authToken', 'new-test-token')

      return { success: true }
    })

    renderAuthProvider()

    fireEvent.click(screen.getByRole('button', { name: 'Login' }))

    await waitFor(() => {
      expect(screen.getByTestId('token')).toHaveTextContent(
        'new-test-token'
      )

      expect(screen.getByTestId('authenticated')).toHaveTextContent(
        'true'
      )
    })

    expect(authService.login).toHaveBeenCalledWith(
      'hr@acme.com',
      'Password@123'
    )
  })

  it('clears authentication state after logout', async () => {
    localStorage.setItem('authToken', 'valid-test-token')

    userService.getCurrentUser.mockResolvedValue({
      id: 1,
      email: 'hr@acme.com',
      role: 'hr_manager',
    })

    authService.logout.mockResolvedValue({ success: true })

    renderAuthProvider()

    await screen.findByText('hr@acme.com')

    fireEvent.click(screen.getByRole('button', { name: 'Logout' }))

    await waitFor(() => {
      expect(screen.getByTestId('authenticated')).toHaveTextContent(
        'false'
      )
    })

    expect(screen.getByTestId('token')).toHaveTextContent('no-token')
    expect(screen.getByTestId('user')).toHaveTextContent('no-user')
    expect(localStorage.getItem('authToken')).toBeNull()
    expect(authService.logout).toHaveBeenCalledOnce()
  })

  it('clears authentication state even when logout API fails', async () => {
    localStorage.setItem('authToken', 'valid-test-token')

    userService.getCurrentUser.mockResolvedValue({
      id: 1,
      email: 'hr@acme.com',
      role: 'hr_manager',
    })

    authService.logout.mockRejectedValue(
      new Error('Network error')
    )

    renderAuthProvider()

    await screen.findByText('hr@acme.com')

    fireEvent.click(screen.getByRole('button', { name: 'Logout' }))

    await waitFor(() => {
      expect(screen.getByTestId('authenticated')).toHaveTextContent(
        'false'
      )
    })

    expect(screen.getByTestId('token')).toHaveTextContent('no-token')
    expect(screen.getByTestId('user')).toHaveTextContent('no-user')
    expect(localStorage.getItem('authToken')).toBeNull()
    expect(authService.logout).toHaveBeenCalledOnce()
  })
})
