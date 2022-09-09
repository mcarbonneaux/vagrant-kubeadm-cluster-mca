#!/bin/bash -e

. /vagrant/scripts/configure_function.sh

disable_ipv6

if ! grep -q '^net.ipv4.ip_forward' /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  sysctl -p
fi

configure_update
apt-get install -y bird2

cat >/etc/bird/bird.conf <<EOF
log stderr all;
debug protocols all;

filter sacredemo {
        # the example IPv4 VIP announced by Cilium
	if (net ~ 10.10.10.0/24) then 
        {  
          accept;
        }
};

router id 172.22.102.2;

protocol direct {
  disabled;
}

protocol kernel {
  persist; # Don't remove routes on bird shutdown
  scan time 20; # Scan kernel routing table every 20 seconds
  merge paths yes limit 10; # ECMP
  ipv4 {			# Connect protocol to IPv4 table by channel
    import all; # Default is export none
    export all; # Default is export none
  };
  
}

# This pseudo-protocol watches all interface up/down events.
protocol device {
  scan time 10; # Scan interfaces every 10 seconds
}

protocol bgp users {
  local as 64003;
  neighbor 172.22.100.3 as 64002;
  graceful restart yes;
  hold time 180;

  ipv4 {
    next hop self;
    import none;
    export filter sacredemo;
  };

}


template bgp bgp_cilium {
  local 172.22.101.2 as 65002;
  passive no;
  graceful restart yes;
  hold time 180;

  ipv4 {
          next hop self;
	  import filter sacredemo;
	  export none;
  };
}

protocol bgp cilium1 from bgp_cilium {
  neighbor 172.22.101.101 as 65006;
}

protocol bgp cilium2 from bgp_cilium {
  neighbor 172.22.101.102 as 65006;
}

protocol bgp cilium3 from bgp_cilium {
  neighbor 172.22.101.103 as 65006;
}

EOF

systemctl restart bird

