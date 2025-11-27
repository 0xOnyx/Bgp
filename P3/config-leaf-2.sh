#!/bin/bash
# ============================================================
# Configuration du VTEP jerdos-p1router-2 (Leaf)
# ============================================================
# Ce script configure un VTEP (VXLAN Tunnel Endpoint) qui:
# - Participe au plan de contrôle BGP EVPN
# - Encapsule/décapsule le trafic VXLAN
# - Apprend automatiquement les adresses MAC via BGP
#
# Connexions:
# - eth0: vers Route Reflector (jerdos-p1router-1)
# - eth1: vers jerdos-p1basic-1 (L2 via bridge)
# ============================================================

echo "========================================="
echo "Configuration de jerdos-p1router-2 (VTEP/Leaf)"
echo "========================================="

# ==========================================
# CONFIGURATION DES INTERFACES RÉSEAU
# ==========================================

echo "[1/4] Configuration des interfaces..."

# Loopback - Router ID et adresse source VTEP
# Cette adresse est annoncée via OSPF et utilisée pour:
# - L'identifiant BGP
# - La source des tunnels VXLAN
ip addr add 1.1.1.2/32 dev lo

# Interface vers le Route Reflector (eth0)
ip link set eth0 up
ip addr add 10.1.1.2/30 dev eth0

# Interface vers jerdos-p1basic-1 (eth1)
# PAS d'adresse IP car elle fonctionne en L2 (bridge)
ip link set eth1 up

echo "   Loopback: 1.1.1.2/32"
echo "   eth0: 10.1.1.2/30 (vers RR)"
echo "   eth1: (L2 vers jerdos-p1basic-1)"

# ==========================================
# CONFIGURATION VXLAN
# ==========================================

echo "[2/4] Configuration VXLAN..."

# Nettoyage des anciennes configurations
ip link del vxlan10 2>/dev/null
ip link del br0 2>/dev/null

# Création de l'interface VXLAN
# Paramètres:
# - id 10: VNI (VXLAN Network Identifier) - identifie le réseau L2 virtuel
# - dstport 4789: Port UDP standard VXLAN (RFC 7348)
# - local 1.1.1.2: Adresse source du VTEP (loopback)
# - nolearning: Désactive l'apprentissage MAC local
#   BGP EVPN gère l'apprentissage des MAC distantes
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.2 \
    nolearning

ip link set vxlan10 up

echo "   Interface vxlan10 créée (VNI 10)"

# ==========================================
# CONFIGURATION DU BRIDGE
# ==========================================

echo "[3/4] Configuration du bridge..."

# Le bridge connecte:
# - eth1: interface locale vers le host
# - vxlan10: tunnel VXLAN vers les autres VTEPs
#
# Cela crée un domaine L2 étendu entre tous les VTEPs

ip link add br0 type bridge
ip link set br0 up

# Ajout des interfaces au bridge
# eth1: trafic local depuis/vers jerdos-p1basic-1
# vxlan10: trafic encapsulé depuis/vers les autres VTEPs
ip link set eth1 master br0
ip link set vxlan10 master br0

echo "   Bridge br0 créé avec eth1 et vxlan10"

# ==========================================
# CONFIGURATION FRR (OSPF + BGP EVPN)
# ==========================================

echo "[4/4] Configuration de FRR (OSPF + BGP EVPN)..."

vtysh << 'EOF'
configure terminal

hostname jerdos-p1router-2

! ==========================================
! CONFIGURATION OSPF
! ==========================================
! OSPF est utilisé uniquement pour la connectivité IP
! entre les loopbacks. Les routes EVPN passent par BGP.

router ospf
 ospf router-id 1.1.1.2
 
 ! Annonce le loopback (utilisé pour VTEP et BGP)
 network 1.1.1.2/32 area 0
 
 ! Annonce le réseau vers le RR (eth0)
 network 10.1.1.0/30 area 0
exit

! ==========================================
! CONFIGURATION BGP AVEC EVPN
! ==========================================

router bgp 1
 bgp router-id 1.1.1.2
 no bgp ebgp-requires-policy
 
 ! Session iBGP vers le Route Reflector uniquement
 ! Pas besoin de sessions vers les autres Leafs grâce au RR
 neighbor 1.1.1.1 remote-as 1
 neighbor 1.1.1.1 update-source lo
 
 ! ----------------------------------------
 ! Address Family L2VPN EVPN
 ! ----------------------------------------
 address-family l2vpn evpn
  ! Active la session EVPN avec le RR
  neighbor 1.1.1.1 activate
  
  ! Annonce automatiquement tous les VNIs locaux
  ! Cela génère les routes Type 3 (IMET) pour chaque VNI
  advertise-all-vni
 exit-address-family
exit

end
write memory
EOF

# ==========================================
# VÉRIFICATION
# ==========================================

echo ""
echo "=== Configuration VXLAN ==="
ip -d link show vxlan10

echo ""
echo "=== Interfaces du bridge ==="
bridge link show br0

echo ""
echo "========================================="
echo "Configuration de jerdos-p1router-2 terminée!"
echo "========================================="
echo ""
echo "Commandes de vérification utiles:"
echo "  vtysh -c 'show ip ospf neighbor'"
echo "  vtysh -c 'show bgp summary'"
echo "  vtysh -c 'show bgp l2vpn evpn'"
echo "  bridge fdb show dev vxlan10"
