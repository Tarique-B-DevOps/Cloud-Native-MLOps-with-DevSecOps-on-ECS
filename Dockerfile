FROM python:3.13-slim-bookworm

ARG MODEL_VERSION=""

WORKDIR /model

# Install Utils
RUN apt-get update && \
    apt-get install curl -y

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY *.py ./ 
COPY models ./models

EXPOSE 8888

ENV MODEL_VERSION=${MODEL_VERSION}

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8888"]
