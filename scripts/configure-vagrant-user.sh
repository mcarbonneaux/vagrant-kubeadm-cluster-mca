#!/bin/bash -e

ip addr add 172.22.100.50/24 dev enp0s8 || true
ip addr add 172.22.100.51/24 dev enp0s8 || true
ip addr add 172.22.100.52/24 dev enp0s8 || true
ip addr add 172.22.100.53/24 dev enp0s8 || true
ip addr add 172.22.100.54/24 dev enp0s8 || true
ip addr add 172.22.100.55/24 dev enp0s8 || true

apt-get update
apt-get install -y bird

cat >/etc/bird/bird.conf <<EOF
filter sacredemo {
  # the example IPv4 VIP announced by Cilium
  if net = 10.10.10.0/24 then accept;
}

router id 172.22.100.3;

protocol direct {
  interface "lo"; # Restrict network interfaces BIRD works with
}

protocol kernel {
  persist; # Don't remove routes on bird shutdown
  scan time 20; # Scan kernel routing table every 20 seconds
  import all; # Default is import all
  export all; # Default is export none
}

# This pseudo-protocol watches all interface up/down events.
protocol device {
  scan time 10; # Scan interfaces every 10 seconds
}

protocol bgp {
  local as 64002;

  import filter sacredemo;
  export none;

  # user side neighbor
  neighbor 172.22.100.2 as 64003;
}
EOF

systemctl restart bird
