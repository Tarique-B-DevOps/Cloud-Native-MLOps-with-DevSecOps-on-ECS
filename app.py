from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from train import load_model
from inference import House
import os

# Load pre-trained model (assumes train.py was run already)
model = load_model()

app = FastAPI(title="House Price Prediction API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {
        "message": "Welcome to the House Price Prediction API!",
        "model_loaded": True
    }

@app.post("/predict")
def predict_house_price(house: House):
    features = [[house.Size, house.Bedrooms, house.Age]]
    prediction = model.predict(features)[0]
    return {"predicted_price": round(float(prediction), 2)}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/version")
def get_model_version():
    model_version = os.getenv("MODEL_VERSION", "unknown")
    return {"model_version": model_version}
