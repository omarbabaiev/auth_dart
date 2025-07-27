# Use latest stable channel SDK.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and AOT compile app.
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server`
FROM debian:bookworm-slim

# Install SQLite and development libraries
RUN apt-get update && apt-get install -y \
    sqlite3 \
    libsqlite3-0 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy runtime and compiled app
COPY --from=build /app/bin/server /app/bin/

# Create app directory and database directory
WORKDIR /app
RUN mkdir -p /app/database

# Expose port
EXPOSE 8080

# Start server
CMD ["/app/bin/server"]
