"use client"

import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  type ReactNode,
} from "react"
import { apiGetProfile, apiLogin, apiRegister } from "./api"

interface User {
  id: string
  name: string
  email: string
  phone_number: string
  marital_status: string
  age: number
  current_income: number
  income_raise_pct: number
  current_monthly_expenses: number
  inflation_rate: number
  spouse_age: number | null
  spouse_income: number | null
  spouse_income_raise_pct: number | null
  onboarding_complete: boolean
  onboarding_step: number
}

interface AuthContextType {
  user: User | null
  token: string | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  register: (data: Parameters<typeof apiRegister>[0]) => Promise<void>
  logout: () => void
  refreshProfile: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [token, setToken] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const fetchProfile = useCallback(async () => {
    try {
      const profile = await apiGetProfile()
      setUser(profile)
    } catch {
      localStorage.removeItem("goalpath_token")
      setToken(null)
      setUser(null)
    }
  }, [])

  useEffect(() => {
    const stored = localStorage.getItem("goalpath_token")
    if (stored) {
      setToken(stored)
      fetchProfile().finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [fetchProfile])

  const login = useCallback(
    async (email: string, password: string) => {
      const res = await apiLogin(email, password)
      localStorage.setItem("goalpath_token", res.access_token)
      setToken(res.access_token)
      await fetchProfile()
    },
    [fetchProfile]
  )

  const register = useCallback(
    async (data: Parameters<typeof apiRegister>[0]) => {
      await apiRegister(data)
      // auto-login after register
      await login(data.email, data.password)
    },
    [login]
  )

  const logout = useCallback(() => {
    localStorage.removeItem("goalpath_token")
    setToken(null)
    setUser(null)
  }, [])

  return (
    <AuthContext.Provider
      value={{ user, token, loading, login, register, logout, refreshProfile: fetchProfile }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error("useAuth must be used within AuthProvider")
  return ctx
}
