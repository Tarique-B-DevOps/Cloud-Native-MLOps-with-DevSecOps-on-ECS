from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
import joblib
from pathlib import Path
from dataset import generate_data

# Models directory
MODEL_DIR = Path("models")
MODEL_DIR.mkdir(exist_ok=True)
MODEL_PATH = MODEL_DIR / "house_price_model-latest.pkl"

def train_model():
    """Train and save the house price prediction model."""
    data = generate_data()
    X = data[['Size', 'Bedrooms', 'Age']]
    y = data['Price']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    model = LinearRegression()
    model.fit(X_train, y_train)
    
    y_pred = model.predict(X_test)
    mse = mean_squared_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    joblib.dump(model, MODEL_PATH)
    print(f"✅ Model trained and saved at {MODEL_PATH}")
    print(f"📊 MSE: {mse:.2f}, R2: {r2:.2f}")

def load_model():
    """Load trained model from disk."""
    return joblib.load(MODEL_PATH)

if __name__ == "__main__":
    train_model()
