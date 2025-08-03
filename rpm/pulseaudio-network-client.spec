Name:           pulseaudio-network-client
Version:        1.0.0
Release:        1%{?dist}
Summary:        PulseAudio network audio client

License:        MIT
URL:            https://github.com/ferdiu/pulseaudio-network
Source0:        pulseaudio-network-client-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  systemd-rpm-macros

Requires:       python3
Requires:       pulseaudio
Requires:       systemd

%description
PulseAudio Network Client provides a reliable way to connect to remote
PulseAudio servers and create tunnel sinks for network audio streaming.
It includes automatic reconnection, configuration management, and health monitoring.

%prep
%setup -q

%build
# Nothing to build for Python scripts

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_userunitdir}
mkdir -p %{buildroot}%{_sysconfdir}/pulseaudio-network
mkdir -p %{buildroot}%{_docdir}/%{name}

# Install the Python script
install -m 755 src/pulseaudio-network-client %{buildroot}%{_bindir}/pulseaudio-network-client

# Install systemd user service
install -m 644 systemd/pulseaudio-network-client.service %{buildroot}%{_userunitdir}/pulseaudio-network-client.service

# Install default configuration
install -m 644 config/client.json %{buildroot}%{_sysconfdir}/pulseaudio-network/client.json

# Install documentation
install -m 644 README.md %{buildroot}%{_docdir}/%{name}/README.md
install -m 644 LICENSE %{buildroot}%{_docdir}/%{name}/LICENSE

%files
%{_bindir}/pulseaudio-network-client
%{_userunitdir}/pulseaudio-network-client.service
%config(noreplace) %{_sysconfdir}/pulseaudio-network/client.json
%doc %{_docdir}/%{name}/README.md
%license %{_docdir}/%{name}/LICENSE

%post
# Inform user about manual steps
cat << EOF

PulseAudio Network Client installed successfully!

To use this service:

1. Configure your server settings:
   ~/.config/pulseaudio-network/client.json

2. Enable and start the user service:
   systemctl --user enable pulseaudio-network-client.service
   systemctl --user start pulseaudio-network-client.service

3. Check service status:
   systemctl --user status pulseaudio-network-client.service

EOF

%preun
if [ $1 -eq 0 ]; then
    # Stop and disable the service on package removal
    systemctl --user stop pulseaudio-network-client.service >/dev/null 2>&1 || :
    systemctl --user disable pulseaudio-network-client.service >/dev/null 2>&1 || :
fi

%changelog
* %(date "+%a %b %d %Y") Federico Manzella <ferdiu.manzella@gmail.com> - 1.0.0-1
- Initial package release
- PulseAudio network client with configuration management
- Systemd user service integration
- Automatic reconnection and health monitoring