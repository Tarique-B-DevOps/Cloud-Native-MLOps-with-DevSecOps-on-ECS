import pandas as pd
import numpy as np

def generate_data(n_samples=500):
    """Generate a synthetic house price dataset."""
    np.random.seed(42)
    size = np.random.randint(500, 5000, n_samples)
    bedrooms = np.random.randint(1, 6, n_samples)
    age = np.random.randint(0, 50, n_samples)
    price = (size * 300) + (bedrooms * 10000) - (age * 500) + np.random.normal(0, 50000, n_samples)
    
    data = pd.DataFrame({
        'Size': size,
        'Bedrooms': bedrooms,
        'Age': age,
        'Price': price
    })
    return data
