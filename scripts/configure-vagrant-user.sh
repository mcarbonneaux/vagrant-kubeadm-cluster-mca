#!/bin/bash -e

. /vagrant/scripts/configure_function.sh

disable_ipv6

configure_update
apt-get install -y bird2 traceroute

cat >/etc/bird/bird.conf <<EOF
log stderr all;
debug protocols all;

filter sacredemo {
  # the example IPv4 VIP announced by Cilium
  if (net ~ 10.10.10.0/24) then 
  {
    accept;
  }
}

router id 172.22.100.3;

protocol direct {
  interface "lo"; # Restrict network interfaces BIRD works with
}

protocol kernel {
  persist; # Don't remove routes on bird shutdown
  scan time 20; # Scan kernel routing table every 20 seconds
  merge paths yes limit 10; # ECMP
  ipv4 {
    import all; # Default is import all
    export all; # Default is export none
  };
}

# This pseudo-protocol watches all interface up/down events.
protocol device {
  scan time 10; # Scan interfaces every 10 seconds
}

protocol bgp {
  local 172.22.100.3 as 64002;
  # user side neighbor
  neighbor 172.22.100.2 as 64003;

  ipv4 {
    import all;
    export none;
    next hop self;
  };

}
EOF

systemctl restart bird
