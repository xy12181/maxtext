# syntax=docker/dockerfile:experimental
# Use Python 3.10 as the base image
FROM python:3.10-slim-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y curl gnupg

# Add the Google Cloud SDK package repository
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Install the Google Cloud SDK
RUN apt-get update && apt-get install -y google-cloud-sdk

# Set the default Python version to 3.10
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 1

# Set environment variables for Google Cloud SDK and Python 3.10
ENV PATH="/usr/local/google-cloud-sdk/bin:/usr/local/bin/python3.10:${PATH}"

# Set environment variables via build arguments
ARG MODE
ENV ENV_MODE=$MODE

ARG JAX_VERSION
ENV ENV_JAX_VERSION=$JAX_VERSION

ARG LIBTPU_GCS_PATH
ENV ENV_LIBTPU_GCS_PATH=$LIBTPU_GCS_PATH

ARG DEVICE
ENV ENV_DEVICE=$DEVICE

RUN mkdir -p /deps

# Set the working directory in the container
WORKDIR /deps

# Copy setup files and dependency files separately for better caching
COPY setup.sh ./
COPY constraints_gpu.txt requirements.txt requirements_with_jax_ai_image.txt ./

# Install dependencies - these steps are cached unless the copied files change
RUN echo "Running command: bash setup.sh MODE=$ENV_MODE JAX_VERSION=$ENV_JAX_VERSION LIBTPU_GCS_PATH=${ENV_LIBTPU_GCS_PATH} DEVICE=${ENV_DEVICE}"
RUN --mount=type=cache,target=/root/.cache/pip bash setup.sh MODE=${ENV_MODE} JAX_VERSION=${ENV_JAX_VERSION} LIBTPU_GCS_PATH=${ENV_LIBTPU_GCS_PATH} DEVICE=${ENV_DEVICE}

# Now copy the remaining code (source files that may change frequently)
COPY . .
