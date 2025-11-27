#!/bin/bash
# Configuration automatique pour routeur_wil-2
# Usage: ./config-router-2.sh [static|multicast]

MODE=${1:-static}

echo "========================================="
echo "Configuration de routeur_wil-2"
echo "Mode: $MODE"
echo "========================================="

# Configuration des interfaces réseau
echo "Configuration des interfaces réseau..."
ip link set eth0 up
ip addr add 30.1.1.2/24 dev eth0

# eth1 ne nécessite pas d'adresse IP car il fonctionne en couche 2 uniquement
ip link set eth1 up

# Nettoyage des anciennes configurations
echo "Nettoyage des anciennes configurations..."
ip link del vxlan10 2>/dev/null
ip link del br0 2>/dev/null

# Configuration VXLAN selon le mode choisi
if [ "$MODE" = "multicast" ]; then
    echo "Configuration VXLAN en mode MULTICAST..."
    ip link add vxlan10 type vxlan \
        id 10 \
        dstport 4789 \
        dev eth0 \
        local 30.1.1.2 \
        group 239.1.1.1 \
        ttl 5
else
    echo "Configuration VXLAN en mode STATIQUE..."
    ip link add vxlan10 type vxlan \
        id 10 \
        dstport 4789 \
        dev eth0 \
        local 30.1.1.2 \
        remote 30.1.1.1
fi

ip link set vxlan10 up

# Configuration du bridge
echo "Configuration du bridge br0..."
ip link add br0 type bridge
ip link set br0 up

# Ajout des interfaces au bridge
ip link set eth1 master br0
ip link set vxlan10 master br0

echo ""
echo "========================================="
echo "Configuration terminée avec succès!"
echo "========================================="
echo ""

# Affichage de la configuration
echo "Configuration VXLAN:"
ip -d link show vxlan10
echo ""

echo "Interfaces du bridge:"
bridge link show br0
echo ""

echo "Table FDB initiale:"
bridge fdb show dev vxlan10
echo ""

if [ "$MODE" = "multicast" ]; then
    echo "Groupes multicast:"
    ip maddr show dev eth0
    echo ""
fi

echo "Utilisez les commandes suivantes pour le diagnostic:"
echo "  - ip -d link show vxlan10"
echo "  - bridge fdb show dev vxlan10"
echo "  - bridge link show br0"
echo "  - tcpdump -i eth0 port 4789 -vv"

