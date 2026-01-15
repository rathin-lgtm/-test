# =============================================================================
# HV EDP Dagster Dockerfile
# =============================================================================
# Multi-stage build for optimal image size
# =============================================================================

# Stage 1: Build
FROM python:3.12-slim as builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim

# Labels
LABEL maintainer="Data Engineering Team"
LABEL description="HV EDP Dagster Application"

# Create non-root user
RUN useradd --create-home --shell /bin/bash dagster

# Set working directory
WORKDIR /opt/dagster/app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy wheels from builder and install
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels

# Copy application code
COPY --chown=dagster:dagster . .

# Install dbt packages
RUN dbt deps --project-dir hv_edp_dbt

# Switch to non-root user
USER dagster

# Environment variables
ENV DAGSTER_HOME=/opt/dagster/app
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import dagster; print('healthy')" || exit 1

# Default command
CMD ["dagster", "api", "grpc", "-h", "0.0.0.0", "-p", "4000"]
