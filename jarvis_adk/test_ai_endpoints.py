"""Test the new AI/ML API endpoints."""

import requests
import time

BASE_URL = "http://localhost:8001"

def test_clusters():
    print("\n1. Testing /ili/clusters endpoint...")
    response = requests.get(f"{BASE_URL}/ili/clusters?year=2022&epsilon=50&min_samples=3", timeout=30)
    if response.status_code == 200:
        data = response.json()
        print(f"   Found {len(data)} clusters")
        if data:
            first_cluster = list(data.keys())[0]
            print(f"   First cluster: {first_cluster}")
            print(f"   Details: {data[first_cluster]}")
        return True
    else:
        print(f"   ERROR: {response.status_code}")
        return False

def test_predict_growth():
    print("\n2. Testing /ili/predict-growth endpoint...")
    # Note: This requires an API key, will test without for now
    response = requests.get(
        f"{BASE_URL}/ili/predict-growth?pair=2015->2022&top_n=2&api_key=test&model=test&base_url=test",
        timeout=60
    )
    if response.status_code == 200:
        data = response.json()
        print(f"   Got {len(data)} predictions")
        if data and len(data) > 0:
            print(f"   First prediction: {data[0]}")
        return True
    else:
        print(f"   ERROR: {response.status_code}")
        return False

def test_risk_assessment():
    print("\n3. Testing /ili/risk-assessment endpoint...")
    # Note: This requires an API key, will test without for now
    response = requests.get(
        f"{BASE_URL}/ili/risk-assessment?api_key=test&model=test&base_url=test",
        timeout=60
    )
    if response.status_code == 200:
        data = response.json()
        print(f"   Risk level: {data.get('risk_level', 'N/A')}")
        print(f"   Action items: {len(data.get('action_items', []))}")
        return True
    else:
        print(f"   ERROR: {response.status_code}")
        return False

if __name__ == "__main__":
    print("Testing new AI/ML API endpoints...")
    print("Waiting for API to be ready...")
    
    # Wait for API to start
    for i in range(10):
        try:
            requests.get(f"{BASE_URL}/ili/summary", timeout=2)
            break
        except:
            time.sleep(1)
    
    # First load the data
    print("\n0. Loading ILI data...")
    response = requests.get(f"{BASE_URL}/ili/run-all", timeout=300)
    if response.status_code == 200:
        print("   Data loaded successfully")
    else:
        print(f"   ERROR loading data: {response.status_code}")
        exit(1)
    
    # Test endpoints
    results = []
    results.append(("Clusters", test_clusters()))
    results.append(("Growth Prediction", test_predict_growth()))
    results.append(("Risk Assessment", test_risk_assessment()))
    
    print("\n" + "="*50)
    print("SUMMARY:")
    for name, success in results:
        status = "✓" if success else "✗"
        print(f"  {status} {name}")
    print("="*50)
