#!/bin/bash
# ============================================================
# Configuration de jerdos-p1basic-1
# ============================================================
# Host simple connecté au VTEP jerdos-p1router-2
# 
# Ce host n'a pas besoin de FRR car il ne participe pas
# au routage. Il est simplement dans le réseau VXLAN L2.
#
# Connexion: eth0 → jerdos-p1router-2 (eth1)
# ============================================================

echo "========================================="
echo "Configuration de jerdos-p1basic-1"
echo "========================================="

# Interface connectée à jerdos-p1router-2 via eth0
ip link set eth0 up
ip addr add 20.1.1.1/24 dev eth0

echo "Configuration terminée:"
echo "  Interface: eth0"
echo "  Adresse IP: 20.1.1.1/24"
echo ""
echo "Commandes de test:"
echo "  ping 20.1.1.2   # Vers jerdos-p1basic-2"
echo "  ping 20.1.1.3   # Vers jerdos-p1basic-3"
