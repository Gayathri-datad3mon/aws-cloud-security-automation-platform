FROM python:3.12-slim

WORKDIR /app

COPY lambda/security_alert.py .

CMD ["python", "security_alert.py"]
