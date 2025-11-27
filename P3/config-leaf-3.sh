#!/bin/bash
# ============================================================
# Configuration du VTEP jerdos-p1router-3 (Leaf)
# ============================================================
# Connexions:
# - eth0: vers Route Reflector (jerdos-p1router-1 eth1)
# - eth1: vers jerdos-p1basic-2 (L2 via bridge)
# ============================================================

echo "========================================="
echo "Configuration de jerdos-p1router-3 (VTEP/Leaf)"
echo "========================================="

# ==========================================
# CONFIGURATION DES INTERFACES RÉSEAU
# ==========================================

echo "[1/4] Configuration des interfaces..."

# Loopback
ip addr add 1.1.1.3/32 dev lo

# Interface vers le Route Reflector (via eth0)
ip link set eth0 up
ip addr add 10.1.1.6/30 dev eth0

# Interface vers jerdos-p1basic-2 (via eth1, L2 uniquement)
ip link set eth1 up

echo "   Loopback: 1.1.1.3/32"
echo "   eth0: 10.1.1.6/30 (vers RR)"
echo "   eth1: (L2 vers jerdos-p1basic-2)"

# ==========================================
# CONFIGURATION VXLAN
# ==========================================

echo "[2/4] Configuration VXLAN..."

ip link del vxlan10 2>/dev/null
ip link del br0 2>/dev/null

ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.3 \
    nolearning

ip link set vxlan10 up

echo "   Interface vxlan10 créée (VNI 10)"

# ==========================================
# CONFIGURATION DU BRIDGE
# ==========================================

echo "[3/4] Configuration du bridge..."

ip link add br0 type bridge
ip link set br0 up

# eth1: vers jerdos-p1basic-2
# vxlan10: tunnel VXLAN
ip link set eth1 master br0
ip link set vxlan10 master br0

echo "   Bridge br0 créé avec eth1 et vxlan10"

# ==========================================
# CONFIGURATION FRR (OSPF + BGP EVPN)
# ==========================================

echo "[4/4] Configuration de FRR (OSPF + BGP EVPN)..."

vtysh << 'EOF'
configure terminal

hostname jerdos-p1router-3

router ospf
 ospf router-id 1.1.1.3
 network 1.1.1.3/32 area 0
 ! Réseau vers RR via eth0
 network 10.1.1.4/30 area 0
exit

router bgp 1
 bgp router-id 1.1.1.3
 no bgp ebgp-requires-policy
 
 neighbor 1.1.1.1 remote-as 1
 neighbor 1.1.1.1 update-source lo
 
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
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
echo "Configuration de jerdos-p1router-3 terminée!"
echo "========================================="
