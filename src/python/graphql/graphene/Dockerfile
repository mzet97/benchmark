FROM python:3.12-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY *.py .
ENV PORT=8080
EXPOSE 8080
CMD ["gunicorn", "server:app", "--bind", "0.0.0.0:8080", "--workers", "4", "--timeout", "120"]
