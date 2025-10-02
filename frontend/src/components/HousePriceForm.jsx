import { useState, useEffect } from "react";
import "../styles/style.css";

// API URL and App version from environment
const API_URL = import.meta.env.VITE_API_URL;
const APP_VERSION = import.meta.env.VITE_APP_VERSION;

export default function HousePriceForm() {
  const [size, setSize] = useState("");
  const [bedrooms, setBedrooms] = useState("");
  const [age, setAge] = useState("");
  const [prediction, setPrediction] = useState(null);
  const [loading, setLoading] = useState(false);
  const [modelVersion, setModelVersion] = useState("");

  // Fetch model version on mount
  useEffect(() => {
    fetch(`${API_URL}/version`)
      .then((res) => res.json())
      .then((data) => setModelVersion(data.model_version))
      .catch((err) => console.error("Error fetching model version:", err));
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setPrediction(null);

    try {
      const res = await fetch(`${API_URL}/predict`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          Size: parseFloat(size),
          Bedrooms: parseInt(bedrooms),
          Age: parseInt(age),
        }),
      });

      if (!res.ok) throw new Error(`API error: ${res.status}`);

      const data = await res.json();
      setPrediction(data.predicted_price);
    } catch (err) {
      console.error(err);
      alert("Error predicting price. Make sure API is running.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      <div className="card">
        <h1>House Price Predictor</h1>

        {modelVersion && (
          <small className="version">Model Version: {modelVersion}</small>
        )}
        {APP_VERSION && (
          <small className="version">Frontend Version: {APP_VERSION}</small>
        )}

        <form onSubmit={handleSubmit}>
          <label>Size (sq ft)</label>
          <input
            type="number"
            value={size}
            onChange={(e) => setSize(e.target.value)}
            required
          />

          <label>Bedrooms</label>
          <input
            type="number"
            value={bedrooms}
            onChange={(e) => setBedrooms(e.target.value)}
            required
          />

          <label>Age (years)</label>
          <input
            type="number"
            value={age}
            onChange={(e) => setAge(e.target.value)}
            required
          />

          <button type="submit" disabled={loading}>
            {loading ? "Predicting..." : "Predict Price"}
          </button>
        </form>

        {prediction !== null && (
          <div className="result">Predicted Price: ${prediction}</div>
        )}
      </div>
    </div>
  );
}
