#!/bin/bash
# Configuration automatique pour host_wil-2

echo "========================================="
echo "Configuration de host_wil-2"
echo "========================================="

# Configuration de l'interface réseau
echo "Configuration de l'interface réseau..."
ip link set eth0 up
ip addr add 10.1.1.2/24 dev eth0

echo ""
echo "Configuration terminée!"
echo ""

# Affichage de la configuration
echo "Adresse IP configurée:"
ip addr show eth0 | grep inet
echo ""

# Test de connectivité
echo "Test de connectivité vers host_wil-1 (10.1.1.1)..."
ping 10.1.1.1 -c 4 -W 2 || echo "Pas encore de connectivité (normal si l'autre host n'est pas configuré)"
echo ""

echo "Configuration réseau terminée!"

