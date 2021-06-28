#!/bin/bash -e

if ! grep -q '^net.ipv4.ip_forward' /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  sysctl -w net.ipv4.ip_forward=1
fi

apt-get update
apt-get install -y bird

cat >/etc/bird/bird.conf <<EOF
filter sacredemo {
  # the example IPv4 VIP announced by Cilium
  if net = 10.10.10.0/24 then accept;
}

router id 172.22.102.3;

protocol direct {
  interface "lo"; # Restrict network interfaces BIRD works with
}

protocol kernel {
  persist; # Don't remove routes on bird shutdown
  scan time 20; # Scan kernel routing table every 20 seconds
  import all; # Default is import all
  export all; # Default is export none
  merge paths on;
}

# This pseudo-protocol watches all interface up/down events.
protocol device {
  scan time 10; # Scan interfaces every 10 seconds
}

protocol bgp users {
  local as 64003;

  import none;
  export filter sacredemo;

  neighbor 172.22.100.3 as 64002;
}

protocol bgp cilium {
  local as 65002;

  import filter sacredemo;
  export none;

  neighbor 172.22.102.101 as 65006;
}

EOF

systemctl restart bird

