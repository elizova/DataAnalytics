FROM python:3.13.7-slim-bookworm

WORKDIR /core

ENV PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    gcc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /core

RUN pip install -r requirements.txt

COPY . /core