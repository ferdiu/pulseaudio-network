# PulseAudio Network Audio Streaming

A reliable solution for streaming audio over the network using PulseAudio's native protocol. This project provides both server and client components with proper configuration management, health monitoring, and packaging for Fedora (RPM) and Debian/Ubuntu (DEB).

## Features

### Server Features
- **TCP Server**: Hosts PulseAudio native protocol over TCP
- **Configuration Management**: JSON-based configuration with automatic defaults
- **Security**: IP ACL support and authentication options
- **Health Monitoring**: Automatic PulseAudio connection monitoring
- **Firewall Integration**: Includes firewalld service definition
- **Graceful Shutdown**: Proper module cleanup on service stop

### Client Features
- **Multi-Server Support**: Connect to multiple servers simultaneously
- **Auto-Reconnection**: Automatic reconnection with configurable retry logic
- **Health Monitoring**: Connection and PulseAudio health checks
- **Custom Sink Names**: Configurable sink names and descriptions
- **Graceful Degradation**: Continues operating even if some servers are unavailable

## Project Structure

```
pulseaudio-network/
├── src/
│   ├── pulseaudio-network-server          # Python server script
│   └── pulseaudio-network-client          # Python client script
├── systemd/
│   ├── pulseaudio-network-server.service  # Systemd user service for server
│   └── pulseaudio-network-client.service  # Systemd user service for client
├── config/
│   ├── server.json                        # Default server configuration
│   └── client.json                        # Default client configuration
├── firewalld/
│   └── pulseaudio-network.xml             # Firewalld service definition
├── rpm/
│   ├── pulseaudio-network-server.spec     # RPM spec file for server
│   └── pulseaudio-network-client.spec     # RPM spec file for client
├── debian/
│   ├── server/                            # Debian packaging files for server
│   │   ├── control
│   │   ├── rules
│   │   ├── postinst
│   │   ├── prerm
│   │   ├── postrm
│   │   ├── changelog
│   │   ├── compat
│   │   └── copyright
│   └── client/                            # Debian packaging files for client
│       ├── control
│       ├── rules
│       ├── postinst
│       ├── prerm
│       ├── changelog
│       ├── compat
│       └── copyright
├── scripts/
│   ├── build-rpm.sh                       # Build RPM packages
│   ├── build-deb.sh                       # Build DEB packages
│   └── install.sh                         # Install from source
├── README.md
└── LICENSE
```

## Installation

### From Packages

#### Fedora/RHEL/CentOS (RPM)
```bash
# Build packages
./scripts/build-rpm.sh

# Install server
sudo dnf install build/server/rpmbuild/RPMS/noarch/pulseaudio-network-server-*.rpm

# Install client
sudo dnf install build/client/rpmbuild/RPMS/noarch/pulseaudio-network-client-*.rpm
```

#### Debian/Ubuntu (DEB)
```bash
# Build packages
./scripts/build-deb.sh

# Install server
sudo dpkg -i build-deb/server/pulseaudio-network-server_*.deb
sudo apt-get install -f  # Fix dependencies if needed

# Install client
sudo dpkg -i build-deb/client/pulseaudio-network-client_*.deb
sudo apt-get install -f  # Fix dependencies if needed
```

### From Source
```bash
# Install both server and client
./scripts/install.sh

# Install only server
./scripts/install.sh server

# Install only client
./scripts/install.sh client
```

## Configuration

### Server Configuration
Edit `~/.config/pulseaudio-network/server.json`:

```json
{
  "port": 4656,
  "listen_address": "0.0.0.0",
  "auth_anonymous": true,
  "auth_ip_acl": ["192.168.1.0/24"],
  "sample_spec": null,
  "channel_map": null
}
```

**Configuration Options:**
- `port`: TCP port to listen on (default: 4656)
- `listen_address`: Address to bind to (default: "0.0.0.0" for all interfaces)
- `auth_anonymous`: Allow anonymous connections (default: true)
- `auth_ip_acl`: List of allowed IP addresses/subnets (empty = allow all)
- `sample_spec`: Custom sample specification (e.g., "s16le 44100 2")
- `channel_map`: Custom channel map (e.g., "front-left,front-right")

### Client Configuration
Edit `~/.config/pulseaudio-network/client.json`:

```json
{
  "servers": [
    {
      "host": "192.168.1.100",
      "port": 4656,
      "sink_name": "network_sink_main",
      "sink_description": "Main Network Audio Sink"
    },
    {
      "host": "192.168.1.101",
      "port": 4656,
      "sink_name": "network_sink_backup",
      "sink_description": "Backup Network Audio Sink"
    }
  ],
  "auto_connect": true,
  "retry_interval": 10,
  "max_retries": -1
}
```

**Configuration Options:**
- `servers`: Array of server configurations
  - `host`: Server IP address or hostname
  - `port`: Server port
  - `sink_name`: Local sink name (will appear in audio settings)
  - `sink_description`: Human-readable description
- `auto_connect`: Automatically connect to servers on startup
- `retry_interval`: Seconds between connection attempts
- `max_retries`: Maximum retry attempts (-1 = infinite)

## Usage

### Server Setup

1. **Install and configure firewall** (if using firewalld):
   ```bash
   sudo firewall-cmd --permanent --add-service=pulseaudio-network
   sudo firewall-cmd --reload
   ```

2. **Enable and start the service**:
   ```bash
   systemctl --user enable pulseaudio-network-server.service
   systemctl --user start pulseaudio-network-server.service
   ```

3. **Check status**:
   ```bash
   systemctl --user status pulseaudio-network-server.service
   journalctl --user -u pulseaudio-network-server.service
   ```

### Client Setup

1. **Configure server addresses** in `~/.config/pulseaudio-network/client.json`

2. **Enable and start the service**:
   ```bash
   systemctl --user enable pulseaudio-network-client.service
   systemctl --user start pulseaudio-network-client.service
   ```

3. **Check status**:
   ```bash
   systemctl --user status pulseaudio-network-client.service
   journalctl --user -u pulseaudio-network-client.service
   ```

4. **Verify sinks are available**:
   ```bash
   pactl list sinks short
   ```

### Using Network Sinks

Once the client is connected, network sinks will appear in your audio settings:

- **GNOME**: Settings → Sound → Output Device
- **KDE**: System Settings → Audio → Playback Devices
- **Command line**: `pactl set-default-sink network_sink_main`

You can also route specific applications:
```bash
# Route Firefox audio to network sink
pactl move-sink-input $(pactl list sink-inputs short | grep firefox | cut -f1) network_sink_main
```

## Troubleshooting

### Common Issues

#### Server Issues

**Service fails to start:**
```bash
# Check if PulseAudio is running
pactl info

# Check for port conflicts
sudo netstat -tlnp | grep :4656

# View detailed logs
journalctl --user -u pulseaudio-network-server.service -f
```

**Firewall blocking connections:**
```bash
# Check firewall status
sudo firewall-cmd --list-services
sudo firewall-cmd --list-ports

# Temporarily disable firewall for testing
sudo systemctl stop firewalld
```

#### Client Issues

**Cannot connect to server:**
```bash
# Test network connectivity
telnet SERVER_IP 4656

# Check DNS resolution
nslookup SERVER_HOSTNAME

# Test with minimal config
echo '{"servers":[{"host":"SERVER_IP","port":4656}]}' > ~/.config/pulseaudio-network/client.json
```

**Sinks not appearing:**
```bash
# Refresh PulseAudio
pulseaudio -k
pulseaudio --start

# Check module status
pactl list modules short | grep tunnel
```

### Log Locations

- **Systemd logs**: `journalctl --user -u pulseaudio-network-{server,client}.service`
- **Application logs**:
  - Server: `/var/log/pulseaudio-server.log` or `~/.local/share/pulseaudio-network/server.log`
  - Client: `/var/log/pulseaudio-client.log` or `~/.local/share/pulseaudio-network/client.log`

### Performance Tuning

#### Network Optimization
```json
// server.json - for high-quality audio
{
  "sample_spec": "s24le 96000 2",
  "channel_map": "front-left,front-right"
}
```

#### Latency Reduction
```json
// client.json - reduce retry interval for faster reconnection
{
  "retry_interval": 5,
  "servers": [...]
}
```

## Security Considerations

### Network Security
- Use IP ACLs to restrict access: `"auth_ip_acl": ["192.168.1.0/24"]`
- Consider VPN for internet connections
- Disable anonymous auth if not needed: `"auth_anonymous": false`

### System Security
- Services run as user (not root)
- Systemd security features enabled (NoNewPrivileges, ProtectSystem, etc.)
- Minimal required permissions

## Development

### Building from Source

#### Prerequisites
```bash
# Fedora/RHEL/CentOS
sudo dnf install python3 python3-devel systemd-rpm-macros rpm-build

# Debian/Ubuntu
sudo apt install python3 python3-dev debhelper dh-python dpkg-dev
```

#### Building Packages
```bash
# Build RPM packages
./scripts/build-rpm.sh

# Build DEB packages
./scripts/build-deb.sh

# Build specific package type
./scripts/build-rpm.sh server    # Only server RPM
./scripts/build-deb.sh client    # Only client DEB
```

### Testing

#### Manual Testing
```bash
# Start server manually
python3 src/pulseaudio-network-server

# Start client manually
python3 src/pulseaudio-network-client

# Test with custom config
CONFIG_DIR=/tmp/test-config python3 src/pulseaudio-network-server
```

#### Integration Testing
```bash
# Test package installation
sudo rpm -i build/server/rpmbuild/RPMS/noarch/pulseaudio-network-server-*.rpm
systemctl --user start pulseaudio-network-server.service

# Test service functionality
pactl list modules short | grep native-protocol-tcp
```

## Advanced Configuration

### Multiple Network Interfaces
```json
// Bind to specific interface
{
  "listen_address": "192.168.1.100",
  "port": 4656
}
```

### Custom Audio Formats
```json
// High-quality audio
{
  "sample_spec": "float32le 192000 8",
  "channel_map": "front-left,front-right,rear-left,rear-right,front-center,lfe,side-left,side-right"
}
```

### Load Balancing Clients
```json
// Connect to multiple servers for redundancy
{
  "servers": [
    {"host": "audio1.local", "port": 4656, "sink_name": "primary"},
    {"host": "audio2.local", "port": 4656, "sink_name": "secondary"}
  ],
  "retry_interval": 5
}
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and test thoroughly
4. Submit a pull request

## Support

- **Issues**: Report bugs and feature requests on GitHub
- **Documentation**: Check the project wiki for detailed guides
- **Community**: Join discussions in the project forums

## Changelog

### Version 1.0.0
- Initial release
- Basic server and client functionality
- RPM and DEB packaging
- Systemd integration
- Configuration file support
- Health monitoring and auto-reconnection