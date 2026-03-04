"use client"

import { useState } from "react"
import { useAuth } from "@/lib/auth-context"
import { apiUpdateUser } from "@/lib/api"
import { formatINR } from "@/lib/utils"
import { Loader2, Save, User, Briefcase, Heart } from "lucide-react"

export default function ProfilePage() {
  const { user, refreshProfile } = useAuth()
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState("")
  const [success, setSuccess] = useState("")

  const [form, setForm] = useState({
    name: user?.name || "",
    phone_number: user?.phone_number || "",
    age: String(user?.age || ""),
    current_income: String(user?.current_income || ""),
    income_raise_pct: String(user?.income_raise_pct || ""),
    current_monthly_expenses: String(user?.current_monthly_expenses || ""),
    inflation_rate: String(user?.inflation_rate || ""),
    spouse_age: String(user?.spouse_age || ""),
    spouse_income: String(user?.spouse_income || ""),
    spouse_income_raise_pct: String(user?.spouse_income_raise_pct || ""),
  })

  function update(field: string, value: string) {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  async function handleSave() {
    if (!user) return
    setError("")
    setSuccess("")
    setSaving(true)
    try {
      await apiUpdateUser(user.id, {
        name: form.name,
        phone_number: form.phone_number,
        age: Number(form.age),
        current_income: Number(form.current_income),
        income_raise_pct: Number(form.income_raise_pct),
        current_monthly_expenses: Number(form.current_monthly_expenses),
        inflation_rate: Number(form.inflation_rate),
        ...(user.marital_status === "Married"
          ? {
              spouse_age: Number(form.spouse_age) || undefined,
              spouse_income: Number(form.spouse_income) || undefined,
              spouse_income_raise_pct:
                Number(form.spouse_income_raise_pct) || undefined,
            }
          : {}),
      })
      await refreshProfile()
      setSuccess("Profile updated successfully")
      setEditing(false)
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to update profile")
    } finally {
      setSaving(false)
    }
  }

  if (!user) return null

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Your Profile</h1>
          <p className="mt-1 text-muted-foreground">
            Review and update your financial details
          </p>
        </div>
        {!editing ? (
          <button
            onClick={() => setEditing(true)}
            className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
          >
            Edit Profile
          </button>
        ) : (
          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                setEditing(false)
                setError("")
                setSuccess("")
              }}
              className="rounded-md border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-accent hover:text-foreground"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
            >
              {saving ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Save className="h-4 w-4" />
              )}
              Save
            </button>
          </div>
        )}
      </div>

      {error && (
        <div className="rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}

      {success && (
        <div className="rounded-lg border border-success/30 bg-success/10 px-4 py-3 text-sm text-success">
          {success}
        </div>
      )}

      {/* Personal Information */}
      <div className="rounded-xl border border-border bg-card p-6">
        <div className="mb-5 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
            <User className="h-5 w-5 text-primary" />
          </div>
          <h2 className="text-lg font-semibold text-foreground">
            Personal Information
          </h2>
        </div>

        {editing ? (
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium text-foreground">
                Full Name
              </label>
              <input
                value={form.name}
                onChange={(e) => update("name", e.target.value)}
                className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium text-foreground">
                Phone
              </label>
              <input
                value={form.phone_number}
                onChange={(e) => update("phone_number", e.target.value)}
                className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium text-foreground">Age</label>
              <input
                type="number"
                value={form.age}
                onChange={(e) => update("age", e.target.value)}
                className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium text-foreground">
                Email
              </label>
              <input
                value={user.email}
                disabled
                className="rounded-md border border-input bg-muted px-3 py-2.5 text-sm text-muted-foreground"
              />
            </div>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div>
              <p className="text-xs text-muted-foreground">Name</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {user.name}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Email</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {user.email}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Phone</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {user.phone_number}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Age</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {user.age} years
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Financial Information */}
      <div className="rounded-xl border border-border bg-card p-6">
        <div className="mb-5 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-success/10">
            <Briefcase className="h-5 w-5 text-success" />
          </div>
          <h2 className="text-lg font-semibold text-foreground">
            Financial Details
          </h2>
        </div>

        {editing ? (
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium text-foreground">
                Annual Income
              </label>
              <input
                type="number"
                value={form.current_income}
                onChange={(e) => update("current_income", e.target.value)}
                className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium text-foreground">
                Income Raise %
              </label>
              <input
                type="number"
                step={0.1}
                value={form.income_raise_pct}
                onChange={(e) => update("income_raise_pct", e.target.value)}
                className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium text-foreground">
                Monthly Expenses
              </label>
              <input
                type="number"
                value={form.current_monthly_expenses}
                onChange={(e) =>
                  update("current_monthly_expenses", e.target.value)
                }
                className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-sm font-medium text-foreground">
                Inflation Rate %
              </label>
              <input
                type="number"
                step={0.1}
                value={form.inflation_rate}
                onChange={(e) => update("inflation_rate", e.target.value)}
                className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div>
              <p className="text-xs text-muted-foreground">Annual Income</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {formatINR(user.current_income)}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Income Raise</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {user.income_raise_pct}%
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Monthly Expenses</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {formatINR(user.current_monthly_expenses)}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Inflation Rate</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {user.inflation_rate}%
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Spouse Info */}
      {user.marital_status === "Married" && (
        <div className="rounded-xl border border-border bg-card p-6">
          <div className="mb-5 flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-chart-5/10">
              <Heart className="h-5 w-5 text-chart-5" />
            </div>
            <h2 className="text-lg font-semibold text-foreground">
              Spouse Details
            </h2>
          </div>

          {editing ? (
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-medium text-foreground">
                  Spouse Age
                </label>
                <input
                  type="number"
                  value={form.spouse_age}
                  onChange={(e) => update("spouse_age", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-medium text-foreground">
                  Spouse Income
                </label>
                <input
                  type="number"
                  value={form.spouse_income}
                  onChange={(e) => update("spouse_income", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-medium text-foreground">
                  Raise %
                </label>
                <input
                  type="number"
                  step={0.1}
                  value={form.spouse_income_raise_pct}
                  onChange={(e) =>
                    update("spouse_income_raise_pct", e.target.value)
                  }
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-3">
              <div>
                <p className="text-xs text-muted-foreground">Age</p>
                <p className="mt-1 text-sm font-medium text-foreground">
                  {user.spouse_age || "N/A"}
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Income</p>
                <p className="mt-1 text-sm font-medium text-foreground">
                  {user.spouse_income
                    ? formatINR(user.spouse_income)
                    : "N/A"}
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Income Raise</p>
                <p className="mt-1 text-sm font-medium text-foreground">
                  {user.spouse_income_raise_pct
                    ? `${user.spouse_income_raise_pct}%`
                    : "N/A"}
                </p>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Account Meta */}
      <div className="rounded-xl border border-border bg-card p-6">
        <h2 className="mb-4 text-lg font-semibold text-foreground">
          Account Information
        </h2>
        <div className="grid gap-4 sm:grid-cols-3">
          <div>
            <p className="text-xs text-muted-foreground">Marital Status</p>
            <p className="mt-1 text-sm font-medium text-foreground">
              {user.marital_status}
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground">Onboarding</p>
            <p className="mt-1 text-sm font-medium text-foreground">
              {user.onboarding_complete ? "Complete" : `Step ${user.onboarding_step}`}
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground">User ID</p>
            <p className="mt-1 truncate text-sm font-mono text-muted-foreground">
              {user.id}
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
