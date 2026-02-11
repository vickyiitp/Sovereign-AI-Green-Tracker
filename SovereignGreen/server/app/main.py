import os
import time
import ctypes
import platform
import re
from typing import Optional, Dict
from fastapi import FastAPI, Header, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from app.api import router as api_router
from app.auth import create_access_token, get_current_user
from datetime import timedelta, datetime

app = FastAPI(title="SovereignGreen API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Rate Limiting (In-Memory) ---
# Map: UserID -> [Timestamps]
_rate_limit_store: Dict[str, list] = {}
RATE_LIMIT_WINDOW = 60 # seconds
MAX_REQUESTS_PER_WINDOW = 10

def check_rate_limit(user_id: str):
    now = datetime.now()
    if user_id not in _rate_limit_store:
        _rate_limit_store[user_id] = []
    
    # Filter out old requests
    _rate_limit_store[user_id] = [t for t in _rate_limit_store[user_id] 
                                  if now - t < timedelta(seconds=RATE_LIMIT_WINDOW)]
    
    if len(_rate_limit_store[user_id]) >= MAX_REQUESTS_PER_WINDOW:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Try again later.")
    
    _rate_limit_store[user_id].append(now)

# --- PII Sanitizer ---
def sanitize_input(text: str) -> str:
    # 1. Email Redaction
    text = re.sub(r'[\w\.-]+@[\w\.-]+\.\w+', '[EMAIL_REDACTED]', text)
    # 2. Phone Number Redaction (Simple Pattern)
    text = re.sub(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', '[PHONE_REDACTED]', text)
    return text

# --- Phase 2: Native C Engine Integration ---
# Load the shared library
lib_name = "libenergy.dll" if platform.system() == "Windows" else "libenergy.so"
# app/main.py -> app/ -> server/ -> SovereignGreen/ -> native_engine/
base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
lib_path = os.path.join(base_dir, "native_engine", lib_name)

print(f"DEBUG: Attempting to load native engine from: {lib_path}")

c_lib = None
try:
    if not os.path.exists(lib_path):
        print(f"ERROR: Library file not found at {lib_path}")
        c_lib = None
    else:
        # On Windows, we sometimes need to add the directory to the DLL search path
        if platform.system() == "Windows":
             try:
                 os.add_dll_directory(os.path.dirname(lib_path))
             except Exception:
                 pass # Might already be added or not supported
             
        c_lib = ctypes.CDLL(lib_path)
        # Define signature: double calculate_impact(int tokens, float grid_intensity, int is_b200_gpu)
        c_lib.calculate_impact.argtypes = [ctypes.c_int, ctypes.c_float, ctypes.c_int]
        c_lib.calculate_impact.restype = ctypes.c_double
        print(f"Successfully loaded native engine from {lib_path}")
except Exception as e:
    print(f"Error loading native engine: {e}")
    c_lib = None

# --- Region Mapping (kg/kWh) ---
REGION_GRID_INTENSITY = {
    "asia-south1": 0.58,   # Mumbai (High)
    "us-central1": 0.42,   # Iowa (Medium)
    "europe-north1": 0.05, # Finland (Low/Green)
    "unknown": 0.475       # Global Average fallback
}

class ChatRequest(BaseModel):
    message: str
    model: str = "gemini-pro"

@app.get("/")
def read_root():
    return {"message": "SovereignGreen Backend Running"}

@app.post("/token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    # Dummy Auth: Accepts any username/password for Demo
    # In prod, check DB
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={"sub": form_data.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/v1/chat")
async def chat_endpoint(
    request: ChatRequest,
    x_goog_region: Optional[str] = Header(None, alias="x-goog-region"),
    x_request_id: Optional[str] = Header(None, alias="x-request-id"),
    current_user: str = Depends(get_current_user) # Require Auth
):
    # 0. Rate Limit
    check_rate_limit(current_user)

    # 1. Start "Double-Clock" (Total Time)
    start_time = time.perf_counter()

    # 2. PII Sanitization & Analysis
    safe_message = sanitize_input(request.message)
    
    # Analyze Request (Mock AI Processing)
    # In a real app, we would call Gemini/OpenAI here.
    # For now, we simulate network lag + processing.
    dummy_input_tokens = len(safe_message.split())
    if dummy_input_tokens == 0: dummy_input_tokens = 1
    
    # Simulate processing time (e.g., 0.5s to 2.0s)
    time.sleep(0.5) 
    
    ai_answer = f"I processed your request about '{safe_message}'. This is a mock response from the Green AI for user {current_user}."
    output_tokens = len(ai_answer.split())
    total_tokens = dummy_input_tokens + output_tokens

    # 3. Detect Region & Intensity
    region = x_goog_region or "unknown"
    grid_intensity = REGION_GRID_INTENSITY.get(region, REGION_GRID_INTENSITY["unknown"])

    # 4. Hardware Efficiency Check
    # Assume we use B200 if the model name suggests next-gen, else H100
    is_b200 = 1 if "b200" in request.model.lower() or "next" in request.model.lower() else 0

    # 5. Call C Engine for Impact
    carbon_grams = 0.0
    # Use global c_lib safely
    active_c_lib = globals().get('c_lib')

    if active_c_lib:
        try:
            carbon_grams = active_c_lib.calculate_impact(
                ctypes.c_int(total_tokens),
                ctypes.c_float(grid_intensity),
                ctypes.c_int(is_b200)
            )
        except Exception:
            active_c_lib = None # Fallback locally

    if not active_c_lib:
        # Fallback Logic (Same as C)
        energy_per_token = 0.003 if is_b200 else 0.05
        total_energy_kwh = (total_tokens * energy_per_token) / 1000.0
        carbon_grams = total_energy_kwh * grid_intensity * 1000.0

    # 6. Stop Clock & Calculate "Pure AI Time" (removing network overhead estimate)
    # For this mock, we assume network overhead is small or we just report the processing time.
    # Real "Double-Clock" would rely on client-side timestamps too, but here we measure server-side processing.
    end_time = time.perf_counter()
    duration_seconds = end_time - start_time

    # 7. Water Usage (Rough Estimate: 10ml - 50ml per query depending on heat/energy)
    # Simple formula: Carbon (g) * 20 (roughly water tracking energy)
    water_ml = carbon_grams * 20.0

    # 8. Efficiency Label
    efficiency_label = "Green" if carbon_grams < 0.1 else "Standard"
    if carbon_grams > 0.5: efficiency_label = "High Impact"

    return {
        "ai_answer": ai_answer,
        "metrics": {
            "tokens_processed": total_tokens,
            "region_detected": region,
            "grid_intensity_used": grid_intensity,
            "energy_engine": "Native C" if active_c_lib else "Python Fallback",
            "carbon_grams": round(carbon_grams, 4),
            "water_ml": round(water_ml, 2),
            "efficiency_label": efficiency_label,
            "processing_time_sec": round(duration_seconds, 3)
        }
    }

app.include_router(api_router, prefix="/api")

