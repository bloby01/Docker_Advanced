#! /bin/sh
clear
echo -n "Mettre l'adresse ip de la gateway: "
read gateway
ip route add 0.0.0.0/0 via $gateway
echo " " ; echo "###########"
echo "" ; echo "Liste des routes disponibles"
ip route
