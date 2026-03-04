"use client"

import { useState } from "react"
import { formatINR } from "@/lib/utils"
import type { GlidePathScheduleItem } from "@/lib/api"
import { ChevronDown, ChevronUp } from "lucide-react"

interface Props {
  schedule: GlidePathScheduleItem[]
  stepupRate: number
}

export function SipScheduleTable({ schedule, stepupRate }: Props) {
  const [expanded, setExpanded] = useState(false)
  const displayItems = expanded ? schedule : schedule.slice(0, 10)

  return (
    <div className="rounded-xl border border-border bg-card p-6">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold text-foreground">
            Year-by-Year SIP Schedule
          </h3>
          <p className="mt-1 text-sm text-muted-foreground">
            Annual step-up rate: {stepupRate.toFixed(2)}%
          </p>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border">
              <th className="py-3 pr-4 text-left text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Year
              </th>
              <th className="py-3 pr-4 text-left text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Age
              </th>
              <th className="py-3 pr-4 text-right text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Monthly SIP
              </th>
              <th className="py-3 pr-4 text-right text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                To Equity
              </th>
              <th className="py-3 pr-4 text-right text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                To Debt
              </th>
              <th className="py-3 text-right text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Allocation
              </th>
            </tr>
          </thead>
          <tbody>
            {displayItems.map((item) => (
              <tr
                key={item.year}
                className="border-b border-border/50 transition-colors hover:bg-secondary/30"
              >
                <td className="py-2.5 pr-4 text-foreground">{item.year}</td>
                <td className="py-2.5 pr-4 text-foreground">{item.age}</td>
                <td className="py-2.5 pr-4 text-right font-medium text-foreground">
                  {formatINR(item.monthly_sip)}
                </td>
                <td className="py-2.5 pr-4 text-right text-success">
                  {formatINR(item.sip_to_equity)}
                </td>
                <td className="py-2.5 pr-4 text-right text-chart-3">
                  {formatINR(item.sip_to_debt)}
                </td>
                <td className="py-2.5 text-right">
                  <span className="inline-flex items-center gap-1">
                    <span className="text-success">{item.equity_pct}%</span>
                    <span className="text-muted-foreground">/</span>
                    <span className="text-chart-3">{item.debt_pct}%</span>
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {schedule.length > 10 && (
        <button
          onClick={() => setExpanded(!expanded)}
          className="mt-4 flex items-center gap-1 text-sm font-medium text-primary hover:underline"
        >
          {expanded ? (
            <>
              Show Less <ChevronUp className="h-3.5 w-3.5" />
            </>
          ) : (
            <>
              Show All {schedule.length} Years{" "}
              <ChevronDown className="h-3.5 w-3.5" />
            </>
          )}
        </button>
      )}
    </div>
  )
}
