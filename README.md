# AltServer Linux - Docker

All-in-one Docker image for running AltServer on Linux. Sideload apps and refresh AltStore without macOS or Windows.

## Features

- **AltServer** - Sideloads IPAs and refreshes apps
- **Anisette v3** - Apple authentication server
- **netmuxd** - WiFi device discovery
- **Avahi** - mDNS/Bonjour support for device discovery
- Persistent certificates and pairing data
- Interactive commands for easy management

## Prerequisites

- Docker and Docker Compose
- USB access (for initial pairing)
- `usbmuxd` running on the host system

### Automatic Setup (Recommended)

Run the setup script to automatically install all dependencies:

```bash
./scripts/setup-host
```

This script supports:
- **Debian/Ubuntu** (and derivatives: Linux Mint, Pop!_OS, Elementary, Zorin)
- **Fedora**
- **CentOS/RHEL/Rocky/AlmaLinux**
- **Arch Linux** (and derivatives: Manjaro, EndeavourOS)
- **openSUSE**

### Manual Setup

If you prefer to install manually:

```bash
# Debian/Ubuntu
sudo apt install docker.io docker-compose-v2 usbmuxd libimobiledevice-utils

# Fedora
sudo dnf install docker docker-compose usbmuxd libimobiledevice-utils

# Arch Linux
sudo pacman -S docker docker-compose usbmuxd libimobiledevice

# Start services
sudo systemctl enable --now docker usbmuxd
```

## Quick Start

### 1. Clone and Start

```bash
git clone https://github.com/YOUR_USERNAME/altserver-docker.git
cd altserver-docker
docker compose up -d --build
```

### 2. Pair Your Device (First Time)

Connect your iOS device via USB, then:

```bash
docker exec -it altserver pair
```

Tap **"Trust"** on your device when prompted, then run the command again.

### 3. Install AltStore

Download AltStore IPA and install it:

```bash
# Download AltStore
docker exec -it altserver download-altstore

# Install (replace with your Apple ID and password)
docker exec -it altserver install AltStore.ipa your@email.com your-password
```

> **Note:** If you have 2FA enabled, use an [app-specific password](https://appleid.apple.com) instead.

### 4. Trust Developer Profile

After installation, on your iPhone:
1. Go to **Settings → General → VPN & Device Management**
2. Tap your Apple ID under "Developer App"
3. Tap **Trust** and confirm

### 5. Done!

AltStore is now installed. It will automatically refresh via the running AltServer container.

## Commands

| Command | Description |
|---------|-------------|
| `docker exec -it altserver pair` | Pair a new iOS device |
| `docker exec -it altserver devices` | List connected devices |
| `docker exec -it altserver install <ipa> <apple-id> <password>` | Install an IPA |
| `docker exec -it altserver download-altstore` | Download AltStore IPA |
| `docker exec -it altserver logs [service]` | View logs |
| `docker exec -it altserver bash` | Interactive shell |

### Host Scripts

| Script | Description |
|--------|-------------|
| `./scripts/setup-host` | Install dependencies on host system |
| `./scripts/diagnose` | Check system status and troubleshoot issues |

## Installing Custom IPAs

1. Place your `.ipa` file in the `ipa/` folder
2. Run: `docker exec -it altserver install MyApp.ipa your@email.com your-password`

## Logs

View logs for troubleshooting:

```bash
# AltServer logs
docker exec -it altserver logs altserver

# All logs
docker exec -it altserver logs all

# Or check the log/ folder directly
ls -la log/
```

## WiFi Refresh

For WiFi refresh to work:
1. Your iOS device must have been previously synced with "Show this iPhone when on WiFi" enabled (via Finder/iTunes on Mac/PC)
2. Device must be on the same network as the Docker host
3. Device must be paired with this container

If WiFi refresh is unstable, USB refresh is always reliable.

## Troubleshooting

### Self-Diagnosis

Run the diagnostic script to check your setup:

```bash
./scripts/diagnose
```

This will verify:
- Docker installation and status
- usbmuxd daemon and socket
- USB device detection
- Container status
- Network connectivity

### "No devices found"
- Make sure `usbmuxd` is running on the host: `sudo systemctl start usbmuxd`
- Connect device via USB
- Run `docker exec -it altserver pair`
- Make sure container has USB access (privileged mode)

### usbmuxd socket is a directory
This happens when Docker creates the mount point before usbmuxd starts:

```bash
# Stop containers
docker compose down

# Remove the directory and start usbmuxd
sudo rm -rf /var/run/usbmuxd
sudo usbmuxd

# Verify socket exists
ls -la /var/run/usbmuxd  # Should show 's' (socket), not 'd' (directory)

# Restart containers
docker compose up -d
```

### "Please accept trust dialog"
- Unlock your iOS device
- Tap "Trust" when prompted
- Run the pair command again

### Installation freezes
- Try restarting the container: `docker compose restart`
- Check logs: `docker exec -it altserver logs altserver`

### 2FA / Authentication errors
- Generate an [app-specific password](https://appleid.apple.com)
- Use that instead of your regular password

## Architecture

The container supports both `x86_64` and `arm64` (Raspberry Pi) architectures. The correct binaries are automatically downloaded during build.

## Directory Structure

```
.
├── docker-compose.yml    # Container orchestration
├── Dockerfile            # Build instructions
├── supervisord.conf      # Service management
├── scripts/
│   ├── setup-host        # Host dependency installer
│   ├── diagnose          # System diagnostic tool
│   ├── pair              # Pair iOS device
│   ├── install           # Install IPA files
│   ├── devices           # List connected devices
│   ├── download-altstore # Download AltStore IPA
│   ├── logs              # View service logs
│   └── entrypoint.sh     # Container entrypoint
├── ipa/                  # Place your IPA files here
├── data/                 # Pairing records (auto-generated)
├── log/                  # Service logs (auto-generated)
└── AltServerData/        # Certificates (auto-generated, sensitive)
```

> **Note:** `AltServerData/`, `data/`, `log/`, and IPA files are gitignored as they contain user-specific or sensitive data.

## Stopping

```bash
docker compose down
```

## Updating

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Free Developer Account Limitations

With a free Apple Developer account:
- Maximum **3 sideloaded apps** at a time
- Apps expire after **7 days** (AltStore auto-refreshes them)
- Limited app IDs

## License

MIT

## Credits

- [AltServer-Linux](https://github.com/NyaMisty/AltServer-Linux) by NyaMisty
- [netmuxd](https://github.com/jkcoxson/netmuxd) by jkcoxson
- [anisette-v3-server](https://github.com/Dadoum/anisette-v3-server) by Dadoum
- [libimobiledevice](https://github.com/libimobiledevice) project
