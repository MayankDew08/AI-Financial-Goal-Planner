"use client"

import { useState } from "react"
import { useAuth } from "@/lib/auth-context"
import { apiUpdateUser } from "@/lib/api"
import { formatINR } from "@/lib/utils"
import { Loader2, CheckCircle2, Pencil, X } from "lucide-react"

export default function ProfilePage() {
  const { user, refreshProfile } = useAuth()
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState("")

  const [form, setForm] = useState({
    marital_status: user?.marital_status || "Single",
    age: String(user?.age || ""),
    current_income: String(user?.current_income || ""),
    income_raise_pct: String(user?.income_raise_pct || ""),
    current_monthly_expenses: String(user?.current_monthly_expenses || ""),
    inflation_rate: String(user?.inflation_rate || ""),
    spouse_age: String(user?.spouse_age || ""),
    spouse_income: String(user?.spouse_income || ""),
    spouse_income_raise_pct: String(user?.spouse_income_raise_pct || ""),
  })

  function update(key: string, value: string) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    if (!user) return
    setError("")
    setSaving(true)
    setSuccess(false)
    try {
      const data: Record<string, string | number | undefined> = {
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
      await apiUpdateUser(user.id, data)
      await refreshProfile()
      setSuccess(true)
      setEditing(false)
      setTimeout(() => setSuccess(false), 3000)
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
          <h1 className="text-2xl font-bold text-foreground">Profile</h1>
          <p className="mt-1 text-muted-foreground">
            Your personal and financial information
          </p>
        </div>
        {!editing && (
          <button
            onClick={() => setEditing(true)}
            className="flex items-center gap-2 rounded-md border border-border px-4 py-2 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
          >
            <Pencil className="h-4 w-4" />
            Edit
          </button>
        )}
      </div>

      {success && (
        <div className="flex items-center gap-2 rounded-lg border border-success/30 bg-success/10 px-4 py-3 text-sm text-success">
          <CheckCircle2 className="h-4 w-4" />
          Profile updated successfully
        </div>
      )}

      {error && (
        <div className="rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}

      {!editing ? (
        /* View Mode */
        <div className="flex flex-col gap-6">
          {/* Account Info */}
          <div className="rounded-xl border border-border bg-card p-6">
            <h2 className="mb-4 text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              Account
            </h2>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
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
              <div>
                <p className="text-xs text-muted-foreground">Marital Status</p>
                <p className="mt-1 text-sm font-medium text-foreground">
                  {user.marital_status}
                </p>
              </div>
            </div>
          </div>

          {/* Financial Info */}
          <div className="rounded-xl border border-border bg-card p-6">
            <h2 className="mb-4 text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              Financial Details
            </h2>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <div>
                <p className="text-xs text-muted-foreground">Annual Income</p>
                <p className="mt-1 text-sm font-medium text-foreground">
                  {formatINR(user.current_income)}
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Income Raise %</p>
                <p className="mt-1 text-sm font-medium text-foreground">
                  {user.income_raise_pct}%
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">
                  Monthly Expenses
                </p>
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
              {user.marital_status === "Married" && (
                <>
                  <div>
                    <p className="text-xs text-muted-foreground">Spouse Age</p>
                    <p className="mt-1 text-sm font-medium text-foreground">
                      {user.spouse_age ?? "N/A"} years
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">
                      Spouse Income
                    </p>
                    <p className="mt-1 text-sm font-medium text-foreground">
                      {user.spouse_income
                        ? formatINR(user.spouse_income)
                        : "N/A"}
                    </p>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      ) : (
        /* Edit Mode */
        <form
          onSubmit={handleSave}
          className="rounded-xl border border-border bg-card p-6"
        >
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              Edit Financial Details
            </h2>
            <button
              type="button"
              onClick={() => setEditing(false)}
              className="text-muted-foreground hover:text-foreground"
              aria-label="Cancel editing"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="flex flex-col gap-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-medium text-foreground">
                  Age
                </label>
                <input
                  type="number"
                  min={18}
                  max={80}
                  value={form.age}
                  onChange={(e) => update("age", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-medium text-foreground">
                  Marital Status
                </label>
                <select
                  value={form.marital_status}
                  onChange={(e) => update("marital_status", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                >
                  <option value="Single">Single</option>
                  <option value="Married">Married</option>
                </select>
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-medium text-foreground">
                  Annual Income
                </label>
                <input
                  type="number"
                  min={1}
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
                  min={0}
                  max={50}
                  step={0.1}
                  value={form.income_raise_pct}
                  onChange={(e) => update("income_raise_pct", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-medium text-foreground">
                  Monthly Expenses
                </label>
                <input
                  type="number"
                  min={1}
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
                  min={1}
                  max={20}
                  step={0.1}
                  value={form.inflation_rate}
                  onChange={(e) => update("inflation_rate", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>

            {form.marital_status === "Married" && (
              <div className="grid gap-4 sm:grid-cols-3">
                <div className="flex flex-col gap-1.5">
                  <label className="text-sm font-medium text-foreground">
                    Spouse Age
                  </label>
                  <input
                    type="number"
                    min={18}
                    max={80}
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
                    min={0}
                    value={form.spouse_income}
                    onChange={(e) => update("spouse_income", e.target.value)}
                    className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-sm font-medium text-foreground">
                    Spouse Raise %
                  </label>
                  <input
                    type="number"
                    min={0}
                    max={50}
                    step={0.1}
                    value={form.spouse_income_raise_pct}
                    onChange={(e) =>
                      update("spouse_income_raise_pct", e.target.value)
                    }
                    className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                </div>
              </div>
            )}

            <div className="flex items-center gap-3">
              <button
                type="submit"
                disabled={saving}
                className="flex items-center gap-2 rounded-md bg-primary px-5 py-2.5 text-sm font-semibold text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
              >
                {saving && <Loader2 className="h-4 w-4 animate-spin" />}
                Save Changes
              </button>
              <button
                type="button"
                onClick={() => setEditing(false)}
                className="rounded-md border border-border px-5 py-2.5 text-sm font-medium text-muted-foreground hover:bg-accent hover:text-foreground"
              >
                Cancel
              </button>
            </div>
          </div>
        </form>
      )}
    </div>
  )
}
