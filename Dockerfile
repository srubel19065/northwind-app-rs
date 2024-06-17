# syntax=docker/dockerfile:1

FROM python:3.8-slim

WORKDIR /app

COPY . /app
RUN pip install --no-cache-dir -r app/requirements.txt

EXPOSE 5000

ENV FLASK_APP=northwind_web.py

CMD ["waitress-serve","--port=5000","northwind_web:app"]
