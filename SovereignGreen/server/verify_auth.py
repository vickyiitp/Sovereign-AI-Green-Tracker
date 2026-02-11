import requests
import time

BASE_URL = "http://127.0.0.1:8003"

def test_auth_flow():
    print("\n--- Testing Authentication ---")
    
    # 1. Try to access chat without token
    try:
        resp = requests.post(f"{BASE_URL}/v1/chat", json={"message": "hello"})
        if resp.status_code == 401:
            print("✅ Protected endpoint rejected unauthenticated request (401)")
        else:
            print(f"❌ Protected endpoint failed to reject: {resp.status_code}")
    except Exception as e:
        print(f"❌ Connection error: {e}")

    # 2. Login to get token
    token = None
    try:
        resp = requests.post(f"{BASE_URL}/token", data={"username": "test_user", "password": "any"})
        if resp.status_code == 200:
            token = resp.json()["access_token"]
            print("✅ Login successful, token received")
        else:
            print(f"❌ Login failed: {resp.status_code}")
    except Exception as e:
        print(f"❌ Connection error: {e}")
        return

    # 3. Access with token
    if token:
        headers = {"Authorization": f"Bearer {token}"}
        try:
            resp = requests.post(f"{BASE_URL}/v1/chat", json={"message": "hello authenticated"}, headers=headers)
            if resp.status_code == 200:
                print("✅ Authenticated request successful")
            else:
                print(f"❌ Authenticated request failed: {resp.status_code} - {resp.text}")
        except Exception as e:
            print(f"❌ Connection error: {e}")

    return token

def test_pii_sanitization(token):
    print("\n--- Testing PII Sanitization ---")
    if not token:
        print("Skipping (no token)")
        return

    headers = {"Authorization": f"Bearer {token}"}
    message = "My email is test@example.com and phone is 123-456-7890"
    
    try:
        resp = requests.post(f"{BASE_URL}/v1/chat", json={"message": message}, headers=headers)
        if resp.status_code == 200:
            ai_answer = resp.json()["ai_answer"]
             # The mock AI echoes the input, so we check if the input in the echo is redacted
            if "[EMAIL_REDACTED]" in ai_answer and "[PHONE_REDACTED]" in ai_answer:
                print("✅ PII Redaction functioning")
            else:
                print(f"❌ PII LEAKED in response: {ai_answer}")
        else:
            print(f"❌ Request failed: {resp.status_code}")
    except Exception as e:
        print(f"❌ Connection error: {e}")

if __name__ == "__main__":
    token = test_auth_flow()
    test_pii_sanitization(token)
