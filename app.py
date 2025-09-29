from fastapi import FastAPI
from train import load_model
from inference import House

# Load pre-trained model (assumes train.py was run already)
model = load_model()

app = FastAPI(title="House Price Prediction API")

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
