# server.py
import face_recognition
import cv2
import os
import numpy as np
import pickle
import datetime
from fastapi import FastAPI, HTTPException, Request, UploadFile, File, BackgroundTasks, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from starlette.websockets import WebSocketDisconnect
import uvicorn
import pandas as pd
import logging
import time
import asyncio
from concurrent.futures import ThreadPoolExecutor

executor = ThreadPoolExecutor(max_workers=4)

# --- Global variables --- #
current_process = {
    "status": "idle",
    "progress": 0,
    "message": "",
    "start_time": None
}
attendance = {}  # {name: "P"/"A"}
data = None
is_capturing = False

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("FaceAttendanceServer")

# Folders
KNOWN_FACES_DIR = "known_faces"
ENCODINGS_FILE = "encodings.pkl"
ATTENDANCE_DIR = "attendance_records"
os.makedirs(KNOWN_FACES_DIR, exist_ok=True)
os.makedirs(ATTENDANCE_DIR, exist_ok=True)

# --- Utility functions --- #

def load_encodings():
    global data
    if not os.path.exists(ENCODINGS_FILE):
        logger.info("No encodings found. Creating one...")
        known_encodings, known_names = [], []
        for filename in os.listdir(KNOWN_FACES_DIR):
            if filename.endswith((".jpg", ".jpeg", ".png")):
                path = os.path.join(KNOWN_FACES_DIR, filename)
                image = face_recognition.load_image_file(path)
                encoding = face_recognition.face_encodings(image)
                if encoding:
                    known_encodings.append(encoding[0])
                    known_names.append(os.path.splitext(filename)[0])
                    logger.info(f"Encoded {filename}")
        if known_encodings:
            data = {"encodings": known_encodings, "names": known_names}
            with open(ENCODINGS_FILE, "wb") as f:
                pickle.dump(data, f)
            logger.info(f"Saved {len(known_names)} encodings")
        else:
            data = {"encodings": [], "names": []}
            logger.warning("No valid faces found.")
    else:
        with open(ENCODINGS_FILE, "rb") as f:
            data = pickle.load(f)
        logger.info(f"Loaded {len(data['names'])} encodings")

def recognize_faces(frame):
    global attendance
    if data is None or not data.get("encodings"):
        return

    rgb_img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    face_locations = face_recognition.face_locations(rgb_img)
    face_encodings = face_recognition.face_encodings(rgb_img, face_locations)

    for face_encoding in face_encodings:
        matches = face_recognition.compare_faces(data["encodings"], face_encoding, tolerance=0.4)
        face_distances = face_recognition.face_distance(data["encodings"], face_encoding)
        name = "Unknown"
        mark = "A"
        if len(face_distances) > 0:
            best_match_index = np.argmin(face_distances)
            if matches[best_match_index] and face_distances[best_match_index] < 0.4:
                name = data["names"][best_match_index]
                mark = "P"
        if name not in attendance:
            attendance[name] = mark
            logger.info(f"Recognized: {name} - {mark}")

def save_attendance_excel():
    global attendance
    today = datetime.date.today().strftime("%Y-%m-%d")
    file_path = os.path.join(ATTENDANCE_DIR, f"attendance_{today}.xlsx")
    df = pd.DataFrame(list(attendance.items()), columns=["Name", "Status"])
    df.to_excel(file_path, index=False)
    logger.info(f"Attendance saved to {file_path}")
    return file_path

def capture_attendance_frames(frame_limit=50, delay=0.1):
    """Capture frames from camera and update attendance & progress in real-time"""
    global is_capturing, attendance, current_process
    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
    frame_count = 0
    current_process.update({
        "status": "processing",
        "progress": 0,
        "message": "Starting attendance capture",
        "start_time": time.time()
    })

    try:
        while frame_count < frame_limit and is_capturing:
            ret, frame = cap.read()
            if not ret:
                logger.warning("Failed to read frame")
                break

            recognize_faces(frame)
            frame_count += 1

            # ✅ Stop early if at least one person recognized
            if any(v == "P" for v in attendance.values()):
                logger.info("Face recognized — stopping capture early")
                break

            # Update progress
            current_process.update({
                "progress": int((frame_count / frame_limit) * 100),
                "message": f"Captured {frame_count}/{frame_limit} frames"
            })
            time.sleep(delay)

        # ✅ Save attendance once (and not repeatedly)
        file_path = save_attendance_excel()
        current_process.update({
            "status": "completed",
            "progress": 100,
            "message": "Attendance capture completed",
            "saved_file": file_path
        })

    finally:
        cap.release()
        cv2.destroyAllWindows()
        is_capturing = False
        logger.info("Camera released and attendance process ended.")


# --- FastAPI App --- #

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Loading face encodings...")
    load_encodings()
    yield
    logger.info("Shutting down server...")

app = FastAPI(lifespan=lifespan, title="Face Recognition Attendance API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Endpoints --- #

@app.get("/")
def read_root():
    return {"status": "success", "message": "Face Recognition Attendance System is running"}

@app.get("/start-attendance")
async def start_attendance(background_tasks: BackgroundTasks):
    global is_capturing, attendance
    if is_capturing:
        return {"status": "error", "message": "Attendance capture already running"}
    attendance = {}
    is_capturing = True
    background_tasks.add_task(capture_attendance_frames)
    return {"status": "success", "message": "Attendance capture started in background"}

@app.get("/stop-attendance")
def stop_attendance():
    global is_capturing
    if is_capturing:
        is_capturing = False
        return {"status": "success", "message": "Attendance stopping..."}
    return {"status": "error", "message": "No active attendance capture to stop"}

@app.get("/attendance")
def get_attendance():
    global attendance
    return {"status": "success", "attendance": attendance or {}}

@app.get("/reset-attendance")
def reset_attendance():
    global attendance
    attendance = {}
    return {"status": "success", "message": "Attendance reset", "attendance": attendance}

@app.post("/add-face/")
async def add_face(name: str, file: UploadFile = File(...)):
    """Add a new predefined face manually"""
    file_path = os.path.join(KNOWN_FACES_DIR, f"{name}.jpg")

    # Save uploaded image
    with open(file_path, "wb") as f:
        f.write(await file.read())

    # Encode and save
    image = face_recognition.load_image_file(file_path)
    encodings = face_recognition.face_encodings(image)
    if not encodings:
        os.remove(file_path)
        raise HTTPException(status_code=400, detail="No face detected in image")

    # Update existing encodings.pkl
    with open(ENCODINGS_FILE, "rb") as f:
        data = pickle.load(f)
    data["encodings"].append(encodings[0])
    data["names"].append(name)

    with open(ENCODINGS_FILE, "wb") as f:
        pickle.dump(data, f)

    logger.info(f"Added predefined face: {name}")
    return {"status": "success", "message": f"Face for '{name}' added successfully"}


@app.post("/manual-mark")
def manual_mark(request: dict):
    global attendance
    name = request.get("name")
    status = request.get("status", "A").upper()
    if not name:
        return {"status": "error", "message": "Name is required", "attendance": attendance or {}}
    if status not in ["P", "A"]:
        status = "A"
    attendance[name] = status
    return {"status": "success", "message": f"{name} marked {status}", "attendance": attendance or {}}

# --- WebSocket for real-time progress --- #

@app.websocket("/ws/attendance")
async def websocket_attendance(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            await asyncio.sleep(0.5)  # update twice per second
            await websocket.send_json(current_process)
    except WebSocketDisconnect:
        logger.info("Client disconnected from WebSocket")

# --- Main --- #

if __name__ == "__main__":
    logger.info("Starting Face Recognition Attendance Server")
    logger.info(f"Known faces directory: {KNOWN_FACES_DIR}")
    logger.info(f"Encodings file: {ENCODINGS_FILE}")
    logger.info(f"Attendance records: {ATTENDANCE_DIR}")
    uvicorn.run(app, host="172.26.16.1", port=9000)
