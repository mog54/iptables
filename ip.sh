#!/bin/bash

DYNHOST=$1
DYNIP=$(host $DYNHOST | grep -iE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" |cut -f4 -d' '|head -n 1)

# Try to get our IP from the system and fallback to the Internet.
# CHECK NAT
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
if [[ "$IP" = "" ]]; then
                echo '1'
                IP=$(wget -qO- api.ipify.org)
fi

# Exit if invalid IP address is returned
case $DYNIP in
0.0.0.0 )
exit 1 ;;
255.255.255.255 )
exit 1 ;;
esac

# Exit if IP address not in proper format
if ! [[ $DYNIP =~ (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25    [0-5]                                                 ) ]]; then
exit 1
fi

# Check incomming 9090/tcp from evrywhere
echo "Check if incomming 9090/tcp from evrywhere exist..."
if ! /sbin/iptables -n -L | grep -iE "9090" >/dev/null 2>&1 ; then
echo "it did NOT exist, creating rule..."
# creating rule
#/sbin/iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
/sbin/iptables -A INPUT -p tcp --dport 45000 -j LOG --log-level debug --log-prefix "45000/TCP "
/sbin/iptables -A INPUT -p tcp --dport 45000 -j ACCEPT
/sbin/iptables -A INPUT -p udp --dport 45000 -j LOG --log-level debug --log-prefix "45000/UDP "
/sbin/iptables -A INPUT -p udp --dport 45000 -j ACCEPT
#/sbin/iptables -A INPUT -p tcp --dport 32400 -j LOG --log-level debug --log-prefix "32400/TCP "
#/sbin/iptables -A INPUT -p tcp --dport 32400 -j ACCEPT
/sbin/iptables -A INPUT -p tcp --dport 32400 -m set --match-set PLEX src -j LOG --log-level debug --log-prefix "PLEX "
/sbin/iptables -A INPUT -p tcp --dport 32400 -m set --match-set PLEX src -j ACCEPT
/sbin/iptables -A INPUT -p tcp --dport 443 -m set --match-set CLOUDFLARE src -j LOG --log-level debug --log-prefix "HTTPS "
/sbin/iptables -A INPUT -p tcp --dport 443 -m set --match-set CLOUDFLARE src -j ACCEPT
/sbin/iptables -A INPUT -s 0.0.0.0/32 -j LOG --log-level debug --log-prefix "TSI "
/sbin/iptables -A INPUT -s 0.0.0.0/32 -j ACCEPT
#/sbin/iptables -A INPUT -s 195.137.186.65/32 -p icmp -j LOG --log-level debug --log-prefix "PING-TSI "
#/sbin/iptables -A INPUT -s 195.137.186.65/32 -p icmp -j ACCEPT
#/sbin/iptables -A INPUT -s 95.211.81.67/32 -j LOG --log-level debug --log-prefix "SEEDHOST "
#/sbin/iptables -A INPUT -s 95.211.81.67/32 -j ACCEPT
/sbin/iptables -A INPUT -s 82.66.125.140/32 -p tcp --dport 32400 -j LOG --log-level debug --log-prefix "PARENT "
/sbin/iptables -A INPUT -s 82.66.125.140/32 -p tcp --dport 32400 -j ACCEPT
#/sbin/iptables -A INPUT -s 37.48.65.162/32 -p icmp -j LOG --log-level debug --log-prefix "PING SEEDHOST "
#/sbin/iptables -A INPUT -s 37.48.65.162/32 -p icmp -j ACCEPT
fi


# Check Allow All outgoing
echo "Check if Allow All outgoing exist..."
if ! /sbin/iptables -n -L | grep -iE "ACCEPT" | grep -iE "0.0.0.0/0" | grep -iE "state RELATED,ESTABLISHED" | grep -iE "all" >/dev/null 2>&1 ; then
echo "it did NOT exist, creating rule..."
# creating rule
/sbin/iptables -I OUTPUT -o enp3s0 -d 0.0.0.0/0 -j ACCEPT
/sbin/iptables -I INPUT -i enp3s0 -m state --state ESTABLISHED,RELATED -j ACCEPT
fi

# Check Block All incoming
echo "Check if Block All incoming rules exist..."
if ! /sbin/iptables -n -L | grep -iE " $IP " >/dev/null 2>&1 ; then
echo "it did NOT exist, creating rule..."
# creating rule
/sbin/iptables -A INPUT -d $IP -j LOG --log-level debug --log-prefix "DENY "
/sbin/iptables -A INPUT -d $IP -j DROP
fi

# If chain for remote doesn't exist, create it
echo "Checkng to see if the chain $DYNHOST exists..."
if ! /sbin/iptables -L $DYNHOST -n >/dev/null 2>&1 ; then
echo "Chain does not exist, creating chain $DYNHOST..."
/sbin/iptables -N $DYNHOST >/dev/null 2>&1
fi

# Check IP address to see if the chain matches first; skip rest of script if update is not needed
echo "Check IP address to see if the chain matches..."
if ! /sbin/iptables -n -L $DYNHOST | grep -iE " $DYNIP " >/dev/null 2>&1 ; then
echo "it did NOT match, creating chain and rules..."
# Flush old rules, and add new
/sbin/iptables -F $DYNHOST >/dev/null 2>&1
/sbin/iptables -I $DYNHOST -s $DYNIP -p tcp --dport 22 -j ACCEPT
/sbin/iptables -I $DYNHOST -s $DYNIP -p icmp -j ACCEPT
/sbin/iptables -I $DYNHOST -s $DYNIP -p tcp --dport 9090 -j ACCEPT
/sbin/iptables -I $DYNHOST -s $DYNIP -p tcp --dport 443 -j ACCEPT
/sbin/iptables -I $DYNHOST -s $DYNIP -p tcp --dport 8384 -j ACCEPT
/sbin/iptables -I $DYNHOST -s $DYNIP -p udp --dport 22000 -j ACCEPT
/sbin/iptables -I $DYNHOST -s $DYNIP -p tcp --dport 32400 -j ACCEPT
/sbin/iptables -I $DYNHOST -s $DYNIP -p tcp --dport 80 -j ACCEPT

# Add chain to INPUT filter if it doesn't exist
if ! /sbin/iptables -C INPUT -t filter -j $DYNHOST >/dev/null 2>&1 ; then
/sbin/iptables -t filter -I INPUT -j $DYNHOST
echo "Adding chain to INPUT filter because it doesn't exist..."
fi

if ! /sbin/iptables -L INPUT | grep  -iE "^DROP[[:space:]]+|dpt:ssh"  >/dev/null 2>&1 ; then
/sbin/iptables -A INPUT -p tcp --dport 22 -j DROP
echo "Adding DROP anywhere ssh to INPUT filter because it doesn't exist..."
fi

fi
