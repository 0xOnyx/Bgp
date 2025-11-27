#!/bin/bash
# ============================================================
# Configuration du Route Reflector (jerdos-p1router-1)
# ============================================================
# Ce script configure le routeur central qui agit comme
# Route Reflector BGP pour tous les VTEPs du datacenter.
#
# Rôle: Centraliser et redistribuer les routes BGP EVPN
# sans nécessiter un full-mesh entre tous les Leafs.
# ============================================================

echo "========================================="
echo "Configuration de jerdos-p1router-1 (Route Reflector)"
echo "========================================="

# ==========================================
# CONFIGURATION DES INTERFACES RÉSEAU
# ==========================================

echo "[1/3] Configuration des interfaces..."

# Loopback - Utilisé comme Router ID pour OSPF et BGP
# C'est l'identifiant stable du routeur dans le réseau
ip addr add 1.1.1.1/32 dev lo

# Interface eth0 - Connexion vers jerdos-p1router-2 (Leaf)
# Réseau point-à-point /30
ip link set eth0 up
ip addr add 10.1.1.1/30 dev eth0

# Interface eth1 - Connexion vers jerdos-p1router-3 (Leaf)
ip link set eth1 up
ip addr add 10.1.1.5/30 dev eth1

# Interface eth2 - Connexion vers jerdos-p1router-4 (Leaf)
ip link set eth2 up
ip addr add 10.1.1.9/30 dev eth2

echo "   Loopback: 1.1.1.1/32"
echo "   eth0: 10.1.1.1/30 (vers jerdos-p1router-2)"
echo "   eth1: 10.1.1.5/30 (vers jerdos-p1router-3)"
echo "   eth2: 10.1.1.9/30 (vers jerdos-p1router-4)"

# ==========================================
# CONFIGURATION FRR (OSPF + BGP EVPN)
# ==========================================

echo "[2/3] Configuration de FRR (OSPF + BGP EVPN)..."

# Écriture de la configuration FRR
vtysh << 'EOF'
configure terminal

! ==========================================
! CONFIGURATION DU HOSTNAME
! ==========================================
hostname jerdos-p1router-1

! ==========================================
! CONFIGURATION OSPF
! ==========================================
! OSPF assure la connectivité IP entre tous les loopbacks
! C'est nécessaire pour que BGP puisse établir ses sessions
! car BGP utilise les loopbacks comme source (update-source lo)

router ospf
 ! Router ID basé sur le loopback pour la stabilité
 ! Si le routeur redémarre, il garde le même ID
 ospf router-id 1.1.1.1
 
 ! Annonce le loopback dans OSPF
 ! ESSENTIEL: Les autres routeurs doivent pouvoir joindre ce loopback
 ! pour établir les sessions BGP
 network 1.1.1.1/32 area 0
 
 ! Annonce les réseaux point-à-point vers les Leafs
 ! Ces réseaux permettent la connectivité physique
 network 10.1.1.0/30 area 0
 network 10.1.1.4/30 area 0
 network 10.1.1.8/30 area 0
exit

! ==========================================
! CONFIGURATION BGP AVEC EVPN
! ==========================================
! BGP EVPN est utilisé pour:
! - Distribuer les informations MAC/IP apprises par les VTEPs
! - Permettre l'apprentissage automatique des adresses MAC
! - Optimiser le trafic BUM (Broadcast, Unknown unicast, Multicast)

router bgp 1
 ! Router ID BGP - doit être unique dans l'AS
 bgp router-id 1.1.1.1
 
 ! Désactive la vérification de politique pour iBGP
 ! (simplifie la configuration pour les labs)
 no bgp ebgp-requires-policy
 
 ! ----------------------------------------
 ! Configuration du peer-group pour les clients RR
 ! ----------------------------------------
 ! Un peer-group permet d'appliquer la même configuration
 ! à plusieurs neighbors, simplifiant la maintenance
 
 neighbor ibgp-clients peer-group
 neighbor ibgp-clients remote-as 1
 neighbor ibgp-clients update-source lo
 
 ! Les 3 Leafs (VTEPs) sont des clients du Route Reflector
 ! Ils utilisent leurs loopbacks comme source BGP
 neighbor 1.1.1.2 peer-group ibgp-clients
 neighbor 1.1.1.3 peer-group ibgp-clients
 neighbor 1.1.1.4 peer-group ibgp-clients
 
 ! ----------------------------------------
 ! Address Family L2VPN EVPN
 ! ----------------------------------------
 ! Cette famille d'adresses permet de transporter
 ! les informations EVPN (MAC, VNI, etc.) via BGP
 
 address-family l2vpn evpn
  ! Active les neighbors dans cette famille d'adresses
  neighbor ibgp-clients activate
  
  ! Configure ce routeur comme Route Reflector
  ! Les routes reçues d'un client seront reflétées vers les autres
  ! Cela évite le besoin d'un full-mesh iBGP entre tous les Leafs
  neighbor ibgp-clients route-reflector-client
 exit-address-family
exit

end
write memory
EOF

# ==========================================
# VÉRIFICATION
# ==========================================

echo "[3/3] Vérification de la configuration..."
echo ""

echo "=== Interfaces ==="
ip -br addr show

echo ""
echo "=== Routes OSPF (après convergence) ==="
echo "Attendez quelques secondes pour la convergence OSPF..."

echo ""
echo "========================================="
echo "Configuration du Route Reflector terminée!"
echo "========================================="
echo ""
echo "Commandes de vérification utiles:"
echo "  vtysh -c 'show ip ospf neighbor'"
echo "  vtysh -c 'show bgp summary'"
echo "  vtysh -c 'show bgp l2vpn evpn summary'"
echo "  vtysh -c 'show running-config'"
