# Detailed Redis Latency Impact Report (From Terminal Flow)

## 1. Executive Summary
Redis is working and delivers a measurable latency reduction for repeated identical computations.

1. Cache miss time: 98.80 ms
2. Cache hit time: 24.81 ms
3. Absolute reduction: 73.99 ms
4. Relative reduction: 74.9%
5. Speedup: 4.0x
6. Correctness check: results_equal = True

For repeated requests with the same cache key payload, Redis reduces compute-path latency by about three-quarters.

---

## 2. What Was Actually Tested
A controlled benchmark was run in terminal with two layers:

1. Raw Redis round-trip latency
2. Application cache-wrapper latency (same helper used by backend code)

### Benchmark Inputs and Flow

1. Redis latency loop:
- 20x ping
- 20x get on key `bench:redis:latency`

2. Cache utility latency test:
- Namespace: `bench:goal`
- Payload:
  - `user_id`: `bench-user`
  - `age`: `30`
  - `income`: `100000`
- Compute function:
  - CPU-heavy loop over 1,500,000 iterations
- Run A:
  - Force delete cache key first
  - `get_or_set_cache` executes compute path (miss)
- Run B:
  - Same payload, same namespace
  - `get_or_set_cache` returns cached path (hit)

---

## 3. Raw Numbers Captured
From terminal output:

1. Redis ping median: 24.07 ms
2. Redis ping p95: 182.37 ms
3. Redis get median: 24.06 ms
4. Redis get p95: 24.81 ms

5. Cache miss: 98.80 ms
6. Cache hit: 24.81 ms
7. Speedup: 4.0x
8. results_equal: True

---

## 4. Derived Metrics (Calculated)

1. Absolute latency saved per repeated call:
- 98.80 - 24.81 = 73.99 ms

2. Percentage reduction:
- 73.99 / 98.80 = 74.9%

3. Hit-path throughput vs miss-path throughput:
- Miss throughput approx 1000 / 98.80 = 10.12 ops/sec
- Hit throughput approx 1000 / 24.81 = 40.31 ops/sec
- Throughput improvement approx 4.0x

4. Large-scale impact (illustrative):
- At 1,000,000 repeated hits, saved time approx 73,990 seconds approx 20.55 hours of compute-path time

---

## 5. Why Endpoint Response Sometimes Looks Similar
Redis optimizes only the cached segment. Requests can still include additional downstream work, such as:

1. Conflict engine execution
2. DB read/write operations
3. Serialization/deserialization
4. LLM/API inference (seconds-level)

So full endpoint latency may still be dominated by non-cached stages.

### Example From Logs
1. AI explanation call observed around 4.353834 s
2. AI explanation call observed around 5.114016 s

These are model-inference dominated timings, not Redis dominated.

---

## 6. Interpretation of Long "Future value calculated" Logs
The repeated log lines indicate substantial iterative computation in conflict and goal processing loops.

Implications:

1. That section is still executing fully in the endpoint path.
2. It may be intentionally uncached, or it runs after the cached retrieval.
3. Total response time may not collapse even though plan-fetch phase is faster.

This is expected unless conflict-engine output or other downstream stages are also cached.

---

## 7. Reliability and Data Quality

### Strengths
1. Same runtime environment and same Redis instance
2. Deterministic payload for miss-hit comparison
3. Directly uses project cache helper (`get_or_set_cache`)
4. Correctness validated with `results_equal = True`

### Limitations
1. Synthetic compute workload, not full endpoint stack
2. No multi-user concurrency stress in this run
3. Ping p95 includes an outlier (182.37 ms), likely network jitter

Overall confidence: High confidence that Redis cache integration is functioning and materially reducing repeated compute-path latency.

---

## 8. Practical Conclusion

1. Redis integration is successful.
2. Cached repeated workloads are about 75% faster on the measured path.
3. For bigger end-to-end API reduction, cache should target dominant latency contributors:
- Conflict-engine output for unchanged inputs
- LLM explanation responses for repeated same question/context
- Expensive DB aggregation snapshots where safe

---

## 9. Recommended Next Measurement Plan

1. Measure endpoint phases separately, not only full response:
- Cache lookup phase
- Compute phase
- Conflict phase
- AI phase

2. Collect per-endpoint p50 and p95 over 100 calls:
- First call cold
- Repeated calls warm with same payload

3. Report two performance tables:
- Plan-computation path (already showing 4.0x)
- Full endpoint path (showing remaining bottlenecks)
