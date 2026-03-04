import type { Metadata, Viewport } from "next"
import { Inter } from "next/font/google"
import "./globals.css"

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" })

export const metadata: Metadata = {
  title: "GoalPath AI - AI-Powered Financial Goal Planner",
  description:
    "Plan your retirement with AI-powered multi-agent financial planning. Get personalized corpus targets, glide path strategies, and bucket-based drawdown plans.",
}

export const viewport: Viewport = {
  themeColor: "#0B1426",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  )
}
