"""
Load testing for Financial Planning API backend.
Simulates realistic user behavior: registration → login → plan creation → chat interactions.
Run with: locust -f locustfile.py --host=http://localhost:8000
"""

import random
from locust import HttpUser, task, between, events
from locust.exception import StopUser
from datetime import datetime


class FinancialPlanningUser(HttpUser):
    """
    Simulates a financial planning API user with realistic behavior patterns.
    """
    wait_time = between(2, 8)  # 2-8 seconds between requests
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.access_token = None
        self.user_email = None
        self.session_id = f"session_{random.randint(10000, 99999)}"
        self.user_id = None
        
    def on_start(self):
        """Runs once per user - handles registration and login."""
        try:
            # Health check first
            with self.client.get("/", catch_response=True, name="health_check") as response:
                if response.status_code != 200:
                    response.failure(f"Backend unreachable: {response.status_code}")
                    raise StopUser()
                response.success()
            
            if not self.register_user():
                raise StopUser()
            if not self.login_user():
                raise StopUser()
        except Exception as e:
            print(f"[ERROR] on_start failed: {e}")
            raise StopUser()
    
    def register_user(self):
        """Create a new user account."""
        email = f"user_{random.randint(100000, 999999)}@test.com"
        phone = str(random.randint(1000000000, 9999999999))[-10:]
        password = "TestPass@123"
        marital_status = random.choice(["Single", "Married"])
        
        payload = {
            "name": f"Test User {random.randint(1, 10000)}",
            "email": email,
            "phone_number": phone,
            "password": password,
            "current_monthly_expenses": random.uniform(30000, 150000),
            "inflation_rate": random.uniform(5.0, 8.0),
            "marital_status": marital_status,
            "age": random.randint(25, 55),
            "current_income": random.uniform(500000, 5000000),
            "income_raise_pct": random.uniform(2.0, 8.0),
        }

        # Required by backend validator when married.
        if marital_status == "Married":
            payload["spouse_age"] = random.randint(23, 55)
            payload["spouse_income"] = random.uniform(300000, 3000000)
            payload["spouse_income_raise_pct"] = random.uniform(2.0, 8.0)
        
        with self.client.post(
            "/user/",
            data=payload,
            catch_response=True,
            name="/user/ - register"
        ) as response:
            if response.status_code in [200, 201]:
                try:
                    resp_data = response.json()
                    self.user_email = email
                    self.user_id = resp_data.get("user_id")
                    response.success()
                    return True
                except Exception as e:
                    response.failure(f"Registration parse failed: {e}")
                    return False

            response.failure(f"Registration failed {response.status_code}: {response.text[:160]}")
            return False
    
    def login_user(self):
        """Authenticate and get access token."""
        payload = {
            "username": self.user_email,
            "password": "TestPass@123"
        }

        with self.client.post(
            "/auth/login",
            data=payload,
            catch_response=True,
            name="/auth/login"
        ) as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    token = data.get("access_token")
                    if not token:
                        response.failure("Login succeeded but token missing")
                        return False
                    self.access_token = token
                    response.success()
                    return True
                except Exception as e:
                    response.failure(f"Login parse failed: {e}")
                    return False

            response.failure(f"Login failed {response.status_code}: {response.text[:160]}")
            return False
    
    def get_headers(self):
        """Return headers with authentication token."""
        return {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
    
    # ========== AUTHENTICATED MATH ENDPOINTS ==========
    
    @task(1)
    def calculate_future_value(self):
        """Math endpoint load: future value goal."""
        if not self.access_token:
            return
            
        payload = {
            "principal": random.uniform(100000, 1000000),
            # NOTE: backend schema key is intentionally spelled 'infation_rate'
            "infation_rate": random.uniform(5.0, 7.0),
            "years": random.randint(5, 30),
        }
        
        with self.client.post(
            "/calculation/future_value_goal",
            json=payload,
            catch_response=True,
            name="/calculation/future_value_goal"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Status {response.status_code}: {response.text[:160]}")
    
    @task(1)
    def calculate_blended_return(self):
        """Math endpoint load: blended return."""
        if not self.access_token:
            return

        equity_pct = random.uniform(40.0, 80.0)
        payload = {
            "equity_pct": equity_pct,
            "debt_pct": 100.0 - equity_pct,
            "return_equity": random.uniform(10.0, 14.0),
            "return_debt": random.uniform(6.0, 8.0),
        }

        with self.client.post(
            "/calculation/blended_return",
            json=payload,
            catch_response=True,
            name="/calculation/blended_return"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Status {response.status_code}: {response.text[:160]}")


# ========== EVENT HANDLERS ==========

@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Log when test starts."""
    print("\n" + "="*60)
    print("🚀 FINANCIAL PLANNING API - LOAD TEST STARTED")
    print("="*60)
    print(f"Timestamp: {datetime.now().isoformat()}")
    print(f"Target: {environment.host}")
    print("="*60 + "\n")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Log when test ends with summary."""
    print("\n" + "="*60)
    print("🛑 LOAD TEST COMPLETED")
    print("="*60)
    stats = environment.stats
    print(f"Total requests: {stats.total.num_requests}")
    print(f"Total failures: {stats.total.num_failures}")
    print(f"Avg response time: {stats.total.avg_response_time:.2f}ms")
    print(f"Max response time: {stats.total.max_response_time:.2f}ms")
    print("="*60 + "\n")


# USAGE INSTRUCTIONS:
# ⚠️  CRITICAL: Backend MUST be running before starting Locust tests!
# 
# 1. Start backend in ONE terminal:
#    cd Backend
#    python -m uvicorn app.main:app --reload
#    (Wait until you see "Application startup complete" message)
#
# 2. VERIFY backend is running (in another terminal):
#    curl http://localhost:8000/
#    (Should return: {"Message": "Welcome to Financial Planning API"})
#
# 3. Only then start Locust in a THIRD terminal:
#    locust -f locustfile.py --host=http://localhost:8000
#
# 4. Open browser: http://localhost:8089
#    Configure: 20 users, 5 spawn rate, duration as needed
#
# KEY METRICS TO MONITOR:
# - Response times under load
# - Failure rates (should be <1%)
# - Throughput (requests/second)
# - Peak load handling capacity
#
# DEBUGGING:
# - If you see "Status 0" errors: Backend is NOT running or crashed.
# - If you see 422: payload keys do not match schema.
# - This file intentionally tests math endpoints only; goal/chat endpoints invoke AI
#   services and can produce server-side 500 under heavy load due to external deps.

    