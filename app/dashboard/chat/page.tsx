"use client"

import { useState, useRef, useEffect } from "react"
import { useRetirement } from "@/lib/retirement-context"
import { apiExplainRetirementPlan } from "@/lib/api"
import ReactMarkdown from "react-markdown"
import { Send, Loader2, Brain, User, AlertCircle } from "lucide-react"
import Link from "next/link"

interface Message {
  role: "user" | "assistant"
  content: string
}

const suggestedQuestions = [
  "Give me a full walkthrough of my retirement plan",
  "Explain my SIP roadmap and how it steps up each year",
  "How does the glide path strategy work for me?",
  "Explain the bucket strategy and how it protects my retirement",
  "Is my plan feasible? What does the savings ratio mean?",
]

export default function ChatPage() {
  const { plan } = useRetirement()
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState("")
  const [loading, setLoading] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [messages])

  async function sendMessage(question: string) {
    if (!plan || !question.trim()) return

    const userMessage: Message = { role: "user", content: question.trim() }
    setMessages((prev) => [...prev, userMessage])
    setInput("")
    setLoading(true)

    try {
      const res = await apiExplainRetirementPlan(plan, question.trim())
      setMessages((prev) => [
        ...prev,
        { role: "assistant", content: res.explanation },
      ])
    } catch {
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content:
            "I encountered an error while generating the explanation. Please try again.",
        },
      ])
    } finally {
      setLoading(false)
    }
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    sendMessage(input)
  }

  if (!plan) {
    return (
      <div className="flex flex-col items-center justify-center py-24">
        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-chart-3/10">
          <Brain className="h-8 w-8 text-chart-3" />
        </div>
        <h2 className="mb-2 text-xl font-semibold text-foreground">
          No Plan Available
        </h2>
        <p className="mb-6 max-w-md text-center text-muted-foreground">
          The AI chat assistant needs a computed retirement plan to work with.
          Compute your plan first, then come back here to ask questions.
        </p>
        <Link
          href="/dashboard/retirement"
          className="rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90"
        >
          Go to Retirement Planner
        </Link>
      </div>
    )
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] flex-col lg:h-[calc(100vh-4rem)]">
      {/* Header */}
      <div className="mb-4 flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-chart-3/10">
          <Brain className="h-5 w-5 text-chart-3" />
        </div>
        <div>
          <h1 className="text-lg font-semibold text-foreground">
            GoalPath AI Chat
          </h1>
          <p className="text-xs text-muted-foreground">
            Ask anything about your retirement plan
          </p>
        </div>
      </div>

      {/* Chat Area */}
      <div className="flex-1 overflow-y-auto rounded-xl border border-border bg-card p-4">
        {messages.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center">
            <Brain className="mb-4 h-12 w-12 text-muted-foreground/30" />
            <p className="mb-6 text-center text-sm text-muted-foreground">
              Ask me anything about your retirement plan. I will explain using
              only the numbers from your computed plan.
            </p>
            <div className="flex max-w-lg flex-wrap justify-center gap-2">
              {suggestedQuestions.map((q) => (
                <button
                  key={q}
                  onClick={() => sendMessage(q)}
                  className="rounded-full border border-border bg-secondary/50 px-3 py-1.5 text-xs text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
                >
                  {q}
                </button>
              ))}
            </div>
            <div className="mt-6 flex items-start gap-2 rounded-lg bg-secondary/30 px-3 py-2">
              <AlertCircle className="mt-0.5 h-3.5 w-3.5 shrink-0 text-muted-foreground" />
              <p className="text-xs text-muted-foreground">
                This AI assistant explains your plan -- it does not provide
                financial advice. All numbers come from your computed plan.
              </p>
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            {messages.map((msg, idx) => (
              <div
                key={idx}
                className={`flex gap-3 ${
                  msg.role === "user" ? "justify-end" : ""
                }`}
              >
                {msg.role === "assistant" && (
                  <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-chart-3/10">
                    <Brain className="h-4 w-4 text-chart-3" />
                  </div>
                )}
                <div
                  className={`max-w-[80%] rounded-xl px-4 py-3 ${
                    msg.role === "user"
                      ? "bg-primary text-primary-foreground"
                      : "bg-secondary/50 text-foreground"
                  }`}
                >
                  {msg.role === "assistant" ? (
                    <div className="prose prose-sm prose-invert max-w-none [&_p]:mb-2 [&_p]:last:mb-0 [&_ul]:mb-2 [&_ol]:mb-2 [&_li]:text-sm [&_h1]:text-base [&_h1]:font-semibold [&_h2]:text-sm [&_h2]:font-semibold [&_h3]:text-sm [&_h3]:font-semibold [&_strong]:text-foreground">
                      <ReactMarkdown>{msg.content}</ReactMarkdown>
                    </div>
                  ) : (
                    <p className="text-sm">{msg.content}</p>
                  )}
                </div>
                {msg.role === "user" && (
                  <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-primary/10">
                    <User className="h-4 w-4 text-primary" />
                  </div>
                )}
              </div>
            ))}
            {loading && (
              <div className="flex gap-3">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-chart-3/10">
                  <Brain className="h-4 w-4 text-chart-3" />
                </div>
                <div className="flex items-center gap-2 rounded-xl bg-secondary/50 px-4 py-3">
                  <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">
                    Thinking...
                  </span>
                </div>
              </div>
            )}
            <div ref={bottomRef} />
          </div>
        )}
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="mt-3 flex gap-2">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask about your retirement plan..."
          disabled={loading}
          className="flex-1 rounded-lg border border-input bg-background px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring disabled:opacity-50"
        />
        <button
          type="submit"
          disabled={loading || !input.trim()}
          className="flex h-12 w-12 items-center justify-center rounded-lg bg-primary text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-50"
          aria-label="Send message"
        >
          <Send className="h-4 w-4" />
        </button>
      </form>
    </div>
  )
}
