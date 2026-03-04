"use client"

import { formatINR } from "@/lib/utils"
import type { BucketsResult } from "@/lib/api"
import { Shield, TrendingUp, Lock, RefreshCw } from "lucide-react"

interface Props {
  buckets: BucketsResult
}

export function BucketStrategy({ buckets }: Props) {
  const b1 = buckets.buckets.bucket_1
  const b2 = buckets.buckets.bucket_2
  const b3 = buckets.buckets.bucket_3

  const bucketCards = [
    {
      data: b1,
      icon: Lock,
      accentColor: "border-chart-3",
      iconBg: "bg-chart-3/10",
      iconColor: "text-chart-3",
    },
    {
      data: b2,
      icon: Shield,
      accentColor: "border-primary",
      iconBg: "bg-primary/10",
      iconColor: "text-primary",
    },
    {
      data: b3,
      icon: TrendingUp,
      accentColor: "border-success",
      iconBg: "bg-success/10",
      iconColor: "text-success",
    },
  ]

  return (
    <div className="rounded-xl border border-border bg-card p-6">
      <h3 className="mb-2 text-lg font-semibold text-foreground">
        Post-Retirement Bucket Strategy
      </h3>
      <p className="mb-6 text-sm text-muted-foreground">
        Your corpus is split into three time-based buckets to protect against
        market volatility during retirement.
      </p>

      <div className="grid gap-4 lg:grid-cols-3">
        {bucketCards.map(({ data, icon: Icon, accentColor, iconBg, iconColor }) => (
          <div
            key={data.name}
            className={`rounded-xl border-l-4 ${accentColor} bg-secondary/30 p-5`}
          >
            <div className="mb-3 flex items-center gap-3">
              <div
                className={`flex h-9 w-9 items-center justify-center rounded-lg ${iconBg}`}
              >
                <Icon className={`h-4 w-4 ${iconColor}`} />
              </div>
              <div>
                <h4 className="text-sm font-semibold text-foreground">
                  {data.name}
                </h4>
                <p className="text-xs text-muted-foreground">
                  {data.years_covered}
                </p>
              </div>
            </div>

            <p className="mb-4 text-2xl font-bold text-foreground">
              {formatINR(data.size)}
            </p>

            <p className="mb-3 text-xs text-muted-foreground">{data.purpose}</p>

            <div className="flex flex-col gap-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Equity</span>
                <span className="font-medium text-success">
                  {data.equity_pct}% ({formatINR(data.equity_amount)})
                </span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Debt</span>
                <span className="font-medium text-chart-3">
                  {data.debt_pct}% ({formatINR(data.debt_amount)})
                </span>
              </div>
              {/* Visual bar */}
              <div className="mt-1 flex h-2 overflow-hidden rounded-full bg-muted">
                <div
                  className="bg-success transition-all"
                  style={{ width: `${data.equity_pct}%` }}
                />
                <div
                  className="bg-chart-3 transition-all"
                  style={{ width: `${data.debt_pct}%` }}
                />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Refill Rules */}
      <div className="mt-6 rounded-lg bg-secondary/50 p-4">
        <div className="mb-3 flex items-center gap-2">
          <RefreshCw className="h-4 w-4 text-primary" />
          <h4 className="text-sm font-semibold text-foreground">Refill Rules</h4>
        </div>
        <div className="flex flex-col gap-2">
          {Object.entries(buckets.refill_rules).map(([key, value]) => (
            <div key={key} className="flex items-start gap-2 text-sm">
              <span className="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary" />
              <span className="text-muted-foreground">{value}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
