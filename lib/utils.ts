import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatINR(value: number): string {
  const isNeg = value < 0
  const abs = Math.abs(value)
  const intPart = Math.floor(abs)
  const decPart = (abs - intPart).toFixed(2).split(".")[1]
  const s = String(intPart)
  let formatted: string
  if (s.length <= 3) {
    formatted = s
  } else {
    const last3 = s.slice(-3)
    let remaining = s.slice(0, -3)
    const groups: string[] = []
    while (remaining.length > 2) {
      groups.push(remaining.slice(-2))
      remaining = remaining.slice(0, -2)
    }
    if (remaining) groups.push(remaining)
    groups.reverse()
    formatted = groups.join(",") + "," + last3
  }
  const result = `₹${formatted}.${decPart}`
  return isNeg ? `-${result}` : result
}
