import requests
import time
import sys

def test_chat():
    url = "http://127.0.0.1:8002/v1/chat"
    headers = {
        "x-goog-region": "asia-south1",
        "Content-Type": "application/json"
    }
    data = {
        "message": "Hello world",
        "model": "gemini-pro"
    }

    try:
        print(f"Sending request to {url}...")
        response = requests.post(url, json=data, headers=headers)
        response.raise_for_status()
        result = response.json()
        
        print("\n--- Response ---")
        print(result)
        
        metrics = result.get("metrics", {})
        engine = metrics.get("energy_engine")
        carbon = metrics.get("carbon_grams", 0.0)
        
        print(f"\nEngine: {engine}")
        print(f"Carbon: {carbon}")
        
        if (engine == "Native C" or engine == "Python Fallback") and carbon > 0:
            print(f"\nSUCCESS: {engine} is working and calculating carbon!")
            sys.exit(0)
        else:
            print(f"\nFAILURE: Verification Failed.")
            print(f"Expected Engine: Native C or Python Fallback. Got: '{engine}'")
            print(f"Expected Carbon > 0. Got: {carbon}")
            sys.exit(1)
            
    except requests.exceptions.ConnectionError:
        print("\nFAILURE: Could not connect to server. Is it running?")
        sys.exit(1)
    except Exception as e:
        print(f"\nFAILURE: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # Wait a bit for server to start if run immediately after
    time.sleep(2)
    test_chat()
