import asyncio
import aiohttp
import time
import statistics
import json

BASE_URL = "http://127.0.0.1:8003"
CONCURRENT_REQUESTS = 50

async def get_token(session):
    try:
        async with session.post(f"{BASE_URL}/token", data={"username": "stress_tester", "password": "any"}) as resp:
            if resp.status == 200:
                data = await resp.json()
                return data["access_token"]
            else:
                print(f"❌ Login Failed: {resp.status}")
                return None
    except Exception as e:
        print(f"❌ Login Error: {e}")
        return None

async def send_request(session, token, idx):
    headers = {"Authorization": f"Bearer {token}"}
    payload = {"message": f"Stress test request {idx}", "model": "gemini-pro"}
    
    start_time = time.perf_counter()
    try:
        async with session.post(f"{BASE_URL}/v1/chat", json=payload, headers=headers) as resp:
            end_time = time.perf_counter()
            duration = end_time - start_time
            
            if resp.status == 200:
                data = await resp.json()
                server_processing = data["metrics"]["processing_time_sec"]
                return {
                    "status": "success",
                    "total_latency": duration,
                    "server_processing": server_processing,
                    "client_overhead": duration - server_processing
                }
            elif resp.status == 429:
                 return {"status": "rate_limited"}
            else:
                return {"status": "error", "code": resp.status}
    except Exception as e:
        return {"status": "exception", "error": str(e)}

async def main():
    print(f"🚀 Starting Stress Test: {CONCURRENT_REQUESTS} concurrent requests to {BASE_URL}")
    
    async with aiohttp.ClientSession() as session:
        # 1. Login
        token = await get_token(session)
        if not token:
            print("❌ Aborting: Could not get auth token.")
            return

        print("✅ Authenticated. Launching requests...")
        
        # 2. Launch Concurrent Requests
        tasks = [send_request(session, token, i) for i in range(CONCURRENT_REQUESTS)]
        results = await asyncio.gather(*tasks)
        
        # 3. Analyze Results
        successes = [r for r in results if r["status"] == "success"]
        failures = [r for r in results if r["status"] != "success"]
        rate_limits = [r for r in results if r["status"] == "rate_limited"]
        
        print("\n📊 --- Results ---")
        print(f"Total Requests: {CONCURRENT_REQUESTS}")
        print(f"✅ Successful: {len(successes)}")
        print(f"⚠️ Rate Limited: {len(rate_limits)} (Expected if limit is low)")
        print(f"❌ Failed: {len(failures) - len(rate_limits)}")
        
        if successes:
            avg_total = statistics.mean([r["total_latency"] for r in successes])
            avg_server = statistics.mean([r["server_processing"] for r in successes])
            avg_overhead = statistics.mean([r["client_overhead"] for r in successes])
            
            print(f"\n⏱️  Latency Analysis (Average):")
            print(f"   - Total Client Latency: {avg_total:.4f}s")
            print(f"   - Server Processing Time (AI+C): {avg_server:.4f}s")
            print(f"   - Network/Client Overhead: {avg_overhead:.4f}s")
            
            if avg_overhead > 0.1:
                print("\n✅ 'Double-Clock' Logic Verified: Client overhead detected.")
            else:
                print("\n⚠️  Low network overhead (Localhost).")

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
