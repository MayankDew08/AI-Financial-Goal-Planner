"use client"

import { createContext, useContext, useState, type ReactNode } from "react"
import type { RetirementPlanResult } from "./api"

interface RetirementContextType {
  plan: RetirementPlanResult | null
  setPlan: (plan: RetirementPlanResult | null) => void
}

const RetirementContext = createContext<RetirementContextType | null>(null)

export function RetirementProvider({ children }: { children: ReactNode }) {
  const [plan, setPlan] = useState<RetirementPlanResult | null>(null)

  return (
    <RetirementContext.Provider value={{ plan, setPlan }}>
      {children}
    </RetirementContext.Provider>
  )
}

export function useRetirement() {
  const ctx = useContext(RetirementContext)
  if (!ctx) throw new Error("useRetirement must be used within RetirementProvider")
  return ctx
}
