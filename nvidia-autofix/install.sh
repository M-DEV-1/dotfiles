#!/bin/bash
# Installs nvidia-autofix: the script in /usr/local/sbin, a boot-time systemd service, and an apt hook that runs the service after every apt run.
# Run with sudo. Remove with: sudo bash install.sh --uninstall
set -eu
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
here=$(dirname "$(readlink -f "$0")")

if [ "${1:-}" = "--uninstall" ]; then
  systemctl disable --now nvidia-autofix.service 2>/dev/null || true
  rm -f /usr/local/sbin/nvidia-autofix /etc/systemd/system/nvidia-autofix.service /etc/apt/apt.conf.d/99nvidia-autofix
  systemctl daemon-reload
  echo "removed"; exit 0
fi

install -m 0755 "$here/nvidia-autofix" /usr/local/sbin/nvidia-autofix

cat > /etc/systemd/system/nvidia-autofix.service <<'EOF'
[Unit]
Description=Install missing kernel headers so the NVIDIA module builds, then load it
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/nvidia-autofix
TimeoutStartSec=30min

[Install]
WantedBy=multi-user.target
EOF

# apt holds its lock while the hook runs, so the hook only queues the service; the service's apt-get waits for the lock.
cat > /etc/apt/apt.conf.d/99nvidia-autofix <<'EOF'
DPkg::Post-Invoke { "systemctl start --no-block nvidia-autofix.service || true"; };
EOF

systemctl daemon-reload
systemctl enable nvidia-autofix.service
systemctl start nvidia-autofix.service || true
journalctl -u nvidia-autofix.service -b --no-pager | tail -20
