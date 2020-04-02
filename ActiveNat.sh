#! /bin/sh
clear
echo ""
echo "liste des interfaces réseaux disponibles:"
echo ""
echo "#########################################"
echo "`ip link`"
echo ""
echo "#########################################"
echo ""
echo -n "Mettre le nom de l'interface réseaux public: "
read eth0 && \
echo -n "Mettre le nom de l'interface réseaux du LAN: "
read eth1

iptables -A FORWARD -i ${eth1} -j ACCEPT
iptables -A FORWARD -o ${eth1} -j ACCEPT
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o ${eth0} -j MASQUERADE
