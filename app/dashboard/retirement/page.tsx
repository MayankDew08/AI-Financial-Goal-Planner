"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { apiComputeRetirement, type RetirementFormData } from "@/lib/api"
import { useRetirement } from "@/lib/retirement-context"
import { Loader2, ArrowRight, Info } from "lucide-react"

export default function RetirementPlannerPage() {
  const router = useRouter()
  const { plan, setPlan } = useRetirement()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")

  const [form, setForm] = useState<RetirementFormData>({
    retirement_age: 60,
    post_retirement_expense_pct: 70,
    post_retirement_return: 7,
    pre_retirement_return: 10,
    life_expectancy: 85,
    annual_post_retirement_income: 0,
    existing_corpus: 0,
    existing_monthly_sip: 0,
    sip_raise_pct: 0,
  })

  function update<K extends keyof RetirementFormData>(key: K, val: string) {
    setForm((prev) => ({ ...prev, [key]: Number(val) }))
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError("")
    setLoading(true)
    try {
      const result = await apiComputeRetirement(form)
      setPlan(result)
      router.push("/dashboard/retirement/results")
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to compute plan")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">Retirement Planner</h1>
        <p className="mt-1 text-muted-foreground">
          Enter your retirement parameters below. Your profile data (income,
          expenses, age) is used automatically from your account.
        </p>
      </div>

      {error && (
        <div className="rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}

      {plan && (
        <div className="rounded-lg border border-primary/30 bg-primary/5 px-4 py-3">
          <div className="flex items-center justify-between">
            <p className="text-sm text-foreground">
              You have an existing plan. You can{" "}
              <button
                type="button"
                onClick={() => router.push("/dashboard/retirement/results")}
                className="font-medium text-primary hover:underline"
              >
                view results
              </button>{" "}
              or recompute below.
            </p>
          </div>
        </div>
      )}

      <form
        onSubmit={handleSubmit}
        className="rounded-xl border border-border bg-card p-6"
      >
        <div className="flex flex-col gap-6">
          {/* Retirement Age & Life Expectancy */}
          <fieldset className="flex flex-col gap-4">
            <legend className="mb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Timeline
            </legend>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="retirement_age"
                  className="text-sm font-medium text-foreground"
                >
                  Retirement Age
                </label>
                <input
                  id="retirement_age"
                  type="number"
                  required
                  min={35}
                  max={80}
                  value={form.retirement_age}
                  onChange={(e) => update("retirement_age", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="life_expectancy"
                  className="text-sm font-medium text-foreground"
                >
                  Life Expectancy
                </label>
                <input
                  id="life_expectancy"
                  type="number"
                  required
                  min={60}
                  max={100}
                  value={form.life_expectancy}
                  onChange={(e) => update("life_expectancy", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>
          </fieldset>

          {/* Expense & Return Assumptions */}
          <fieldset className="flex flex-col gap-4">
            <legend className="mb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Assumptions
            </legend>
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="post_ret_expense"
                  className="flex items-center gap-1 text-sm font-medium text-foreground"
                >
                  Post-Retirement Expense %
                  <span
                    title="Your post-retirement expenses as a percentage of current pre-retirement expenses (e.g., 70 = 70%)"
                    className="cursor-help"
                  >
                    <Info className="h-3.5 w-3.5 text-muted-foreground" />
                  </span>
                </label>
                <input
                  id="post_ret_expense"
                  type="number"
                  required
                  min={1}
                  max={100}
                  step={1}
                  value={form.post_retirement_expense_pct}
                  onChange={(e) =>
                    update("post_retirement_expense_pct", e.target.value)
                  }
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="pre_ret_return"
                  className="text-sm font-medium text-foreground"
                >
                  Pre-Retirement Return %
                </label>
                <input
                  id="pre_ret_return"
                  type="number"
                  required
                  min={1}
                  max={20}
                  step={0.1}
                  value={form.pre_retirement_return}
                  onChange={(e) => update("pre_retirement_return", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="post_ret_return"
                  className="text-sm font-medium text-foreground"
                >
                  Post-Retirement Return %
                </label>
                <input
                  id="post_ret_return"
                  type="number"
                  required
                  min={1}
                  max={20}
                  step={0.1}
                  value={form.post_retirement_return}
                  onChange={(e) => update("post_retirement_return", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>
          </fieldset>

          {/* Existing Assets */}
          <fieldset className="flex flex-col gap-4">
            <legend className="mb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Existing Investments
            </legend>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="post_ret_income"
                  className="flex items-center gap-1 text-sm font-medium text-foreground"
                >
                  Annual Post-Retirement Income
                  <span
                    title="Any pension, rental income, or other regular income you expect after retirement (in today's value)"
                    className="cursor-help"
                  >
                    <Info className="h-3.5 w-3.5 text-muted-foreground" />
                  </span>
                </label>
                <input
                  id="post_ret_income"
                  type="number"
                  min={0}
                  value={form.annual_post_retirement_income}
                  onChange={(e) =>
                    update("annual_post_retirement_income", e.target.value)
                  }
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="existing_corpus"
                  className="text-sm font-medium text-foreground"
                >
                  Existing Retirement Corpus
                </label>
                <input
                  id="existing_corpus"
                  type="number"
                  min={0}
                  value={form.existing_corpus}
                  onChange={(e) => update("existing_corpus", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="existing_sip"
                  className="text-sm font-medium text-foreground"
                >
                  Existing Monthly SIP
                </label>
                <input
                  id="existing_sip"
                  type="number"
                  min={0}
                  value={form.existing_monthly_sip}
                  onChange={(e) => update("existing_monthly_sip", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="sip_raise"
                  className="flex items-center gap-1 text-sm font-medium text-foreground"
                >
                  SIP Step-Up %
                  <span
                    title="Annual increase percentage applied to your existing SIP"
                    className="cursor-help"
                  >
                    <Info className="h-3.5 w-3.5 text-muted-foreground" />
                  </span>
                </label>
                <input
                  id="sip_raise"
                  type="number"
                  min={0}
                  max={50}
                  step={0.1}
                  value={form.sip_raise_pct}
                  onChange={(e) => update("sip_raise_pct", e.target.value)}
                  className="rounded-md border border-input bg-background px-3 py-2.5 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                />
              </div>
            </div>
          </fieldset>

          <button
            type="submit"
            disabled={loading}
            className="flex items-center justify-center gap-2 rounded-md bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-50"
          >
            {loading ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <ArrowRight className="h-4 w-4" />
            )}
            {loading ? "Computing Plan..." : "Compute Retirement Plan"}
          </button>
        </div>
      </form>
    </div>
  )
}
