#!/bin/bash
# Configuration automatique pour Switch_wil

echo "========================================="
echo "Configuration de Switch_wil"
echo "========================================="

# Configuration des interfaces réseau
echo "Configuration des interfaces réseau..."
ip link set eth0 up
ip link set eth1 up

# Nettoyage des anciennes configurations
echo "Nettoyage des anciennes configurations..."
ip link del br0 2>/dev/null

# Configuration du bridge pour la commutation L2
echo "Configuration du bridge br0..."
ip link add br0 type bridge
ip link set br0 up

# Ajout des interfaces au bridge
ip link set eth0 master br0
ip link set eth1 master br0

echo ""
echo "========================================="
echo "Configuration terminée avec succès!"
echo "========================================="
echo ""

# Affichage de la configuration
echo "Interfaces du bridge:"
bridge link show br0
echo ""

echo "État des interfaces:"
ip link show br0
ip link show eth0
ip link show eth1
echo ""

echo "Switch L2 opérationnel!"

