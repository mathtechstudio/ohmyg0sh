# Build ohmyg0sh CLI (compile Dart + install Jadx)
FROM dart:stable AS build

# Install Java and required tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jre \
    curl \
    unzip \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install JADX (for decompiling Android APKs)
ENV JADX_VERSION=1.5.3
RUN curl -L "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" -o /tmp/jadx.zip \
  && unzip /tmp/jadx.zip -d /opt/jadx \
  && rm /tmp/jadx.zip \
  && chmod +x /opt/jadx/bin/jadx /opt/jadx/bin/jadx-gui

# Set Java environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH="${PATH}:/opt/jadx/bin"

# Setup project workspace
WORKDIR /app

# Copy dependency files first (improves caching)
COPY pubspec.yaml pubspec.lock ./

# Resolve Dart dependencies
RUN dart pub get --offline || dart pub get

# Copy config files (regexes.json, notkeyhacks.json, etc.)
COPY config/ ./config/

# Copy source code
COPY bin/ ./bin/
COPY lib/ ./lib/

# Compile Dart executable
RUN dart compile exe bin/ohmyg0sh.dart -o ohmyg0sh

# Optimize binary size (optional but recommended)
RUN strip ohmyg0sh || true

# Minimal runtime image
FROM debian:bookworm-slim

# Install Java runtime only (for JADX)
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jre \
  && rm -rf /var/lib/apt/lists/*

# Copy JADX from build stage
COPY --from=build /opt/jadx /opt/jadx
ENV PATH="/opt/jadx/bin:${PATH}"

# Copy compiled binary and config
COPY --from=build /app/ohmyg0sh /usr/local/bin/ohmyg0sh
COPY --from=build /app/config /app/config

# Add environment variable for config path (for flexibility)
ENV OHMYG0SH_CONFIG_PATH=/app/config
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# Default working directory
WORKDIR /work

# Default entrypoint (CLI)
ENTRYPOINT ["ohmyg0sh"]
CMD ["--help"]
