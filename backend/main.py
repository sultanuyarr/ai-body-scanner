import os
import json
import uuid
import numpy as np
import cv2
from datetime import datetime
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from ai_engine.body_analyzer import BodyAnalyzer

# Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate("service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
COLLECTION = "analyses"
USERS_COLLECTION = "users"

app = FastAPI()
analyzer = BodyAnalyzer()

@app.post("/register")
async def register(
    email: str = Form(...),
    password: str = Form(...),
    name: str = Form(...),
    age: int = Form(...),
    gender: str = Form(...),
    weight: float = Form(...),
    height: float = Form(...),
    goal: str = Form(...)
):
    print(f"AI_DEBUG: Backend - Registering user {email}")
    # Check if user already exists
    doc = db.collection(USERS_COLLECTION).document(email.lower()).get()
    if doc.exists:
        raise HTTPException(status_code=400, detail="Bu e-posta adresi zaten kullanımda.")
    
    user_record = {
        "email": email.lower(),
        "password": password,
        "name": name,
        "age": age,
        "gender": gender,
        "weight": weight,
        "height": height,
        "goal": goal,
        "registeredAt": datetime.now().isoformat()
    }
    
    db.collection(USERS_COLLECTION).document(email.lower()).set(user_record)
    return {"success": True, "user": user_record}

@app.post("/login")
async def login(
    email: str = Form(...),
    password: str = Form(...)
):
    print(f"AI_DEBUG: Backend - Logging in user {email}")
    doc = db.collection(USERS_COLLECTION).document(email.lower()).get()
    if not doc.exists:
        raise HTTPException(status_code=400, detail="E-posta adresi veya şifre hatalı.")
    
    user_data = doc.to_dict()
    if user_data["password"] != password:
        raise HTTPException(status_code=400, detail="E-posta adresi veya şifre hatalı.")
    
    return {"success": True, "user": user_data}

# Allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def save_record(record: dict):
    db.collection(COLLECTION).document(record["id"]).set(record)

def load_all_records():
    docs = db.collection(COLLECTION).order_by("date", direction=firestore.Query.DESCENDING).stream()
    return [doc.to_dict() for doc in docs]

def load_record_by_id(analysis_id: str):
    doc = db.collection(COLLECTION).document(analysis_id).get()
    if doc.exists:
        return doc.to_dict()
    return None

@app.post("/analysis")
async def analyze_photo(
    photo: UploadFile = File(...),
    userId: str = Form("default_user"),
    height: str = Form("0"),
    weight: str = Form("0"),
    age: str = Form("0"),
    gender: str = Form(""),
    goal: str = Form("")
):
    print(f"AI_DEBUG: Backend - Received request for {userId}")
    print(f"AI_DEBUG: Backend - Form data: H={height}, W={weight}, Age={age}, Gender={gender}, Goal={goal}")
    try:
        if not photo or not photo.filename:
            print("AI_DEBUG: Backend - Invalid photo payload")
            return JSONResponse(
                status_code=200,
                content={"success": False, "error": "invalid_photo"}
            )

        # Convert string inputs
        try:
            height_cm = float(height)
            weight_kg = float(weight)
            age_int = int(age)
        except ValueError:
            print("AI_DEBUG: Backend - Invalid numeric fields")
            return JSONResponse(status_code=200, content={"success": False, "error": "invalid_photo"})

        # Read image into memory
        print(f"AI_DEBUG: Backend - Processing file {photo.filename} ({photo.size} bytes)")
        file_bytes = np.frombuffer(await photo.read(), np.uint8)
        image = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

        if image is None:
            print("AI_DEBUG: Backend - Failed to decode image")
            return JSONResponse(status_code=200, content={"success": False, "error": "invalid_photo"})

        # Run AI Analysis
        print("AI_DEBUG: Backend - Starting real AI analysis pipeline...")
        result = analyzer.analyze(
            image=image,
            height_cm=height_cm,
            weight_kg=weight_kg,
            age=age_int,
            gender=gender,
            goal=goal
        )

        if not result.get("success", False):
            print(f"AI_DEBUG: Backend - Analysis failed: {result.get('message')}")
            return JSONResponse(
                status_code=200,
                content={"success": False, "error": "invalid_photo"}
            )
            
    except Exception as e:
        print(f"AI_DEBUG: Backend - Unhandled Exception: {e}")
        return JSONResponse(
            status_code=200,
            content={"success": False, "error": "invalid_photo"}
        )

    print("AI_DEBUG: Backend - Analysis successful, saving record to Firestore.")
    analysis_id = str(uuid.uuid4())
    record = {
        "id": analysis_id,
        "userId": userId,
        "date": datetime.now().isoformat(),
        "bmi": result["bmi"],
        "bodyFatPct": result["bodyFatPct"],
        "leanMassKg": result["leanMassKg"],
        "riskLevel": result["riskLevel"],
        "calories": result["calories"],
        "macros": result["macros"],
        "dietPlan": result["dietPlan"],
        "workoutPlan": result["workoutPlan"],
        "confidenceScore": result["confidenceScore"],
        "debug": result["debug"]
    }
    
    # Save to Firestore
    save_record(record)
    print(f"AI_DEBUG: Firestore - Record saved with id: {analysis_id}")

    return {
        "success": True,
        **record
    }

@app.get("/analysis/history")
async def get_history():
    return load_all_records()

@app.get("/analysis/{id}")
async def get_analysis_by_id(id: str):
    record = load_record_by_id(id)
    if record:
        return record
    raise HTTPException(status_code=404, detail="Analysis not found")
