"use client"

import { useRouter } from "next/navigation"
import { useRetirement } from "@/lib/retirement-context"
import { CorpusSummary, CorpusDetailCards } from "@/components/retirement/corpus-summary"
import { FeasibilityCard } from "@/components/retirement/feasibility-card"
import { GlidePathChart } from "@/components/retirement/glide-path-chart"
import { BucketStrategy } from "@/components/retirement/bucket-strategy"
import { SipScheduleTable } from "@/components/retirement/sip-schedule-table"
import { ArrowLeft, MessageSquare, RotateCcw } from "lucide-react"
import Link from "next/link"

export default function RetirementResultsPage() {
  const router = useRouter()
  const { plan } = useRetirement()

  if (!plan) {
    return (
      <div className="flex flex-col items-center justify-center py-24">
        <h2 className="mb-2 text-xl font-semibold text-foreground">
          No Plan Computed Yet
        </h2>
        <p className="mb-6 text-muted-foreground">
          You need to compute a retirement plan first.
        </p>
        <button
          onClick={() => router.push("/dashboard/retirement")}
          className="flex items-center gap-2 rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90"
        >
          <ArrowLeft className="h-4 w-4" />
          Go to Retirement Planner
        </button>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">
            Your Retirement Plan
          </h1>
          <p className="mt-1 text-muted-foreground">
            Complete breakdown of your personalized retirement strategy.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard/chat"
            className="flex items-center gap-2 rounded-md bg-chart-3/10 px-4 py-2 text-sm font-medium text-chart-3 transition-colors hover:bg-chart-3/20"
          >
            <MessageSquare className="h-4 w-4" />
            Ask AI
          </Link>
          <button
            onClick={() => router.push("/dashboard/retirement")}
            className="flex items-center gap-2 rounded-md border border-border px-4 py-2 text-sm font-medium text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
          >
            <RotateCcw className="h-4 w-4" />
            Recompute
          </button>
        </div>
      </div>

      {/* Feasibility */}
      <FeasibilityCard status={plan.status} feasibility={plan.feasibility} />

      {/* Corpus Summary Cards */}
      <CorpusSummary corpus={plan.corpus} />

      {/* Detailed Breakdown */}
      <CorpusDetailCards corpus={plan.corpus} />

      {/* Glide Path */}
      {plan.glide_path && <GlidePathChart glidePath={plan.glide_path} />}

      {/* SIP Schedule Table */}
      {plan.glide_path && (
        <SipScheduleTable
          schedule={plan.glide_path.yearly_schedule}
          stepupRate={plan.glide_path.sip_stepup_rate_pct}
        />
      )}

      {/* Bucket Strategy */}
      {plan.buckets && <BucketStrategy buckets={plan.buckets} />}

      {/* Disclaimer */}
      <div className="rounded-lg border border-border bg-secondary/30 p-4">
        <p className="text-xs text-muted-foreground">
          All projections in this plan are based on the assumptions you provided
          -- inflation rate, expected return, and time horizon. These are
          estimates, not guarantees. GoalPath AI is not a SEBI-registered
          advisor. Please review this plan with a qualified fee-only financial
          planner before making investment decisions.
        </p>
      </div>
    </div>
  )
}
