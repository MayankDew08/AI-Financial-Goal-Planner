"use client"

import { useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { useAuth } from "@/lib/auth-context"
import { AuthProvider } from "@/lib/auth-context"
import { Eye, EyeOff, Loader2 } from "lucide-react"

function RegisterForm() {
  const { register } = useAuth()
  const router = useRouter()
  const [error, setError] = useState("")
  const [loading, setLoading] = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  const [form, setForm] = useState({
    name: "",
    email: "",
    phone_number: "",
    password: "",
    marital_status: "Single",
    age: "",
    current_income: "",
    income_raise_pct: "",
    current_monthly_expenses: "",
    inflation_rate: "6",
    spouse_age: "",
    spouse_income: "",
    spouse_income_raise_pct: "",
  })

  function update(field: string, value: string) {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError("")
    setLoading(true)
    try {
      const data: Parameters<typeof register>[0] = {
        name: form.name,
        email: form.email,
        phone_number: form.phone_number,
        password: form.password,
        marital_status: form.marital_status,
        age: Number(form.age),
        current_income: Number(form.current_income),
        income_raise_pct: Number(form.income_raise_pct),
        current_monthly_expenses: Number(form.current_monthly_expenses),
        inflation_rate: Number(form.inflation_rate),
      }
      if (form.marital_status === "Married") {
        data.spouse_age = Number(form.spouse_age)
        if (form.spouse_income) data.spouse_income = Number(form.spouse_income)
        if (form.spouse_income_raise_pct)
          data.spouse_income_raise_pct = Number(form.spouse_income_raise_pct)
      }
      await register(data)
      router.push("/dashboard")
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Registration failed")
    } finally {
      setLoading(false)
    }
  }

  const isMarried = form.marital_status === "Married"

  return (
    <div className="rounded-xl border border-border bg-card p-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-foreground">Create Your Account</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Set up your financial profile to get started
        </p>
      </div>

      {error && (
        <div className="mb-4 rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex flex-col gap-5">
        {/* Personal Info */}
        <fieldset className="flex flex-col gap-3">
          <legend className="mb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Personal Information
          </legend>
          <div className="flex flex-col gap-1.5">
            <label htmlFor="name" className="text-sm font-medium text-foreground">Full Name</label>
            <input id="name" type="text" required value={form.name} onChange={(e) => update("name", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="Rahul Sharma" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <label htmlFor="email" className="text-sm font-medium text-foreground">Email</label>
              <input id="email" type="email" required value={form.email} onChange={(e) => update("email", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="you@email.com" />
            </div>
            <div className="flex flex-col gap-1.5">
              <label htmlFor="phone" className="text-sm font-medium text-foreground">Phone (10 digits)</label>
              <input id="phone" type="text" required maxLength={10} minLength={10} pattern="[0-9]{10}" value={form.phone_number} onChange={(e) => update("phone_number", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="9876543210" />
            </div>
          </div>
          <div className="flex flex-col gap-1.5">
            <label htmlFor="password" className="text-sm font-medium text-foreground">Password</label>
            <div className="relative">
              <input id="password" type={showPassword ? "text" : "password"} required minLength={6} value={form.password} onChange={(e) => update("password", e.target.value)} className="w-full rounded-md border border-input bg-background px-3 py-2.5 pr-10 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="Min 6 characters" />
              <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground" aria-label={showPassword ? "Hide password" : "Show password"}>
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <label htmlFor="age" className="text-sm font-medium text-foreground">Age</label>
              <input id="age" type="number" required min={18} max={80} value={form.age} onChange={(e) => update("age", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="30" />
            </div>
            <div className="flex flex-col gap-1.5">
              <label htmlFor="marital" className="text-sm font-medium text-foreground">Marital Status</label>
              <select id="marital" value={form.marital_status} onChange={(e) => update("marital_status", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring">
                <option value="Single">Single</option>
                <option value="Married">Married</option>
              </select>
            </div>
          </div>
        </fieldset>

        {/* Financial Info */}
        <fieldset className="flex flex-col gap-3">
          <legend className="mb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Financial Details
          </legend>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <label htmlFor="income" className="text-sm font-medium text-foreground">Annual Income</label>
              <input id="income" type="number" required min={1} value={form.current_income} onChange={(e) => update("current_income", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="1200000" />
            </div>
            <div className="flex flex-col gap-1.5">
              <label htmlFor="raise" className="text-sm font-medium text-foreground">Income Raise %</label>
              <input id="raise" type="number" required min={0} max={50} step={0.1} value={form.income_raise_pct} onChange={(e) => update("income_raise_pct", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="8" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1.5">
              <label htmlFor="expenses" className="text-sm font-medium text-foreground">Monthly Expenses</label>
              <input id="expenses" type="number" required min={1} value={form.current_monthly_expenses} onChange={(e) => update("current_monthly_expenses", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="50000" />
            </div>
            <div className="flex flex-col gap-1.5">
              <label htmlFor="inflation" className="text-sm font-medium text-foreground">Inflation Rate %</label>
              <input id="inflation" type="number" required min={1} max={20} step={0.1} value={form.inflation_rate} onChange={(e) => update("inflation_rate", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="6" />
            </div>
          </div>
        </fieldset>

        {/* Spouse Fields */}
        {isMarried && (
          <fieldset className="flex flex-col gap-3">
            <legend className="mb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Spouse Details
            </legend>
            <div className="grid grid-cols-3 gap-3">
              <div className="flex flex-col gap-1.5">
                <label htmlFor="spouse_age" className="text-sm font-medium text-foreground">Spouse Age</label>
                <input id="spouse_age" type="number" required min={18} max={80} value={form.spouse_age} onChange={(e) => update("spouse_age", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="28" />
              </div>
              <div className="flex flex-col gap-1.5">
                <label htmlFor="spouse_income" className="text-sm font-medium text-foreground">Spouse Income</label>
                <input id="spouse_income" type="number" min={0} value={form.spouse_income} onChange={(e) => update("spouse_income", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="800000" />
              </div>
              <div className="flex flex-col gap-1.5">
                <label htmlFor="spouse_raise" className="text-sm font-medium text-foreground">Raise %</label>
                <input id="spouse_raise" type="number" min={0} max={50} step={0.1} value={form.spouse_income_raise_pct} onChange={(e) => update("spouse_income_raise_pct", e.target.value)} className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring" placeholder="7" />
              </div>
            </div>
          </fieldset>
        )}

        <button
          type="submit"
          disabled={loading}
          className="mt-2 flex items-center justify-center gap-2 rounded-md bg-primary px-4 py-2.5 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-50"
        >
          {loading && <Loader2 className="h-4 w-4 animate-spin" />}
          Create Account
        </button>
      </form>

      <p className="mt-6 text-center text-sm text-muted-foreground">
        Already have an account?{" "}
        <Link href="/login" className="font-medium text-primary hover:underline">
          Sign in
        </Link>
      </p>
    </div>
  )
}

export default function RegisterPage() {
  return (
    <AuthProvider>
      <RegisterForm />
    </AuthProvider>
  )
}
