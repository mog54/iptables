#!/bin/bash

# Check incomming 9090/tcp from evrywhere
echo "Check if incomming 9090/tcp from evrywhere exist..."
if ! /sbin/iptables -n -L | grep -iE "9090" >/dev/null 2>&1 ; then
echo "it did NOT exist, creating rule..."
# creating rule
/sbin/iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
fi
