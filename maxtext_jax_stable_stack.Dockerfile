ARG JAX_STABLE_STACK_BASEIMAGE

# JAX Stable Stack Base Image
FROM $JAX_STABLE_STACK_BASEIMAGE

ARG COMMIT_HASH

ENV COMMIT_HASH=$COMMIT_HASH

RUN mkdir -p /deps

# Set the working directory in the container
WORKDIR /deps

# Copy all files from local workspace into docker container
COPY . .
RUN ls .

# b/399968784 - Temporary fix till we install JStS[tpu]>=0.5.1
# Orbax checkpoint installs the latest version of JAX,
# but the libtpu version in this base image is older.
# This version mismatch can cause compatibility issues
# and break MaxText.

ARG DEVICE
ENV DEVICE=$DEVICE

RUN if [ $DEVICE = "tpu" ]; then \
        pip install --no-cache-dir jax[tpu]==0.5.1; \
    fi

# Install Maxtext requirements with Jax Stable Stack
RUN pip install -r /deps/requirements_with_jax_stable_stack.txt

# Run the script available in JAX Stable Stack base image to generate the manifest file
RUN bash /jax-stable-stack/generate_manifest.sh PREFIX=maxtext COMMIT_HASH=$COMMIT_HASH