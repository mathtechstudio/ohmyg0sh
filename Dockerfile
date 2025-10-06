# Build
FROM dart:stable AS build

LABEL maintainer="Iqbal Fauzi <iqbalfauzien@gmail.com>" \
  description="APK security scanner that detects hardcoded API keys and credentials before they reach production." \
  repository="https://github.com/mathtechstudio/ohmyg0sh.git"

# Install default JRE (headless for smaller size) and unzip
RUN apt-get update && \
  apt-get install -y default-jre-headless unzip && \
  rm -rf /var/lib/apt/lists/*

# Install jadx 1.5.3
ENV JADX_VERSION=1.5.3
RUN curl -L "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" -o /tmp/jadx.zip \
  && unzip /tmp/jadx.zip -d /opt/jadx \
  && rm /tmp/jadx.zip \
  && chmod +x /opt/jadx/bin/jadx /opt/jadx/bin/jadx-gui

# Set PATH for jadx
ENV PATH="${PATH}:/opt/jadx/bin"

# Working directory
WORKDIR /app

# Copy dependency files first for caching
COPY pubspec.* ./

# Get Dart dependencies
RUN dart pub get

# Copy remaining files
COPY config/ ./config/
COPY bin/ ./bin/
COPY lib/ ./lib/
COPY tool/ ./tool/

# Compile to native executable for better performance
RUN dart run tool/version_gen.dart
RUN dart compile exe bin/ohmyg0sh.dart -o /app/ohmyg0sh


# Runtime
FROM debian:bookworm-slim

# Install minimal runtime (default JRE headless)
RUN apt-get update && apt-get install -y --no-install-recommends \
  default-jre-headless \
  && rm -rf /var/lib/apt/lists/*

# Copy jadx binaries
COPY --from=build /opt/jadx /opt/jadx
ENV PATH="/opt/jadx/bin:${PATH}"

# Copy compiled Dart binary and config files
COPY --from=build /app/ohmyg0sh /usr/local/bin/ohmyg0sh
COPY --from=build /app/config /app/config

# Set default work directory
WORKDIR /work

# Entrypoint for the CLI app
ENTRYPOINT ["ohmyg0sh"]
CMD ["--help"]