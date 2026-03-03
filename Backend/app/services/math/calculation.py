
from app.models.calculation import (
    FutureValue, 
    BlendedReturn, 
    RequiredAnnualSavings, 
    SuggestedAllocation,
    CheckFeasibility,
    CheckRebalancing,
    SIPRequest,
    GlidePathRequest,
    RebalanceRequest
)



def future_value_goal(data: FutureValue):
    P = data.principal
    inflation = data.infation_rate/100
    years = data.years
    
    future_value = P * ((1 + inflation) ** years)
    return {"future_value": future_value}


def blended_return(data: BlendedReturn):
    equity_pct = data.equity_pct/100
    debt_pct = data.debt_pct/100
    re = data.return_equity
    rd = data.return_debt
    
    blended = (equity_pct * re) + (debt_pct * rd)
    return {"blended_return": blended}


def required_annual_saving(data: RequiredAnnualSavings):
    FV_goal = data.future_value
    r = data.return_rate/100
    years = data.years
    current_savings = 0
    
    if r == 0:
        required_saving = (FV_goal - current_savings) / years
    else:
        required_saving = (FV_goal - current_savings * ((1 + r) ** years)) / (((1 + r) ** years - 1) / r)
    
    return {"required_annual_saving": required_saving}


def suggest_allocation(data: SuggestedAllocation):
    years = data.years
    risk = data.risk
    
    if years < 3:
        equity_pct = 20
    elif years < 7:
        equity_pct = 50
    else:
        equity_pct = 70
    
    if risk.lower() == "low":
        equity_pct = max(0, equity_pct - 20)
    elif risk.lower() == "high":
        equity_pct = min(100, equity_pct + 20)
    
    debt_pct = 100 - equity_pct
    
    return {"equity_allocation": equity_pct, "debt_allocation": debt_pct}


def check_feasibility(data: CheckFeasibility):
    annual_saving_required = data.annual_saving_required
    max_possible_saving = data.max_possible_saving
    
    feasible = annual_saving_required <= max_possible_saving
    
    return {"feasible": feasible, "shortfall": max(0, annual_saving_required - max_possible_saving)}



def check_rebalancing(data: CheckRebalancing):
    planned_alloc = data.planned_alloc
    current_alloc = data.current_alloc
    threshold = data.threshold
    
    needs_rebalancing = False
    deviations = {}
    
    for key in planned_alloc:
        if key in current_alloc:
            deviation = abs(planned_alloc[key] - current_alloc[key])
            deviations[key] = deviation
            if deviation > threshold:
                needs_rebalancing = True
    
    return {"needs_rebalancing": needs_rebalancing, "deviations": deviations}

# Phase 1 Implementation

def calculate_sip(data: SIPRequest):
    """
    Calculates initial monthly SIP with step-up adjusted for inflation and salary hike.
    Step-up rate derived: g = ((1 + income_raise_pct) / (1 + inflation_rate)) - 1
    Formula: PMT = (Target * (r - g)) / (((1+r)^N - (1+g)^N) * (1+r))
    """
    target_corpus = data.target_corpus
    r = data.pre_ret_return / 100
    inflation_rate = data.inflation_rate / 100
    income_raise_pct = data.income_raise_pct / 100
    n_years = data.years_to_goal

    # Derive real step-up rate from income growth adjusted for inflation
    g = ((1 + income_raise_pct) / (1 + inflation_rate)) - 1
    
    # Prevent division by zero if r ≈ g
    if abs(r - g) < 1e-9:
        g += 1e-9

    numerator = target_corpus * (r - g)
    denominator = (((1 + r) ** n_years) - ((1 + g) ** n_years)) * (1 + r)
    
    starting_sip = (numerator / denominator) / 12
    
    return {"starting_monthly_investment": round(starting_sip, 2)}

def calculate_glide_path(data: GlidePathRequest):
    """
    Generates a year-by-year schedule of Equity/Debt ratio.
    Formula: Equity Weight (E_t) = E_start - ( (E_start - E_end) / (T) ) * (t)
    t = current year of plan (0 to T)
    T = Total years (goal_age - current_age)
    """
    current_age = data.current_age
    goal_age = data.goal_age
    e_start = data.start_equity_percent
    e_end = data.end_equity_percent
    
    total_years = goal_age - current_age
    if total_years <= 0:
        return {"yearly_allocation_table": []}

    schedule = []
    # t moves from 0 to total_years
    for t in range(total_years + 1): # Include the goal year? "between now and the goal year N"
        # If t=0, equity = start. If t=T, equity = end.
        equity_weight = e_start - ((e_start - e_end) / total_years) * t
        debt_weight = 100 - equity_weight
        
        schedule.append({
            "year": current_age + t,
            "age": current_age + t,
            "equity_percent": round(equity_weight, 2),
            "debt_percent": round(debt_weight, 2)
        })
        
    return {"yearly_allocation_table": schedule}

def check_portfolio_rebalance(data: RebalanceRequest):
    """
    Monitors portfolio drift. 5/25 Rule.
    1. Calculate Actual Ratio (Equity %)
    2. Calculate Drift = |Actual - Target|
    3. Trigger:
       - If Target >= 20%: Suggest if Drift > 5% (absolute percentage points)
       - If Target < 20%: Suggest if Drift / Target > 0.25 (25% relative deviation)
         Wait, Prompt says:
         "If the Equity domain is a large part of the portfolio (Target > 20%), suggest rebalancing if Drift > 5%."
         "If it is a small domain (Target < 20%), suggest rebalancing if Drift > 25%." (Ambiguous: 25% absolute or relative?)
         Common 5/25 rule: 
         - Absolute drift of 5% (e.g. 60% -> 65%)
         - OR Relative drift of 25% of the target allocation (e.g. 10% -> 12.5%)
         
         Prompt says "suggest rebalancing if Drift > 25%". Given the context of "small domain", and the name 5/25, it usually implies relative deviation for small asset classes.
         BUT, "Drift > 25%" syntax implies absolute drift in the prompt's context of "Drift = |Actual - Target|".
         However, 25% absolute drift on a <20% portfolio is impossible (it would negative or huge).
         So for small domain, it MUST be relative. 
         Let's assume:
         Condition 1 (Large): |Actual - Target| > 5 (percentage points)
         Condition 2 (Small): |Actual - Target| > 0.25 * Target
         
         Let's stick literally to the prompt text if possible?
         "If it is a small domain (Target < 20%), suggest rebalancing if Drift > 25%."
         If Target is 10%, Drift > 25% means Actual is >35% or <-15%? No.
         It means Drift (absolute) > 25. Which is huge.
         So it implies Relative Drift.
         
         Let's implement:
         actual_equity_ratio = Equity / Total
         target = data.current_year_target_ratio (decimal)
         
         drift = abs(actual - target) (decimal)
         
         if target > 0.20:
             chk = drift > 0.05
         else:
             chk = drift > (0.25 * target)
    """
    current_equity = data.current_equity_value
    current_debt = data.current_debt_value
    target_equity_ratio = data.current_year_target_ratio # decimal, e.g. 0.60
    
    total_portfolio = current_equity + current_debt
    if total_portfolio == 0:
        return {"rebalance_required": False, "suggested_move_amount": 0, "message": "Empty portfolio"}
        
    actual_equity_ratio = current_equity / total_portfolio
    drift = abs(actual_equity_ratio - target_equity_ratio)
    
    rebalance_required = False
    
    # 5/25 Rule
    if target_equity_ratio > 0.20:
        # Large domain: Absolute drift > 5%
        if drift > 0.05:
            rebalance_required = True
    else:
        # Small domain: Relative drift > 25%
        if drift > (0.25 * target_equity_ratio):
            rebalance_required = True
            
    suggested_move = 0
    if rebalance_required:
        # Calculate amount to move to restore target
        # Target Equity = Total * Target Ratio
        # Move = Target Equity - Actual Equity
        target_equity_val = total_portfolio * target_equity_ratio
        suggested_move = target_equity_val - current_equity
        # Positive means Buy Equity (Move from Debt to Equity)
        # Negative means Sell Equity (Move from Equity to Debt)
        
    return {
        "rebalance_required": rebalance_required,
        "suggested_move_amount": round(suggested_move, 2),
        "current_equity_ratio": round(actual_equity_ratio, 4),
        "target_equity_ratio": target_equity_ratio,
        "drift": round(drift, 4)
    }
