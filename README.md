# iptables

smal script to create iptable rules to alow:

-ssh from specific IP
-ping from specific IP 
-9090/tcp from evrywhere
-all outgoing traffic

and block all other incoming traffic.
if you have dyn ip you have to make a cron job tu run periodically

## Usage

```
./ip.sh your.dns.com

Checking to see if the chain your.dns.com exists…
Chain does not exist, creating chain your.dns.com…
Check IP address to see if the chain matches…
It did NOT match, creating chain and rules…
Adding chain to INPUT filter because it doesn't exist…
Adding DROP anywhere ssh to INPUT filter because it doesn't exist…

# Iptables -S

-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-N your.dns.com
-A INPUT -j your.dns.com
-A INPUT -p tcp -m tcp --dport 22 -j DROP
-A your.dns.com -s your-ip/32 -p tcp -m tcp --dport 22 -j ACCEPT
-A your.dns.com -s your-ip/32 -p tcp -m icmp -j ACCEPT


#Allow outbound traffic (change interface name if needed)

iptables -I OUTPUT -o enp4s0 -d 0.0.0.0/0 -j ACCEPT
iptables -I INPUT -i enp4s0 -m state --state ESTABLISHED,RELATED -j ACCEPT

```

credit: https://arthur.carterstein.com/dynamically-update-iptables/
