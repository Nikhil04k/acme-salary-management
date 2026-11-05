
import {
  createContext,
  useContext,
  useEffect,
  useState,
} from 'react'

import authService from '../services/authService'
import userService from '../services/userService'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [token, setToken] = useState(
    () => localStorage.getItem('authToken')
  )

  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchUser = async () => {
      if (!token) {
        setUser(null)
        setLoading(false)
        return
      }

      try {
        const currentUser = await userService.getCurrentUser()
        setUser(currentUser)
      } catch (error) {
        localStorage.removeItem('authToken')
        setToken(null)
        setUser(null)
      } finally {
        setLoading(false)
      }
    }

    fetchUser()
  }, [token])

  const login = async (email, password) => {
    const response = await authService.login(email, password)

    const savedToken = localStorage.getItem('authToken')
    setToken(savedToken)

    return response
  }

  const logout = async () => {
    try {
      await authService.logout()
    } finally {
      localStorage.removeItem('authToken')
      setToken(null)
      setUser(null)
    }
  }

  const isAuthenticated = Boolean(token)

  return (
    <AuthContext.Provider
      value={{
        token,
        user,
        loading,
        isAuthenticated,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
