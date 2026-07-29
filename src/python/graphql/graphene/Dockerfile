FROM python:3.12-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY *.py .
ENV PORT=8080
RUN groupadd --gid 1001 app && useradd --uid 1001 --gid 1001 --shell /bin/false --create-home app

EXPOSE 8080

USER app

CMD ["gunicorn", "server:app", "--bind", "0.0.0.0:8080", "--workers", "4", "--timeout", "120"]
