# Build ohmyg0sh binary
FROM dart:stable AS build

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    curl \
    unzip \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install JADX (official method)
ENV JADX_VERSION=1.5.3
RUN curl -L "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" -o /tmp/jadx.zip \
  && unzip /tmp/jadx.zip -d /opt/ \
  && rm /tmp/jadx.zip \
  && chmod +x /opt/jadx-${JADX_VERSION}/bin/jadx /opt/jadx-${JADX_VERSION}/bin/jadx-gui

# Add JADX to PATH
ENV PATH="${PATH}:/opt/jadx-${JADX_VERSION}/bin"
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Create app directory
WORKDIR /app

# Copy pubspec first for caching
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --offline || dart pub get

# Copy config & sources
COPY config/ ./config/
COPY bin/ ./bin/
COPY lib/ ./lib/

# Compile Dart executable
RUN dart compile exe bin/ohmyg0sh.dart -o ohmyg0sh && strip ohmyg0sh || true


# Runtime image
FROM debian:bookworm-slim

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    libxext6 libxrender1 libxtst6 libxi6 \
  && rm -rf /var/lib/apt/lists/*

# Copy JADX from build stage
ENV JADX_VERSION=1.5.3
COPY --from=build /opt/jadx-${JADX_VERSION} /opt/jadx-${JADX_VERSION}
ENV PATH="${PATH}:/opt/jadx-${JADX_VERSION}/bin"

# Copy compiled app
COPY --from=build /app/ohmyg0sh /usr/local/bin/ohmyg0sh
COPY --from=build /app/config /app/config

# Setup environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV OHMYG0SH_CONFIG_PATH=/app/config

WORKDIR /work

# Default command
ENTRYPOINT ["ohmyg0sh"]
CMD ["--help"]
