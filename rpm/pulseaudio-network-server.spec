Name:           pulseaudio-network-server
Version:        1.0.0
Release:        1%{?dist}
Summary:        PulseAudio network audio server

License:        MIT
URL:            https://github.com/ferdiu/pulseaudio-network
Source0:        pulseaudio-network-server-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  systemd-rpm-macros

Requires:       python3
Requires:       pulseaudio
Requires:       systemd
Requires:       firewalld

%description
PulseAudio Network Server provides a reliable way to share audio from a
PulseAudio-enabled system over the network. It includes automatic configuration
management, health monitoring, and graceful error handling.

%prep
%setup -q

%build
# Nothing to build for Python scripts

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_userunitdir}
mkdir -p %{buildroot}%{_sysconfdir}/pulseaudio-network
mkdir -p %{buildroot}%{_prefix}/lib/firewalld/services
mkdir -p %{buildroot}%{_docdir}/%{name}

# Install the Python script
install -m 755 src/pulseaudio-network-server %{buildroot}%{_bindir}/pulseaudio-network-server

# Install systemd user service
install -m 644 systemd/pulseaudio-network-server.service %{buildroot}%{_userunitdir}/pulseaudio-network-server.service

# Install firewalld service definition
install -m 644 firewalld/pulseaudio-network.xml %{buildroot}%{_prefix}/lib/firewalld/services/pulseaudio-network.xml

# Install default configuration
install -m 644 config/server.json %{buildroot}%{_sysconfdir}/pulseaudio-network/server.json

# Install documentation
install -m 644 README.md %{buildroot}%{_docdir}/%{name}/README.md
install -m 644 LICENSE %{buildroot}%{_docdir}/%{name}/LICENSE

%files
%{_bindir}/pulseaudio-network-server
%{_userunitdir}/pulseaudio-network-server.service
%{_prefix}/lib/firewalld/services/pulseaudio-network.xml
%config(noreplace) %{_sysconfdir}/pulseaudio-network/server.json
%doc %{_docdir}/%{name}/README.md
%license %{_docdir}/%{name}/LICENSE

%post
# Reload firewalld to pick up new service definition
if systemctl is-active --quiet firewalld; then
    firewall-cmd --reload >/dev/null 2>&1 || :
fi

# Inform user about manual steps
cat << EOF

PulseAudio Network Server installed successfully!

To use this service:

1. Enable and start the user service:
   systemctl --user enable pulseaudio-network-server.service
   systemctl --user start pulseaudio-network-server.service

2. Configure firewall (as root):
   firewall-cmd --permanent --add-service=pulseaudio-network
   firewall-cmd --reload

3. Edit configuration if needed:
   ~/.config/pulseaudio-network/server.json

EOF

%preun
if [ $1 -eq 0 ]; then
    # Stop and disable the service on package removal
    systemctl --user stop pulseaudio-network-server.service >/dev/null 2>&1 || :
    systemctl --user disable pulseaudio-network-server.service >/dev/null 2>&1 || :
fi

%postun
if [ $1 -eq 0 ]; then
    # Reload firewalld on package removal
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --reload >/dev/null 2>&1 || :
    fi
fi

%changelog
* %(date "+%a %b %d %Y") Federico Manzella <ferdiu.manzella@gmail.com> - 1.0.0-1
- Initial package release
- PulseAudio network server with configuration management
- Systemd user service integration
- Firewalld service definition