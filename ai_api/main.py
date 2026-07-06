from fastapi import FastAPI, Query, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests
import os
from dotenv import load_dotenv

# .env 불러오기
load_dotenv()

app = FastAPI()

# CORS 설정 (Flutter Web용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 개발 단계에서만 *, 배포 시엔 도메인 지정 권장
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 환경변수에서 API 키 불러오기
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
TMAP_API_KEY = os.getenv("TMAP_API_KEY")

# 기본 루트 엔드포인트
@app.get("/")
def read_root():
    return {
        "message": "FastAPI is running!",
        "google_key_loaded": bool(GOOGLE_API_KEY),
        "tmap_key_loaded": bool(TMAP_API_KEY),
    }

# ✅ Google Directions API (driving / walking / transit)
@app.get("/directions")
def get_directions(
    origin: str = Query(...),
    destination: str = Query(...),
    mode: str = Query("driving")  # driving, walking, transit
):
    url = "https://maps.googleapis.com/maps/api/directions/json"
    params = {
        "origin": origin,
        "destination": destination,
        "mode": mode,
        "key": GOOGLE_API_KEY
    }

    response = requests.get(url, params=params)
    return response.json()

class WalkRequest(BaseModel):
    startX: float
    startY: float
    endX: float
    endY: float
    startName: str
    endName: str

# ✅ Tmap 도보 경로 요청 API
@app.post("/tmap/walk")
def get_tmap_walk(body: WalkRequest = Body(...)):
    url = f"https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1"
    headers = {
        "appKey": TMAP_API_KEY,
        "Content-Type": "application/json",
    }

    payload = {
        "startX": body.startX,
        "startY": body.startY,
        "endX": body.endX,
        "endY": body.endY,
        "startName": body.startName,
        "endName": body.endName,
        "reqCoordType": "WGS84GEO",
        "resCoordType": "WGS84GEO"
    }

    response = requests.post(url, headers=headers, json=payload)
    return response.json()


