#!/bin/sh
#
#   !!!!!!!!!!!!!   pas fini !!!!!!!!!!!!!!!!!!!!
#   !!!!!!!!!!!!!   corriger les tests de fin de fonctions
#
# Script de déploiment docker swarm
# By christophe@cmconsulting.online
#
# Script destiné à faciliter le déploiement de cluster docker swarm
# Il est à exécuter dans le cadre d'une formation.
# Il ne doit pas être exploité pour un déploiement en production.
#
#
#
#################################################################################
#                                                                               #
#                       LABS  DOCKER Avanced                                    #
#                                                                               #
#                                                                               #
#               Internet                                                        #
#                   |                                                           #
#                  master1 (VM) dhcp bind9 NAT                                  #
#                       |                                                       #
#                      -------------------                                      #
#                      |  switch  interne|--(VM) Client linux                   #
#                      |-----------------|                                      #
#                        |     |                                                #
#                        |     |                                                #
#                 (vm)worker1  |                                                #
#                      (vm)worker2                                              #
#                                                                               #
#                                                                               #
#                                                                               #
#################################################################################
#                                                                               #
#                          Features                                             #
#                                                                               #
#################################################################################
#                                                                               #
# - Le système sur lequel s'exécute ce script doit être un CentOS7              #
# - Le compte root doit etre utilisé pour exécuter ce Script                    #
# - Le script requière que la machine master soit correctement configuré sur IP #
#   master.mon.dom carte interne  -> 172.21.0.100/24                            #
# - Les systèmes sont synchronisés sur le serveur de temps 1.fr.pool.ntp.org    #
# - Les noeuds worker sont automatiquements adressé sur IP par le master        #
# - La résolution de nom est réaliser par un serveur BIND9 sur le master        #
# - le LABS est établie avec un maximum de trois noeuds worker                  #
#                                                                               #
#                                                                               #
#################################################################################
#Fonction de vérification des étapes
#activesshroot() {
#
#}
verif(){
  if [ "${vrai}" -eq "0" ]; then
    echo "Étape - ${node}- ${nom} - OK"
  else
    echo "Erreur étape - ${node}- ${nom}"
    exit 0
  fi
}
# Fonction d'installation de docker EE version 18.9
DOCKER(){
vrai="1"
export DOCKERURL=${docker_ee} && \
echo  "${DOCKERURL}/centos"  >  /etc/yum/vars/dockerurl && \
yum-config-manager  --add-repo  "$DOCKERURL/centos/docker-ee.repo" && \
#sed -i -e "s|enabled=1|enabled=0|g" /etc/yum.repos.d/docker-ee.repo && \
#sed -i -e  "151 s|enabled=0|enabled=1|g" /etc/yum.repos.d/docker-ee.repo && \
yum  install  -y   docker-ee && \
systemctl enable  --now docker.service && \
vrai="0"
nom="Installation de DOCKER-EE"
verif
}
# Fonction de configuration des parametres communs du dhcp
dhcp () {
vrai="1"
cat <<EOF > /etc/dhcp/dhcpd.conf
ddns-updates on;
ddns-update-style interim;
ignore client-updates;
update-static-leases on;
log-facility local7;
include "/etc/named/ddns.key";
zone mon.dom. {
  primary 172.21.0.100;
  key DDNS_UPDATE;
}
zone 0.21.172.in-addr.arpa. {
  primary 172.21.0.100;
  key DDNS_UPDATE;
}
option domain-name "mon.dom";
#option domain-name-servers 172.21.0.100, 172.21.0.101, 172.21.0.102 ;
option domain-name-servers 172.21.0.100;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 172.21.0.0 netmask 255.255.255.0 {
  range 172.21.0.110 172.21.0.150;
  option routers 172.21.0.100;
  option broadcast-address 172.21.0.255;
  ddns-domainname "mon.dom.";
  ddns-rev-domainname "in-addr.arpa";
}
EOF
vrai="0"
nom="dhcp"
}
# Fonction de configuration du serveur Named maitre SOA
namedSOA () {
vrai="1"
cat <<EOF >> /etc/named.conf
include "/etc/named/ddns.key" ;
zone "mon.dom" IN {
        type master;
        file "mon.dom.db";
        allow-update {key DDNS_UPDATE;};
        allow-query { any;};
        notify yes;
};
zone "0.21.172.in-addr.arpa" IN {
        type master;
        file "172.21.0.db";
        allow-update {key DDNS_UPDATE;};
        allow-query { any;};
        notify yes;
};
EOF
vrai="0"
nom="namedSOA"
}
#
#
# Fonction de configuration de la zone direct mon.dom
namedMonDom () {
vrai="1"
cat <<EOF > /var/named/mon.dom.db
\$TTL 300
@       IN SOA  master.mon.dom. root.master.mon.dom. (
              1       ; serial
              600      ; refresh
              900      ; retry
              3600      ; expire
              300 )    ; minimum
@             NS      master.mon.dom.
master   A       172.21.0.100
worker1  A  172.21.0.110
worker2  A  172.21.0.111
EOF
vrai="0"
nom="namedMonDom"
}
#
#
# Fonction de configuration de la zone reverse named
namedRevers () {
vrai="1"
cat <<EOF > /var/named/172.21.0.db
\$TTL 300
@       IN SOA  master.mon.dom. root.master.mon.dom. (
              1       ; serial
              600      ; refresh
              900      ; retry
              3600      ; expire
              300 )    ; minimum
@             NS      master.mon.dom.
100           PTR     master.mon.dom.
110   PTR   worker1.mon.dom.
111   PTR   worker2.mon.dom.
EOF
vrai="0"
nom="namedRevers"
}
#
#
# Fonction de configuration du module bridge
moduleBr () {
vrai="1"
modprobe  br_netfilter && \
cat <<EOF > /etc/rc.modules
modprobe  br_netfilter
EOF
chmod  +x  /etc/rc.modules && \
sysctl   -w net.bridge.bridge-nf-call-iptables=1 && \
sysctl   -w net.bridge.bridge-nf-call-ip6tables=1 && \
cat <<EOF >> /etc/sysctl.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF
vrai="0"
nom="moduleBr"
}
#
#
# Fonction de serveur de temps
temps() {
vrai="1"
ntpdate -u 0.fr.pool.ntp.org && \
sed -i -e  "s|server 0.centos.pool.ntp.org|server 0.fr.pool.ntp.org|g" /etc/ntp.conf && \
systemctl enable --now ntpd.service && \
vrai="0"
nom="temps"
}

###################################################################################################
#                                                                                                 #
#                             Debut de la séquence d'Installation                                 #
#                                                                                                 #
###################################################################################################
#
# Etape 1
# Déclaration des variables
#
#
NBR=0
clear
until [ "${noeud}" = "worker" -o "${noeud}" = "master" ]
do
echo -n 'Indiquez si cette machine doit être "master" ou "worker", mettre en toutes lettres votre réponse: '
read noeud
done
if [ "${noeud}" = "worker" ]
then
vrai="1"
x=0 ; until [ "${x}" -gt "0" -a "${x}" -lt "4" ] ; do echo -n "Mettez un numéro de ${noeud} à installer (1, 2 ou 3, pour ${noeud}1.mon.dom, mettre: 1 ): " ; read x ; done
hostnamectl  set-hostname  ${noeud}${x}.mon.dom && \
vrai="1"
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
read eth1 && \
vrai="0"
nom="selection de la carte réseau public"
verif
export node="worker"
elif [ ${noeud} = "master" ]
then
#vrai="1"
#activesshroot && \
#vrai="0"
#nom="activation du root sur ssh"
#verif
vrai="1"
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
read eth1 && \
vrai="0"
nom="selection de la carte réseau interne"
verif
vrai="1"
hostnamectl  set-hostname  ${noeud}.mon.dom && \
export node="master" && \
vrai="1"
#firewall-cmd --set-default-zone trusted && \
iptables -A FORWARD -i ${eth1} -j ACCEPT
iptables -A FORWARD -o ${eth1} -j ACCEPT
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o ${eth0} -j MASQUERADE
vrai="0"
nom="regles de firewall à trusted"
verif
cat <<EOF > /etc/resolv.conf
domain mon.dom
nameserver 172.21.0.100
nameserver 8.8.8.8
EOF
vrai="0"
nom="Construction du nom d hote et du fichier resolv.conf"
verif
fi
vrai="1"
echo -n "Collez l'URL de télechargement de Docker-EE: "
read docker_ee && \
vrai="0"
nom="recuperation de l url de docker"
verif
#
#
# Etape 3
# Construction du fichier de résolution interne hosts.
# et déclaration du résolveur DNS client
#
#
vrai="1"
cat <<EOF > /etc/hosts
127.0.0.1 localhost
EOF
vrai="0"
nom="contruction du fichier hosts"
verif
############################################################################################
#                                                                                          #
#                       Déploiement du master docker                                       #
#                                                                                          #
############################################################################################
#
# Etape 4 node master
# installation des services annexes.
#
#
if [ "${node}" = "master" ]
then
vrai="1"
eth1="enp0s8"
vrai="0"
nom="parametrage de base du master"
verif
#
# Etape 5 node master
# installation des applications.
#
#
vrai="1"
yum  install -y bind ntp yum-utils dhcp && \
vrai="0"
nom="installation des outils et services sur le master"
verif
#
# Etape 6 node master
# Configuration et démarrage du serveur BIND9
#
#
vrai="1"
dnssec-keygen -a HMAC-MD5 -b 128 -r /dev/urandom -n USER DDNS_UPDATE && \
cat <<EOF > /etc/named/ddns.key
key DDNS_UPDATE {
	algorithm HMAC-MD5.SIG-ALG.REG.INT;
  secret "bad" ;
};
EOF
secret=`grep Key: /root/*.private | cut -f 2 -d " "` && \
sed -i -e "s|bad|$secret|g" /etc/named/ddns.key && \
chown root:named /etc/named/ddns.key && \
chmod 640 /etc/named/ddns.key && \
sed -i -e "s|listen-on port 53 { 127.0.0.1; };|listen-on port 53 { 172.21.0.100; 127.0.0.1; };|g" /etc/named.conf && \
sed -i -e "s|allow-query     { localhost; };|allow-query     { localhost;172.21.0.0/24; };|g" /etc/named.conf && \
echo 'OPTIONS="-4"' >> /etc/sysconfig/named && \
namedSOA && \
namedMonDom && \
chown root:named /var/named/mon.dom.db && \
chmod 660 /var/named/mon.dom.db && \
namedRevers && \
chown root:named /var/named/172.21.0.db && \
chmod 660 /var/named/172.21.0.db && \
systemctl enable --now named.service && \
vrai="0"
nom="configuration et demarrage de bind"
verif
#
# Etape 7 node master
# Configuration et démarrage du serveur de temps ntp.
#
#
vrai="1"
temps && \
vrai="0"
nom="synchronisation du temps"
verif
#
# Etape 8 node master
# installation du modules bridge.
# et activation du routage
#
vrai="1"
moduleBr && \
vrai="0"
nom="installation du module de brige"
verif
#
# Etape 9 node master
# configuration du NAT sur le premier master
#
#vrai="1"
#firewall-cmd --add-masquerade && \
#firewall-cmd --permanent --add-masquerade && \
#vrai="0"
#nom="mise en place du NAT"
#verif
#
# Etape 10 node master
# configuration du dhcp avec inscription dans le DNS
#
#
vrai="1"
dhcp && \
sed -i 's/.pid/& '"${eth1}"'/' /usr/lib/systemd/system/dhcpd.service && \
systemctl enable  --now  dhcpd.service && \
vrai="0"
nom="configuration et start du service dhcp"
verif
#
# Etape 11 node master
# installation de docker
#
#
vrai="1"
DOCKER && \
vrai="0"
nom="configuration et installaiton du service docker-ee"
#
# Etape 12 node master
# deployement de swarm
#
#
vrai="1"
docker swarm init --listen-addr ${eth1} --advertise-addr ${eth1}
vrai="0"
nom="deploiement du cluster"
verif
#
# Etape 13 node master
# Installation de bash-completion pour faciliter les saisies
#
#
vrai="1"
yum install -y bash-completion && \
vrai="0"
nom="installation de bash-completion"
verif
#
# Etape 14 node master
# ajout du compte stagiaire dans le groupe "docker"
#
#
vrai="1"
usermod  -aG docker stagiaire
vrai="0"
nom="Ajout du compte stagiaire dans le groupe docker"
verif
fi

############################################################################################
#                                                                                          #
#                       Déploiement des workers Kubernetes                                 #
#                                                                                          #
############################################################################################
if [ "${node}" = "worker" ]
then
# Libre passage des flux in et out sur les interfaces réseaux
#
#
vrai="1"
#firewall-cmd --set-default-zone trusted && \
iptables -A FORWARD -i ${eth1} -j ACCEPT
iptables -A FORWARD -o ${eth1} -j ACCEPT
#sysctl -w net.ipv4.ip_forward=1
#sysctl -p /etc/sysctl.conf
vrai="0"
nom="regles de firewall à trusted"
verif
vrai="1"
systemctl restart network && \
vrai="0"
nom="restart de la pile réseau du worker"
verif
#
# Etape 4 node worker
# Création des clés pour ssh-copy-id
#
#
vrai="1"
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -P "" && \
ssh-copy-id -i ~/.ssh/id_rsa.pub stagiaire@master.mon.dom && \
vrai="0"
nom="configuration du ssh agent"
verif
#
# Etape 5 node worker
# Création des clés pour ssh-copy-id
#
#
vrai="1"
alias master="ssh stagiaire@master.mon.dom" && \
export token=`master docker swarm join-token -q worker` \
vrai="0"
nom="recuperation des clés sur le master pour l'intégration au cluster"
verif
# Etape 6 node worker
# Installation des outils
#
#
vrai="1"
yum install -y ntp yum-utils && \
vrai="0"
nom="installation de outils sur le worker"
verif
#
# Etape 7 node worker
# synchronisation de temps sur 0.fr.pool.ntp.org
#
#
vrai="1"
temps && \
vrai="0"
nom="configuration du serveur de temps sur le worker"
verif
#
# Etape 8 node worker
# Chargement du module noyau de bridge
#
#
vrai="1"
moduleBr && \
vrai="0"
nom="installation du module bridge sur le worker"
verif
#
# Etape 9
# Installation du moteur de conteneurisation docker
#
#
vrai="1"
DOCKER && \
vrai="0"
nom="installation du service docker sur le worker"
verif
#
# Etape 10 node worker
# Jonction de l'hôte au cluster
#
#
vrai="1"
docker swarm join --token ${token}  master.mon.dom:2377
vrai="0"
nom="intégration du noeud worker au cluster"
verif
fi
