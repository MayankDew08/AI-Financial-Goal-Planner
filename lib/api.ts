const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"

export class ApiError extends Error {
  status: number
  constructor(message: string, status: number) {
    super(message)
    this.status = status
  }
}

function getToken(): string | null {
  if (typeof window === "undefined") return null
  return localStorage.getItem("goalpath_token")
}

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken()
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string>),
  }
  if (token) {
    headers["Authorization"] = `Bearer ${token}`
  }
  // Only add Content-Type if body is not FormData
  if (options.body && !(options.body instanceof FormData) && !(options.body instanceof URLSearchParams)) {
    headers["Content-Type"] = "application/json"
  }

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  })

  if (!res.ok) {
    let message = "An error occurred"
    try {
      const err = await res.json()
      message = err.detail || err.message || message
    } catch {
      // ignore parse error
    }
    throw new ApiError(message, res.status)
  }

  return res.json()
}

// ---- Auth ----

export async function apiLogin(email: string, password: string) {
  const body = new URLSearchParams()
  body.append("username", email)
  body.append("password", password)

  return apiFetch<{ access_token: string; token_type: string }>("/auth/login", {
    method: "POST",
    body,
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  })
}

export async function apiRegister(data: {
  name: string
  email: string
  phone_number: string
  password: string
  marital_status: string
  age: number
  current_income: number
  income_raise_pct: number
  current_monthly_expenses: number
  inflation_rate: number
  spouse_age?: number
  spouse_income?: number
  spouse_income_raise_pct?: number
}) {
  const form = new FormData()
  form.append("name", data.name)
  form.append("email", data.email)
  form.append("phone_number", data.phone_number)
  form.append("password", data.password)
  form.append("marital_status", data.marital_status)
  form.append("age", String(data.age))
  form.append("current_income", String(data.current_income))
  form.append("income_raise_pct", String(data.income_raise_pct))
  form.append("current_monthly_expenses", String(data.current_monthly_expenses))
  form.append("inflation_rate", String(data.inflation_rate))
  if (data.spouse_age !== undefined) form.append("spouse_age", String(data.spouse_age))
  if (data.spouse_income !== undefined) form.append("spouse_income", String(data.spouse_income))
  if (data.spouse_income_raise_pct !== undefined)
    form.append("spouse_income_raise_pct", String(data.spouse_income_raise_pct))

  return apiFetch<{ user_id: string; message: string }>("/user/", {
    method: "POST",
    body: form,
  })
}

export async function apiGetProfile() {
  return apiFetch<{
    id: string
    name: string
    email: string
    phone_number: string
    marital_status: string
    age: number
    current_income: number
    income_raise_pct: number
    current_monthly_expenses: number
    inflation_rate: number
    spouse_age: number | null
    spouse_income: number | null
    spouse_income_raise_pct: number | null
    onboarding_complete: boolean
    onboarding_step: number
  }>("/auth/profile")
}

export async function apiUpdateUser(
  userId: string,
  data: Record<string, string | number | undefined>
) {
  const form = new FormData()
  for (const [key, value] of Object.entries(data)) {
    if (value !== undefined && value !== null) {
      form.append(key, String(value))
    }
  }
  return apiFetch<{ user_id: string; message: string }>(`/user/${userId}`, {
    method: "PUT",
    body: form,
  })
}

// ---- Retirement ----

export interface RetirementFormData {
  retirement_age: number
  post_retirement_expense_pct: number
  post_retirement_return: number
  pre_retirement_return: number
  life_expectancy: number
  annual_post_retirement_income: number
  existing_corpus: number
  existing_monthly_sip: number
  sip_raise_pct: number
}

export interface CorpusResult {
  annual_expense_at_retirement: number
  income_at_retirement: number
  net_annual_withdrawal: number
  corpus_required: number
  fv_existing_corpus: number
  fv_existing_sip: number
  corpus_gap: number
  additional_monthly_sip_required: number
  feasible: boolean
}

export interface BucketAllocation {
  name: string
  size: number
  equity_pct: number
  debt_pct: number
  years_covered: string
  purpose: string
  equity_amount: number
  debt_amount: number
}

export interface GlidePathScheduleItem {
  year: number
  age: number
  years_to_retirement: number
  monthly_sip: number
  equity_pct: number
  debt_pct: number
  sip_to_equity: number
  sip_to_debt: number
}

export interface AllocationBand {
  equity_pct: number
  debt_pct: number
  from_age: number
  to_age: number
  from_year: number
  to_year: number
  years_in_band: number
}

export interface GlidePathResult {
  accumulation_years: number
  retirement_age: number
  sip_stepup_rate_pct: number
  allocation_bands: AllocationBand[]
  yearly_schedule: GlidePathScheduleItem[]
}

export interface BucketsResult {
  corpus_required: number
  total_allocated: number
  unallocated_buffer: number
  review_age: number
  retirement_duration_years: number
  buckets: {
    bucket_1: BucketAllocation
    bucket_2: BucketAllocation
    bucket_3: BucketAllocation
  }
  refill_rules: Record<string, string>
}

export interface RetirementPlanResult {
  status: "feasible" | "infeasible"
  corpus: CorpusResult
  feasibility: {
    feasible: boolean
    failure?: {
      year: number
      age: number
      monthly_household_income: number
      total_monthly_sip: number
      savings_ratio_pct: number
      message: string
    }
  }
  glide_path: GlidePathResult | null
  buckets: BucketsResult | null
}

export async function apiComputeRetirement(data: RetirementFormData) {
  const form = new FormData()
  form.append("retirement_age", String(data.retirement_age))
  form.append("post_retirement_expense_pct", String(data.post_retirement_expense_pct))
  form.append("post_retirement_return", String(data.post_retirement_return))
  form.append("pre_retirement_return", String(data.pre_retirement_return))
  form.append("life_expectancy", String(data.life_expectancy))
  form.append("annual_post_retirement_income", String(data.annual_post_retirement_income))
  form.append("existing_corpus", String(data.existing_corpus))
  form.append("existing_monthly_sip", String(data.existing_monthly_sip))
  form.append("sip_raise_pct", String(data.sip_raise_pct))

  return apiFetch<RetirementPlanResult>("/goals/retirement", {
    method: "POST",
    body: form,
  })
}

export async function apiExplainRetirementPlan(
  retirementPlan: RetirementPlanResult,
  userQuestion?: string
) {
  return apiFetch<{ explanation: string }>("/goals/explain_retirement_plan", {
    method: "POST",
    body: JSON.stringify({
      retirement_plan: retirementPlan,
      user_question: userQuestion || null,
    }),
  })
}
