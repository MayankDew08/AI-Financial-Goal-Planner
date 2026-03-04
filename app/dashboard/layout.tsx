"use client"

import { useEffect } from "react"
import { useRouter } from "next/navigation"
import { AuthProvider, useAuth } from "@/lib/auth-context"
import { RetirementProvider } from "@/lib/retirement-context"
import { Sidebar } from "@/components/dashboard/sidebar"
import { Loader2 } from "lucide-react"

function DashboardGuard({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && !user) {
      router.replace("/login")
    }
  }, [loading, user, router])

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  if (!user) return null

  return (
    <div className="min-h-screen bg-background">
      <Sidebar />
      <main className="lg:pl-64">
        <div className="mx-auto max-w-6xl px-6 py-8 pt-16 lg:pt-8">
          {children}
        </div>
      </main>
    </div>
  )
}

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <AuthProvider>
      <RetirementProvider>
        <DashboardGuard>{children}</DashboardGuard>
      </RetirementProvider>
    </AuthProvider>
  )
}
