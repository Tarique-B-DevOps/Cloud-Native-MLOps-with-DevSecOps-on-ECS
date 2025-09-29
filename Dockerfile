# Base image
FROM python:3.13-slim-bookworm

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code and models directory
COPY . .

# Expose API port
EXPOSE 8888

# Run FastAPI
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8888"]
