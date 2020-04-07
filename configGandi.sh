#! /bin/sh


################################################################################
#                                                                              #
#                                                                              #
#                    Pré-configuration VMs Gandi                               #
#                                                                              #
#  1 ) Choix du poste à déployer (master ou worker)                            #
#  2 ) Installation de firewalld                                               #
#  3 ) Configuration du NAT                                                    #
#  4 ) Configuration des interfaces réseaux                                    #
#  5 ) Configuration des interfaces dans les zones appropriés                  #
#  6 ) Configuration du fichier /etc/sysconfig/gandi                           #
#  7 ) Configurer le client dns /etc/resolv.conf t du fichier /etc/hosts       #
#                                                                              #
################################################################################


# Version 1.0

################################################################################
#                                                                              #
#                    Déclaration variables                                     #
#                                                                              #
################################################################################
dns1="172.21.0.100"
dns2="8.8.8.8"
domain="mon.dom"
network="/etc/sysconfig/network"
################################################################################
#                                                                              #
#                    Déclaration fonctions                                     #
#                                                                              #
################################################################################
config_motd() {
cp MilleniumFalcon /etc/motd
}

config_interface() {
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-${eth}${num}
DEVICE=${eth}${num}
ONBOOT=yes
NAME=${eth}${num}
IPADDR=${ip}
NETMASK=${netmask}
GATEWAY=${gateway}
ZONE=${zone}
DNS1=${dns1}
DNS2=${dns2}
DOMAIN=${domain}
IPV6INIT=no
IPV6_AUTOCONF=no
EOF
}

config_nat() {
firewall-cmd  ---zone=trusted --add-masquerade --permanent
firewall-cmd  ---zone=trusted --add-masquerade
}

config_gandi_master() {
sed -i -e "s|CONFIG_HOSTNAME=1|CONFIG_HOSTNAME=0|g" /etc/sysconfig/gandi
sed -i -e "s|CONFIG_NAMESERVER=1|CONFIG_NAMESERVER=0|g" /etc/sysconfig/gandi
sed -i -e "s|CONFIG_NODHCP=""|CONFIG_NODHCP="eth0 eth1 eth2"|g" /etc/sysconfig/gandi
sed -i -e "s|CONFIG_NETWORK=1|CONFIG_NETWORK=0|g" /etc/sysconfig/gandi
sed -i -e "s|CONFIG_MOTD=1|CONFIG_MOTD=0|g" /etc/sysconfig/gandi
}

config_gandi_worker() {
sed -i -e "s|CONFIG_HOSTNAME=1|CONFIG_HOSTNAME=0|g" /etc/sysconfig/gandi
sed -i -e "s|CONFIG_NAMESERVER=1|CONFIG_NAMESERVER=0|g" /etc/sysconfig/gandi
sed -i -e "s|CONFIG_NODHCP=""|CONFIG_NODHCP="eth0 eth1"|g" /etc/sysconfig/gandi
sed -i -e "s|CONFIG_NETWORK=1|CONFIG_NETWORK=0|g" /etc/sysconfig/gandi
sed -i -e "s|CONFIG_MOTD=1|CONFIG_MOTD=0|g" /etc/sysconfig/gandi
}

config_network() {
  if [ -f ${network} ]
  then
    echo "NETWORK=y" > ${network}
    echo "NETWORKING_IPV6=no" >> ${network}
    echo "IPV6_AUTOCONF=no" >> ${network}
  fi
}
config_hosts() {
cat <<EOF > /etc/hosts
127.0.0.1 localhost
172.21.0.100 master.mon.dom
172.21.0.110 worker1.mon.dom
172.21.0.111 worker2.mon.dom
EOF
}
################################################################################
#                                                                              #
#                    Exécution code                                            #
#                                                                              #
################################################################################

#Choix du noeud master ou worker

clear
until [ "${noeud}" = "worker" -o "${noeud}" = "master" ]
do
echo -n 'Indiquez si cette machine doit être "master" ou "worker", mettre en toutes lettres votre réponse: '
read noeud
done


if [ "${noeud}" = "master" ]
then
# CONFIG MASTER install de firewalld et configuration du NAT et du réseau global + MOTD
yum install -y firewalld
systemctl enable --now firewalld
config_nat
config_network
config_motd
  for num in 0 1 2
  do
    clear
    echo "#######################################################"
    echo -n "Mettre l'adresse IP de l'interface ${eth}${num} :  "
    read ip
    echo "#######################################################"
    echo -n "Mettre l'adresse du MSR pour l'adresse ${ip} :  "
    read netmask
    echo "#######################################################"
    echo -n "Mettre l'adresse de passerelle pour ${eth}${num} - ${ip} :  "
    read gateway
    echo "#######################################################"
    echo -n "Mettre la zone de firewall pour l'interface ${eth}${num} - ${ip} :  "
    read zone
    eth="eth"
    config_interface
  done
systemctl enable --now network
systemctl restart network
config_hosts
elif [ "${noeud}" = "worker" ]
then
# CONFIG WORKER install de firewalld et configuration du NAT et du réseau global + MOTD
yum install -y firewalld
systemctl enable --now firewalld
config_network
config_motd
  for num in 0 1
  do
    clear
    echo "#######################################################"
    echo -n "Mettre l'adresse IP de l'interface ${eth}${num} :  "
    read ip
    echo "#######################################################"
    echo -n "Mettre l'adresse du MSR pour l'adresse ${ip} :  "
    read netmask
    echo "#######################################################"
    echo -n "Mettre l'adresse de passerelle pour ${eth}${num} - ${ip} :  "
    read gateway
    echo "#######################################################"
    echo -n "Mettre la zone de firewall pour l'interface ${eth}${num} - ${ip} :  "
    read zone
    eth="eth"
    config_interface
  done
systemctl enable --now network
systemctl restart network
config_hosts
fi
