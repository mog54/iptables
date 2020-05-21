#!/bin/bash

DYNHOST=$1
DYNIP=$(host $DYNHOST | grep -iE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" |cut -f4 -d' '|head -n 1)

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
# Allow incomming 9090/tcp from evrywhere
echo "Allow incomming 9090/tcp from evrywhere..."
/sbin/iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
# Allow All outgoing
echo "Allow All outgoing..."
/sbin/iptables -I OUTPUT -o enp4s0 -d 0.0.0.0/0 -j ACCEPT
/sbin/iptables -I INPUT -i enp4s0 -m state --state ESTABLISHED,RELATED -j ACCEPT
# Block All incoming
echo "Block All incoming..."
/sbin/iptables -A INPUT -j DROP




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
