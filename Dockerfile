FROM python:3.12-slim

WORKDIR /opt/dagster/app

COPY . /opt/dagster/app

RUN pip install -r requirements.txt