#!/bin/bash
# Password root diambil dari ROOT_PASSWORD (atau PASSWORD) yang dikirim bot per VPS.
PASS="${ROOT_PASSWORD:-$PASSWORD}"
if [ -z "$PASS" ]; then
  echo "ROOT_PASSWORD belum diset, sshd tidak dijalankan"
  exec sleep infinity
fi
echo "root:${PASS}" | chpasswd
mkdir -p /run/sshd
ssh-keygen -A
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/; s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
(pm2 resurrect >/dev/null 2>&1 || true)
exec /usr/sbin/sshd -D -e -p "${PORT:-22}"
