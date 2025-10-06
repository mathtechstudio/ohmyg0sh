# Dockerfile for ohmyg0sh CLI
FROM dart:stable AS build

# Install Java 17 and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
    curl \
    unzip \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install jadx
ENV JADX_VERSION=1.5.3
RUN curl -L "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" -o /tmp/jadx.zip \
  && unzip /tmp/jadx.zip -d /opt/jadx \
  && rm /tmp/jadx.zip \
  && chmod +x /opt/jadx/bin/jadx

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${PATH}:/opt/jadx/bin"

# App workspace
WORKDIR /app

# Copy dependency files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Resolve Dart dependencies
RUN dart pub get

# Copy config files (must be present for runtime)
COPY config/ ./config/

# Copy source code
COPY bin/ ./bin/
COPY lib/ ./lib/

# Compile to native executable for better performance
RUN dart compile exe bin/ohmyg0sh.dart -o ohmyg0sh

# Minimal runtime image
FROM debian:bookworm-slim

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
  && rm -rf /var/lib/apt/lists/*

# Copy jadx from build stage
COPY --from=build /opt/jadx /opt/jadx
ENV PATH="/opt/jadx/bin:${PATH}"

# Copy compiled binary and config
COPY --from=build /app/ohmyg0sh /usr/local/bin/ohmyg0sh
COPY --from=build /app/config /app/config

# Set working directory
WORKDIR /work

# Entrypoint
ENTRYPOINT ["ohmyg0sh"]
CMD ["--help"]
