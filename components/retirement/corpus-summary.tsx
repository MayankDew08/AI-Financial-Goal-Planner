"use client"

import { formatINR } from "@/lib/utils"
import type { CorpusResult } from "@/lib/api"
import { TrendingUp, TrendingDown, Wallet, Target } from "lucide-react"

interface Props {
  corpus: CorpusResult
}

export function CorpusSummary({ corpus }: Props) {
  const cards = [
    {
      label: "Corpus Required",
      value: formatINR(corpus.corpus_required),
      icon: Target,
      color: "text-primary",
      bg: "bg-primary/10",
    },
    {
      label: "Corpus Gap",
      value: formatINR(corpus.corpus_gap),
      icon: corpus.corpus_gap > 0 ? TrendingDown : TrendingUp,
      color: corpus.corpus_gap > 0 ? "text-chart-5" : "text-success",
      bg: corpus.corpus_gap > 0 ? "bg-chart-5/10" : "bg-success/10",
    },
    {
      label: "Additional SIP Needed",
      value: `${formatINR(corpus.additional_monthly_sip_required)}/mo`,
      icon: Wallet,
      color: "text-chart-3",
      bg: "bg-chart-3/10",
    },
    {
      label: "FV Existing Corpus",
      value: formatINR(corpus.fv_existing_corpus),
      icon: TrendingUp,
      color: "text-success",
      bg: "bg-success/10",
    },
  ]

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      {cards.map((card) => (
        <div
          key={card.label}
          className="rounded-xl border border-border bg-card p-5"
        >
          <div className="flex items-center justify-between">
            <p className="text-xs font-medium text-muted-foreground">
              {card.label}
            </p>
            <div
              className={`flex h-8 w-8 items-center justify-center rounded-lg ${card.bg}`}
            >
              <card.icon className={`h-4 w-4 ${card.color}`} />
            </div>
          </div>
          <p className={`mt-3 text-xl font-bold ${card.color}`}>{card.value}</p>
        </div>
      ))}
    </div>
  )
}

export function CorpusDetailCards({ corpus }: Props) {
  return (
    <div className="rounded-xl border border-border bg-card p-6">
      <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-muted-foreground">
        Detailed Breakdown
      </h3>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg bg-secondary/50 p-4">
          <p className="text-xs text-muted-foreground">
            Annual Expense at Retirement
          </p>
          <p className="mt-1 text-lg font-semibold text-foreground">
            {formatINR(corpus.annual_expense_at_retirement)}
          </p>
        </div>
        <div className="rounded-lg bg-secondary/50 p-4">
          <p className="text-xs text-muted-foreground">
            Income at Retirement
          </p>
          <p className="mt-1 text-lg font-semibold text-foreground">
            {formatINR(corpus.income_at_retirement)}
          </p>
        </div>
        <div className="rounded-lg bg-secondary/50 p-4">
          <p className="text-xs text-muted-foreground">
            Net Annual Withdrawal
          </p>
          <p className="mt-1 text-lg font-semibold text-foreground">
            {formatINR(corpus.net_annual_withdrawal)}
          </p>
        </div>
        <div className="rounded-lg bg-secondary/50 p-4">
          <p className="text-xs text-muted-foreground">FV Existing SIP</p>
          <p className="mt-1 text-lg font-semibold text-foreground">
            {formatINR(corpus.fv_existing_sip)}
          </p>
        </div>
        <div className="rounded-lg bg-secondary/50 p-4">
          <p className="text-xs text-muted-foreground">FV Existing Corpus</p>
          <p className="mt-1 text-lg font-semibold text-foreground">
            {formatINR(corpus.fv_existing_corpus)}
          </p>
        </div>
        <div className="rounded-lg bg-secondary/50 p-4">
          <p className="text-xs text-muted-foreground">Corpus Gap</p>
          <p className="mt-1 text-lg font-semibold text-foreground">
            {formatINR(corpus.corpus_gap)}
          </p>
        </div>
      </div>
    </div>
  )
}
