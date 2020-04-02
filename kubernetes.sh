#!/bin/sh
#################################################################################
#                           Script de deployement complémentaire pour k8s        #
#################################################################################
#Fonction de vérification des étapes
verif(){
  if [ "${vrai}" -eq "0" ]; then
    echo "Étape - ${node}- ${nom} - OK"
  else
    echo "Erreur étape - ${node}- ${nom}"
    exit 0
  fi
}
repok8s () {
vrai="1"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
vrai="0"
nom="repok8s"
}
# Fonction  de configuration du SElinux et du swap à off
selinuxSwap () {
vrai="1"
setenforce 0 && \
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config && \
swapoff   -a && \
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && \
vrai="0"
nom="selinuxSwap"
}
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
cat <<EOF > /etc/sysctl.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF
vrai="0"
nom="moduleBr"
}
# Fonction de serveur de temps
temps() {
vrai="1"
ntpdate -u 0.fr.pool.ntp.org && \
sed -i -e  "s|server 0.centos.pool.ntp.org|server 0.fr.pool.ntp.org|g" /etc/ntp.conf && \
systemctl enable --now ntpd.service && \
vrai="0"
nom="temps"
}
#################################################################################
#                                                                               #
#                 Début du déploiement                                          #
#                                                                               #
#################################################################################
#################################################################################
#                                                                               #
#                 Déploiement des masters                                       #
#                                                                               #
#################################################################################
clear
until [ "${noeud}" = "worker" -o "${noeud}" = "master" ]
do
echo -n 'Indiquez si cette machine doit être "master" ou "worker", mettre en toutes lettres votre réponse: '
read noeud
done
if [ "${noeud}" = "master" ]
then
# Etape 1 node master
# Configuration repo et swap
#
vrai="1"
repok8s && \
selinuxSwap && \
vrai="0"
nom="installation du module de brige"
verif
# Etape 2 node master
# installation des outils.
#
vrai="1"
yum  install -y ntp kubelet  kubeadm  kubectl  --disableexcludes=kubernetes && \
vrai="0"
nom="installation des outils et services sur le master"
verif
# Etape 3 node master
# installation du modules bridge et gestion de l'horloge.
#
vrai="1"
moduleBr && \
temps && \
vrai="0"
nom="installation du module de brige"
verif
#
# Etape 4 node master
# Démarrage du service kubelet
#
#
vrai="1"
systemctl enable --now kubelet && \
vrai="0"
nom="démarrage de la kubelet"
verif
#
# Etape 5 node master
# deployement de K8S sur le master
#
#
vrai="1"
kubeadm init --apiserver-advertise-address=172.21.0.100 --pod-network-cidr=192.168.0.0/16 && \
vrai="0"
nom="deploiement du cluster K8S"
verif
#
# Etape 6 node master
# autorisation du compte stagiaire à gérer le cluster kubernetes
#
#
vrai="1"
mkdir  -p   /home/stagiaire/.kube && \
cp  -i   /etc/kubernetes/admin.conf  /home/stagiaire/.kube/config && \
chown  -R  stagiaire:wheel   /home/stagiaire/.kube && \
vrai="0"
nom="construction du compte stagiaire avec le controle de K8S"
verif
#
# Etape 7 node master
# permettre à root de temporairement gérer le cluster kubernetes
#
#
vrai="1"
export KUBECONFIG=/etc/kubernetes/admin.conf && \
vrai="0"
nom="export de la variable KUBECONFIG"
verif
#
# Etape 8 node master
# Construire le réseau calico pour k8s
#
#
vrai="1"
kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml && \
vrai="0"
nom="installation de calico"
verif
#
# Etape 9 node master
# configuration de bash-completion pour faciliter les saisies
#
#
vrai="1"
cat <<EOF >> /home/stagiaire/.bashrc
source <(kubectl completion bash)
EOF
vrai="0"
nom="installation et configuration de stagiaire avec bash-completion"
verif
#
# Fin de l'installation sur le master
#
#
echo " "
echo " "
echo "Fin de l'installation du master"
echo " "
echo " Vous pouvez activer le script sur les noeuds workers"
echo " "
#################################################################################
#                                                                               #
#                 installation des workers                                      #
#                                                                               #
#################################################################################
############################################################################################
#                                                                                          #
#                       Déploiement des workers Kubernetes                                 #
#                                                                                          #
############################################################################################
elif [ "${noeud}" = "worker" ]
then
#vrai="1"
#systemctl restart network && \
#vrai="0"
#nom="restart de la pile réseau du worker"
#verif
#
# Etape 2 node worker
# Création des clés pour ssh-copy-id
#
#
vrai="1"
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -P "" && \
ssh-copy-id -i ~/.ssh/id_rsa.pub stagiaire@172.21.0.100 && \
vrai="0"
nom="configuration du ssh agent"
verif
#
# Etape 3 node worker
# Création des clés pour ssh-copy-id
#
#
vrai="1"
alias master="ssh stagiaire@master.mon.dom" && \
export token=`master kubeadm token list | tail -1 | cut -f 1,2 -d " "` && \
tokensha=`master openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'` && \
export tokenca=sha256:${tokensha} && \
vrai="0"
nom="recuperation des clés sur le master pour l'intégration au cluster"
verif
#
# Etape 4 node worker
# Constuction du fichier de configuration du repository de kubernetes
#
#
vrai="1"
repok8s && \
vrai="0"
nom="construction du repository de K8S"
verif
#
# Etape 5 node worker
# Gestion du SELinux et suppression du swap
#
#
vrai="1"
selinuxSwap && \
vrai="0"
nom="configuration du SELINUX"
verif
#
# Etape 6 node worker
# Installation des outils
#
#
vrai="1"
yum install -y ntp kubelet  kubeadm  kubectl --disableexcludes=kubernetes && \
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
sysctl   -w net/ipv4/ip_forward=1 && \
cat <<EOF >> /etc/sysctl.conf
net/ipv4/ip_forward=1
EOF
vrai="0"
nom="installation du module bridge sur le worker"
verif
#
# Etape 9
# Démarrage du service kubelet
#
#
vrai="1"
systemctl enable --now kubelet && \
vrai="0"
nom="demarrage du service kubelet sur le worker"
verif
#
# Etape 10 node worker
# Jonction de l'hôte au cluster
#
#
vrai="1"
kubeadm join master.mon.dom:6443 --token ${token}  --discovery-token-ca-cert-hash ${tokenca} && \
vrai="0"
nom="intégration du noeud worker au cluster"
verif
echo " "
echo " "
echo "Fin de l'installation du noeud"
echo " "
fi
