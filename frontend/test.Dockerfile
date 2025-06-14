# Use a pre-built Flutter image from GitHub Container Registry
FROM ghcr.io/cirruslabs/flutter:3.32.4

# Set working directory
WORKDIR /app

# Copy the entire frontend project
# A .dockerignore file is used to exclude unnecessary files
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# The command to run the tests is specified in the docker-compose.yml,
# so no CMD or ENTRYPOINT is needed here.
