import Link from "next/link"
import {
  Target,
  Brain,
  TrendingUp,
  Shield,
  GraduationCap,
  Home,
  Heart,
  Briefcase,
  ArrowRight,
} from "lucide-react"

function Navbar() {
  return (
    <header className="fixed top-0 left-0 right-0 z-50 border-b border-border/50 bg-background/80 backdrop-blur-md">
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
        <Link href="/" className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-md bg-primary">
            <Target className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-lg font-semibold text-foreground">
            GoalPath AI
          </span>
        </Link>
        <div className="flex items-center gap-3">
          <Link
            href="/login"
            className="rounded-md px-4 py-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
          >
            Sign In
          </Link>
          <Link
            href="/register"
            className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Get Started
          </Link>
        </div>
      </nav>
    </header>
  )
}

function HeroSection() {
  return (
    <section className="relative flex min-h-[90vh] flex-col items-center justify-center px-6 pt-20 text-center">
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute left-1/2 top-1/4 h-96 w-96 -translate-x-1/2 rounded-full bg-primary/5 blur-3xl" />
      </div>
      <div className="relative z-10 mx-auto max-w-4xl">
        <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-border bg-secondary/50 px-4 py-1.5 text-sm text-muted-foreground">
          <Brain className="h-4 w-4 text-primary" />
          AI-Powered Multi-Agent Financial Planning
        </div>
        <h1 className="text-balance text-4xl font-bold leading-tight tracking-tight text-foreground sm:text-5xl lg:text-6xl">
          Your Retirement,{" "}
          <span className="text-primary">Planned with Precision</span>
        </h1>
        <p className="mx-auto mt-6 max-w-2xl text-pretty text-lg leading-relaxed text-muted-foreground">
          GoalPath AI uses deterministic financial engines and intelligent agents
          to build personalized retirement plans -- corpus targets, SIP roadmaps,
          glide paths, and bucket strategies -- all tailored to your life.
        </p>
        <div className="mt-10 flex flex-col items-center gap-4 sm:flex-row sm:justify-center">
          <Link
            href="/register"
            className="flex items-center gap-2 rounded-lg bg-primary px-6 py-3 text-base font-semibold text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Start Planning
            <ArrowRight className="h-4 w-4" />
          </Link>
          <Link
            href="/login"
            className="flex items-center gap-2 rounded-lg border border-border bg-secondary/50 px-6 py-3 text-base font-medium text-foreground transition-colors hover:bg-secondary"
          >
            I Already Have an Account
          </Link>
        </div>
      </div>
    </section>
  )
}

const features = [
  {
    icon: Target,
    title: "Corpus Calculation",
    description:
      "Inflation-adjusted retirement corpus based on your current expenses, income, and post-retirement needs.",
  },
  {
    icon: TrendingUp,
    title: "SIP Roadmap",
    description:
      "Monthly SIP with annual step-up, split between equity and debt based on your years to retirement.",
  },
  {
    icon: Shield,
    title: "Glide Path Strategy",
    description:
      "Dynamic asset allocation that shifts from growth to capital preservation as retirement approaches.",
  },
  {
    icon: Brain,
    title: "AI Chat Assistant",
    description:
      "Ask questions about your plan in plain language. Our AI explains every number without making up new ones.",
  },
]

function FeaturesSection() {
  return (
    <section className="px-6 py-24">
      <div className="mx-auto max-w-6xl">
        <div className="mb-16 text-center">
          <h2 className="text-balance text-3xl font-bold text-foreground sm:text-4xl">
            Everything You Need for Retirement Planning
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-pretty text-muted-foreground">
            Our retirement agent computes a complete financial plan, then lets
            you explore it interactively with AI-powered explanations.
          </p>
        </div>
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {features.map((f) => (
            <div
              key={f.title}
              className="group rounded-xl border border-border bg-card p-6 transition-colors hover:border-primary/30"
            >
              <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                <f.icon className="h-5 w-5 text-primary" />
              </div>
              <h3 className="mb-2 font-semibold text-foreground">{f.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">
                {f.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

function HowItWorksSection() {
  const steps = [
    {
      step: "01",
      title: "Create Your Profile",
      description:
        "Enter your income, expenses, age, and family details. This forms the foundation of your plan.",
    },
    {
      step: "02",
      title: "Set Retirement Parameters",
      description:
        "Choose your target retirement age, expected returns, existing corpus, and post-retirement expense ratio.",
    },
    {
      step: "03",
      title: "Get Your Plan",
      description:
        "Our engine computes your corpus target, monthly SIP, glide path, and bucket strategy in seconds.",
    },
    {
      step: "04",
      title: "Explore with AI",
      description:
        "Ask the AI assistant anything about your plan. It explains using only the computed numbers -- never guesses.",
    },
  ]

  return (
    <section className="border-t border-border px-6 py-24">
      <div className="mx-auto max-w-5xl">
        <div className="mb-16 text-center">
          <h2 className="text-balance text-3xl font-bold text-foreground sm:text-4xl">
            How It Works
          </h2>
        </div>
        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((s) => (
            <div key={s.step} className="relative">
              <span className="text-4xl font-bold text-primary/20">
                {s.step}
              </span>
              <h3 className="mt-2 font-semibold text-foreground">{s.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                {s.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

const comingSoon = [
  {
    icon: GraduationCap,
    title: "Education Planning",
    description: "Plan for your children's higher education costs.",
  },
  {
    icon: Home,
    title: "Home Purchase",
    description: "Down payment and EMI planning for your dream home.",
  },
  {
    icon: Heart,
    title: "Wedding Planning",
    description: "Financial preparation for family weddings.",
  },
  {
    icon: Briefcase,
    title: "Emergency Fund",
    description: "Build a safety net for unexpected expenses.",
  },
]

function ComingSoonSection() {
  return (
    <section className="border-t border-border px-6 py-24">
      <div className="mx-auto max-w-6xl">
        <div className="mb-16 text-center">
          <h2 className="text-balance text-3xl font-bold text-foreground sm:text-4xl">
            More Agents, Coming Soon
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-pretty text-muted-foreground">
            Retirement is just the beginning. We are building specialized AI
            agents for every major financial goal.
          </p>
        </div>
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {comingSoon.map((item) => (
            <div
              key={item.title}
              className="rounded-xl border border-dashed border-border bg-card/50 p-6 opacity-60"
            >
              <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-lg bg-muted">
                <item.icon className="h-5 w-5 text-muted-foreground" />
              </div>
              <h3 className="mb-2 font-semibold text-foreground">
                {item.title}
              </h3>
              <p className="text-sm leading-relaxed text-muted-foreground">
                {item.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

function Footer() {
  return (
    <footer className="border-t border-border px-6 py-8">
      <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 sm:flex-row">
        <div className="flex items-center gap-2">
          <div className="flex h-6 w-6 items-center justify-center rounded bg-primary">
            <Target className="h-3.5 w-3.5 text-primary-foreground" />
          </div>
          <span className="text-sm font-medium text-foreground">
            GoalPath AI
          </span>
        </div>
        <p className="text-xs text-muted-foreground">
          GoalPath AI is not a SEBI-registered advisor. All projections are
          estimates based on your assumptions. Consult a qualified financial
          planner before making investment decisions.
        </p>
      </div>
    </footer>
  )
}

export default function LandingPage() {
  return (
    <main className="min-h-screen">
      <Navbar />
      <HeroSection />
      <FeaturesSection />
      <HowItWorksSection />
      <ComingSoonSection />
      <Footer />
    </main>
  )
}
