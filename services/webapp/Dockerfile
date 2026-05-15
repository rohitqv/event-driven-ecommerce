# syntax=docker/dockerfile:1.7

FROM python:3.11-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app

FROM base AS deps
COPY pyproject.toml ./
# hadolint ignore=DL3013
RUN pip install --upgrade pip && pip install -e .

FROM deps AS runtime
COPY webapp ./webapp
# COPY alembic.ini ./alembic.ini   # uncommented in Task 3 when alembic.ini exists
EXPOSE 8000
CMD ["uvicorn", "webapp.main:app", "--host", "0.0.0.0", "--port", "8000"]
