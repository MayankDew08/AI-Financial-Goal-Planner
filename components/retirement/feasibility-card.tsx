"use client"

import { CheckCircle2, XCircle, AlertTriangle } from "lucide-react"

interface Props {
  status: "feasible" | "infeasible"
  feasibility: {
    feasible: boolean
    failure?: {
      year: number
      age: number
      monthly_household_income: number
      total_monthly_sip: number
      savings_ratio_pct: number
      message: string
    }
  }
}

export function FeasibilityCard({ status, feasibility }: Props) {
  const isFeasible = status === "feasible"

  return (
    <div
      className={`rounded-xl border p-6 ${
        isFeasible
          ? "border-success/30 bg-success/5"
          : "border-destructive/30 bg-destructive/5"
      }`}
    >
      <div className="flex items-start gap-4">
        <div
          className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-full ${
            isFeasible ? "bg-success/20" : "bg-destructive/20"
          }`}
        >
          {isFeasible ? (
            <CheckCircle2 className="h-5 w-5 text-success" />
          ) : (
            <XCircle className="h-5 w-5 text-destructive" />
          )}
        </div>
        <div>
          <h3
            className={`text-lg font-semibold ${
              isFeasible ? "text-success" : "text-destructive"
            }`}
          >
            {isFeasible ? "Plan is Feasible" : "Plan Needs Adjustment"}
          </h3>
          {isFeasible ? (
            <p className="mt-1 text-sm text-muted-foreground">
              Your monthly SIP stays within 50% of your household income
              throughout the accumulation period. This plan is achievable.
            </p>
          ) : (
            <>
              <p className="mt-1 text-sm text-muted-foreground">
                {feasibility.failure?.message}
              </p>
              {feasibility.failure && (
                <div className="mt-3 flex items-start gap-2 rounded-lg bg-destructive/10 p-3">
                  <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-destructive" />
                  <div className="text-sm text-foreground">
                    <p>
                      Breach occurs at year {feasibility.failure.year} (age{" "}
                      {feasibility.failure.age}) when the savings ratio reaches{" "}
                      {feasibility.failure.savings_ratio_pct}% of income.
                    </p>
                    <p className="mt-1 text-muted-foreground">
                      Consider extending your retirement timeline or increasing
                      your savings rate to make the plan feasible.
                    </p>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}
