"use client"

import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts"
import type { GlidePathResult } from "@/lib/api"

interface Props {
  glidePath: GlidePathResult
}

export function GlidePathChart({ glidePath }: Props) {
  const chartData = glidePath.yearly_schedule.map((item) => ({
    age: item.age,
    equity: item.equity_pct,
    debt: item.debt_pct,
  }))

  return (
    <div className="rounded-xl border border-border bg-card p-6">
      <h3 className="mb-2 text-lg font-semibold text-foreground">
        Pre-Retirement Glide Path
      </h3>
      <p className="mb-6 text-sm text-muted-foreground">
        How your asset allocation shifts from growth to preservation as
        retirement approaches.
      </p>

      <div className="h-72">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(217, 33%, 18%)" />
            <XAxis
              dataKey="age"
              label={{ value: "Age", position: "bottom", offset: -5, fill: "hsl(215, 20%, 65%)" }}
              tick={{ fill: "hsl(215, 20%, 65%)", fontSize: 12 }}
              stroke="hsl(217, 33%, 18%)"
            />
            <YAxis
              tick={{ fill: "hsl(215, 20%, 65%)", fontSize: 12 }}
              stroke="hsl(217, 33%, 18%)"
              domain={[0, 100]}
              tickFormatter={(v) => `${v}%`}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: "hsl(222, 40%, 10%)",
                border: "1px solid hsl(217, 33%, 18%)",
                borderRadius: "8px",
                color: "hsl(210, 40%, 98%)",
              }}
              formatter={(value: number) => [`${value}%`]}
            />
            <Legend wrapperStyle={{ color: "hsl(215, 20%, 65%)" }} />
            <Area
              type="monotone"
              dataKey="equity"
              stackId="1"
              name="Equity"
              fill="hsl(142, 71%, 45%)"
              fillOpacity={0.6}
              stroke="hsl(142, 71%, 45%)"
            />
            <Area
              type="monotone"
              dataKey="debt"
              stackId="1"
              name="Debt"
              fill="hsl(217, 91%, 60%)"
              fillOpacity={0.4}
              stroke="hsl(217, 91%, 60%)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Allocation Bands Summary */}
      <div className="mt-6">
        <h4 className="mb-3 text-sm font-semibold text-muted-foreground">
          Allocation Bands
        </h4>
        <div className="flex flex-col gap-2">
          {glidePath.allocation_bands.map((band, idx) => (
            <div
              key={idx}
              className="flex items-center justify-between rounded-lg bg-secondary/50 px-4 py-2.5"
            >
              <span className="text-sm text-foreground">
                Age {band.from_age}
                {band.from_age !== band.to_age ? ` - ${band.to_age}` : ""}
              </span>
              <div className="flex items-center gap-4">
                <span className="text-sm text-success">
                  {band.equity_pct}% Equity
                </span>
                <span className="text-sm text-chart-3">
                  {band.debt_pct}% Debt
                </span>
                <span className="text-xs text-muted-foreground">
                  ({band.years_in_band}yr{band.years_in_band > 1 ? "s" : ""})
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
