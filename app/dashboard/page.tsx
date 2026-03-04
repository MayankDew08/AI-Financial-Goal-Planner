"use client"

import Link from "next/link"
import { useAuth } from "@/lib/auth-context"
import { useRetirement } from "@/lib/retirement-context"
import { formatINR } from "@/lib/utils"
import {
  TrendingUp,
  MessageSquare,
  User,
  ArrowRight,
  CheckCircle2,
  XCircle,
} from "lucide-react"

export default function DashboardOverview() {
  const { user } = useAuth()
  const { plan } = useRetirement()

  return (
    <div className="flex flex-col gap-8">
      {/* Welcome */}
      <div>
        <h1 className="text-2xl font-bold text-foreground">
          Welcome back, {user?.name?.split(" ")[0]}
        </h1>
        <p className="mt-1 text-muted-foreground">
          Here is a snapshot of your financial planning journey.
        </p>
      </div>

      {/* Quick Actions */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Link
          href="/dashboard/retirement"
          className="group flex flex-col justify-between rounded-xl border border-border bg-card p-6 transition-colors hover:border-primary/30"
        >
          <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
            <TrendingUp className="h-5 w-5 text-primary" />
          </div>
          <div>
            <h3 className="font-semibold text-foreground">Retirement Planner</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              {plan ? "View or recompute your retirement plan" : "Compute your personalized retirement plan"}
            </p>
          </div>
          <div className="mt-4 flex items-center gap-1 text-sm font-medium text-primary">
            {plan ? "View Plan" : "Get Started"}
            <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-1" />
          </div>
        </Link>

        <Link
          href="/dashboard/chat"
          className="group flex flex-col justify-between rounded-xl border border-border bg-card p-6 transition-colors hover:border-primary/30"
        >
          <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-lg bg-chart-3/10">
            <MessageSquare className="h-5 w-5 text-chart-3" />
          </div>
          <div>
            <h3 className="font-semibold text-foreground">AI Chat</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              {plan
                ? "Ask the AI about your retirement plan"
                : "Compute a plan first to chat with the AI"}
            </p>
          </div>
          <div className="mt-4 flex items-center gap-1 text-sm font-medium text-chart-3">
            Open Chat
            <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-1" />
          </div>
        </Link>

        <Link
          href="/dashboard/profile"
          className="group flex flex-col justify-between rounded-xl border border-border bg-card p-6 transition-colors hover:border-primary/30"
        >
          <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-lg bg-chart-2/10">
            <User className="h-5 w-5 text-chart-2" />
          </div>
          <div>
            <h3 className="font-semibold text-foreground">Profile</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              Review and update your financial details
            </p>
          </div>
          <div className="mt-4 flex items-center gap-1 text-sm font-medium text-chart-2">
            View Profile
            <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-1" />
          </div>
        </Link>
      </div>

      {/* Plan Summary (if available) */}
      {plan && (
        <div className="rounded-xl border border-border bg-card p-6">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-foreground">
              Retirement Plan Summary
            </h2>
            <div className="flex items-center gap-2">
              {plan.status === "feasible" ? (
                <>
                  <CheckCircle2 className="h-5 w-5 text-success" />
                  <span className="text-sm font-medium text-success">Feasible</span>
                </>
              ) : (
                <>
                  <XCircle className="h-5 w-5 text-destructive" />
                  <span className="text-sm font-medium text-destructive">
                    Needs Adjustment
                  </span>
                </>
              )}
            </div>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div>
              <p className="text-xs text-muted-foreground">Corpus Required</p>
              <p className="mt-1 text-lg font-semibold text-foreground">
                {formatINR(plan.corpus.corpus_required)}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Corpus Gap</p>
              <p className="mt-1 text-lg font-semibold text-foreground">
                {formatINR(plan.corpus.corpus_gap)}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Additional SIP Needed</p>
              <p className="mt-1 text-lg font-semibold text-primary">
                {formatINR(plan.corpus.additional_monthly_sip_required)}/mo
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Existing Corpus FV</p>
              <p className="mt-1 text-lg font-semibold text-foreground">
                {formatINR(plan.corpus.fv_existing_corpus)}
              </p>
            </div>
          </div>
          <div className="mt-4">
            <Link
              href="/dashboard/retirement/results"
              className="text-sm font-medium text-primary hover:underline"
            >
              View full results with charts and breakdown
            </Link>
          </div>
        </div>
      )}

      {/* User Profile Summary */}
      {user && (
        <div className="rounded-xl border border-border bg-card p-6">
          <h2 className="mb-4 text-lg font-semibold text-foreground">
            Your Financial Profile
          </h2>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div>
              <p className="text-xs text-muted-foreground">Age</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {user.age} years
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Annual Income</p>
              <p className="mt-1 text-sm font-medium text-foreground">
                {formatINR(user.current_income)}
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
        </div>
      )}
    </div>
  )
}
