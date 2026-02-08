"""Simple test of new endpoints."""
import requests
import time

BASE_URL = "http://localhost:8001"

print("Waiting for API...")
time.sleep(2)

# First load data
print("\n1. Loading ILI data...")
r = requests.get(f"{BASE_URL}/ili/run-all", timeout=300)
print(f"   Status: {r.status_code}")

# Test clusters
print("\n2. Testing clusters endpoint...")
r = requests.get(f"{BASE_URL}/ili/clusters?year=2022&epsilon=50&min_samples=3", timeout=30)
print(f"   Status: {r.status_code}")
if r.status_code == 200:
    data = r.json()
    print(f"   Found {len(data)} clusters")
    if data:
        first = list(data.values())[0]
        print(f"   First cluster has {first['member_count']} anomalies")

print("\nAll tests passed!" if r.status_code == 200 else "\nSome tests failed")
