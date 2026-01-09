# AltServer Linux - All-in-one Docker Image
# Includes: AltServer, netmuxd, anisette-v3, and all dependencies

FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    checkinstall \
    git \
    autoconf \
    automake \
    libtool-bin \
    libssl-dev \
    libcurl4-openssl-dev \
    libusb-1.0-0-dev \
    libavahi-client-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Build libplist
RUN git clone --depth 1 https://github.com/libimobiledevice/libplist.git && \
    cd libplist && \
    ./autogen.sh && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build libimobiledevice-glue
RUN git clone --depth 1 https://github.com/libimobiledevice/libimobiledevice-glue.git && \
    cd libimobiledevice-glue && \
    ./autogen.sh && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build libtatsu
RUN git clone --depth 1 https://github.com/libimobiledevice/libtatsu.git && \
    cd libtatsu && \
    ./autogen.sh && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build libusbmuxd
RUN git clone --depth 1 https://github.com/libimobiledevice/libusbmuxd.git && \
    cd libusbmuxd && \
    ./autogen.sh && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build libimobiledevice
RUN git clone --depth 1 https://github.com/libimobiledevice/libimobiledevice.git && \
    cd libimobiledevice && \
    ./autogen.sh && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build usbmuxd
RUN git clone --depth 1 https://github.com/libimobiledevice/usbmuxd.git && \
    cd usbmuxd && \
    ./autogen.sh && \
    make -j$(nproc) && \
    make install

# ============================================
# Runtime image
# ============================================
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    supervisor \
    curl \
    wget \
    ca-certificates \
    libssl3 \
    libcurl4 \
    libusb-1.0-0 \
    libavahi-client3 \
    libavahi-compat-libdnssd-dev \
    avahi-daemon \
    avahi-utils \
    dbus \
    udev \
    python3 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/lib/x86_64-linux-gnu/libdns_sd.so.1 /usr/lib/x86_64-linux-gnu/libdns_sd.so

# Copy built libraries from builder
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/sbin /usr/local/sbin
COPY --from=builder /usr/local/include /usr/local/include
RUN ldconfig

# Create directories
RUN mkdir -p /app /app/ipa /app/log /app/data /var/run/dbus /var/run/avahi-daemon

# Detect architecture and download appropriate binaries
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        ALTSERVER_BIN="AltServer-aarch64" && \
        NETMUXD_BIN="aarch64-linux-netmuxd"; \
    else \
        ALTSERVER_BIN="AltServer-x86_64" && \
        NETMUXD_BIN="x86_64-linux-netmuxd"; \
    fi && \
    wget -O /app/AltServer "https://github.com/NyaMisty/AltServer-Linux/releases/download/v0.0.5/${ALTSERVER_BIN}" && \
    wget -O /app/netmuxd "https://github.com/jkcoxson/netmuxd/releases/download/v0.1.4/${NETMUXD_BIN}" && \
    chmod +x /app/AltServer /app/netmuxd

# Copy configuration files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*

# Add scripts to PATH
ENV PATH="/app/scripts:${PATH}"

# Environment variables
ENV ALTSERVER_ANISETTE_SERVER=http://127.0.0.1:6969
ENV RUST_LOG=info

# Volume for IPA files and persistent data
VOLUME ["/app/ipa", "/app/data"]

# Entry point
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["supervisord"]
