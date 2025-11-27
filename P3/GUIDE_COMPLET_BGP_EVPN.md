# Guide Complet BGP EVPN - P3

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
   - [Topologie du réseau](#topologie-du-réseau)
   - [Architecture BGP EVPN](#architecture-bgp-evpn)
   - [Plan d'adressage](#plan-dadressage)
2. [Concepts clés](#concepts-clés)
   - [Route Reflector (RR)](#route-reflector-rr)
   - [VTEP (VXLAN Tunnel Endpoint)](#vtep-vxlan-tunnel-endpoint)
   - [Types de routes EVPN](#types-de-routes-evpn)
3. [Pré-requis et préparation](#pré-requis-et-préparation)
4. [Configuration](#configuration)
   - [Route Reflector (jerdos-p1router-1)](#1-route-reflector-jerdos-p1router-1)
   - [VTEP jerdos-p1router-2](#2-vtep-jerdos-p1router-2)
   - [VTEP jerdos-p1router-3](#3-vtep-jerdos-p1router-3)
   - [VTEP jerdos-p1router-4](#4-vtep-jerdos-p1router-4)
   - [Hosts](#5-configuration-des-hosts)
5. [Tests et vérification](#tests-et-vérification)

---

## Vue d'ensemble

Ce projet implémente BGP EVPN (RFC 7432) avec VXLAN pour créer un réseau de datacenter moderne. Le plan de contrôle utilise BGP avec EVPN pour l'apprentissage automatique des adresses MAC, tandis que le plan de données utilise VXLAN pour l'encapsulation.

### Topologie du réseau

```
                                 OSPF + BGP EVPN
                                      AS 1
                          ┌─────────────────────────┐
                          │                         │
                          │    jerdos-p1router-1    │
                          │          (RR)           │
                          │       1.1.1.1/32        │
                          │                         │
                          └──────┬──────┬──────┬───┘
                             eth0│  eth1│  eth2│
                                 │      │      │
                      10.1.1.1/30│      │      │10.1.1.9/30
                                 │      │10.1.1.5/30
                                 │      │      │
    ┌────────────────────────────┼──────┼──────┼────────────────────────┐
    │                      Leafs │(VTEPs)      │                        │
    │                            │      │      │                        │
    │        eth0 ┌──────────────┴┐ eth0│  eth0┌┴──────────────┐        │
    │             │jerdos-p1router│     │      │jerdos-p1router│        │
    │             │      -2       │     │      │      -4       │        │
    │             │   1.1.1.2     │     │      │   1.1.1.4     │        │
    │        eth1 └───────┬───────┘     │      └───────┬───────┘ eth1   │
    │                     │             │              │                │
    │                     │      ┌──────┴──────┐       │                │
    │                     │ eth0 │jerdos-p1router      │                │
    │                     │      │      -3     │       │                │
    │                     │      │   1.1.1.3   │       │                │
    │                     │      └──────┬──────┘ eth1  │                │
    │                     │             │              │                │
    └─────────────────────┼─────────────┼──────────────┼────────────────┘
                          │             │              │
                     eth0 │        eth0 │         eth0 │
                    ┌─────┴─────┐ ┌─────┴─────┐ ┌──────┴──────┐
                    │  jerdos-  │ │  jerdos-  │ │   jerdos-   │
                    │ p1basic-1 │ │ p1basic-2 │ │  p1basic-3  │
                    │ 20.1.1.1  │ │ 20.1.1.2  │ │  20.1.1.3   │
                    └───────────┘ └───────────┘ └─────────────┘
```

**Connexions:**
- `jerdos-p1router-1 (eth0)` ↔ `jerdos-p1router-2 (eth0)`
- `jerdos-p1router-1 (eth1)` ↔ `jerdos-p1router-3 (eth0)`
- `jerdos-p1router-1 (eth2)` ↔ `jerdos-p1router-4 (eth0)`
- `jerdos-p1router-2 (eth1)` ↔ `jerdos-p1basic-1 (eth0)`
- `jerdos-p1router-3 (eth1)` ↔ `jerdos-p1basic-2 (eth0)`
- `jerdos-p1router-4 (eth1)` ↔ `jerdos-p1basic-3 (eth0)`

### Architecture BGP EVPN

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PLAN DE CONTRÔLE                            │
│                                                                     │
│   ┌──────────────┐                                                  │
│   │Route Reflector│  ← Centralise les routes BGP EVPN              │
│   │  (iBGP RR)   │                                                  │
│   └───────┬──────┘                                                  │
│           │ iBGP Sessions (AS 1)                                    │
│     ┌─────┼─────┬─────────────┐                                     │
│     ▼     ▼     ▼             ▼                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐                                         │
│  │VTEP-2│ │VTEP-3│ │VTEP-4│ ← Leaf switches                        │
│  └──────┘ └──────┘ └──────┘                                         │
│                                                                     │
│   OSPF: Assure la connectivité IP entre loopbacks                   │
│   BGP EVPN: Distribue les informations MAC/IP                       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         PLAN DE DONNÉES                             │
│                                                                     │
│   VXLAN (VNI 10) - Tunnels entre VTEPs                             │
│                                                                     │
│   VTEP-2 ◄──────────────────────────────────────────────► VTEP-4   │
│      ▲                                                       ▲      │
│      │                        VXLAN                          │      │
│      └───────────────────────► VTEP-3 ◄──────────────────────┘      │
│                                                                     │
│   Encapsulation: Trames L2 → Paquets UDP (port 4789)               │
└─────────────────────────────────────────────────────────────────────┘
```

### Plan d'adressage

#### Adresses Loopback (Router IDs)

| Équipement | Loopback | Rôle |
|------------|----------|------|
| jerdos-p1router-1 | 1.1.1.1/32 | Route Reflector |
| jerdos-p1router-2 | 1.1.1.2/32 | VTEP/Leaf |
| jerdos-p1router-3 | 1.1.1.3/32 | VTEP/Leaf |
| jerdos-p1router-4 | 1.1.1.4/32 | VTEP/Leaf |

#### Réseau OSPF (Transport L3) - 10.1.1.0/24

| Lien | Interface RR | IP RR | Interface Leaf | IP Leaf |
|------|--------------|-------|----------------|---------|
| RR ↔ Leaf-2 | eth0 | 10.1.1.1/30 | eth0 | 10.1.1.2/30 |
| RR ↔ Leaf-3 | eth1 | 10.1.1.5/30 | eth0 | 10.1.1.6/30 |
| RR ↔ Leaf-4 | eth2 | 10.1.1.9/30 | eth0 | 10.1.1.10/30 |

#### Réseau VXLAN (Hosts) - 20.1.1.0/24

| Host | Interface | IP |
|------|-----------|-----|
| jerdos-p1basic-1 | eth0 | 20.1.1.1/24 |
| jerdos-p1basic-2 | eth0 | 20.1.1.2/24 |
| jerdos-p1basic-3 | eth0 | 20.1.1.3/24 |

---

## Concepts clés

### Route Reflector (RR)

Le Route Reflector est un routeur BGP qui reflète les routes apprises d'un client iBGP vers d'autres clients iBGP. Cela évite le besoin d'un maillage complet (full mesh) entre tous les routeurs BGP.

**Avantages:**
- Réduit le nombre de sessions BGP nécessaires
- Simplifie la configuration
- Améliore la scalabilité

**Fonctionnement:**
```
Sans RR (full mesh):          Avec RR:
    A ─── B                      A
    │\   /│                       \
    │ \ / │                        \
    │  X  │                   RR ───┼─── B
    │ / \ │                        /
    │/   \│                       /
    C ─── D                      C
  
  6 sessions iBGP              3 sessions iBGP
```

### VTEP (VXLAN Tunnel Endpoint)

Les VTEPs sont les points de terminaison des tunnels VXLAN. Ils encapsulent et décapsulent les trames Ethernet dans des paquets UDP.

**Caractéristiques:**
- Identifié par son adresse IP (loopback)
- Participe au plan de contrôle BGP EVPN
- Gère le mapping MAC ↔ VTEP distant

### Peer-Group BGP

Un **peer-group** est un modèle de configuration BGP qui permet de regrouper plusieurs voisins ayant les mêmes paramètres. C'est un mécanisme de simplification et d'optimisation.

#### Pourquoi utiliser un peer-group ?

**Sans peer-group (configuration répétitive) :**
```bash
neighbor 1.1.1.2 remote-as 1
neighbor 1.1.1.2 update-source lo
neighbor 1.1.1.2 route-reflector-client

neighbor 1.1.1.3 remote-as 1
neighbor 1.1.1.3 update-source lo
neighbor 1.1.1.3 route-reflector-client

neighbor 1.1.1.4 remote-as 1
neighbor 1.1.1.4 update-source lo
neighbor 1.1.1.4 route-reflector-client
```
**Problème :** Si on veut changer `remote-as` ou `update-source`, il faut modifier 3 fois !

**Avec peer-group (configuration centralisée) :**
```bash
# 1. Créer le peer-group avec les paramètres communs
neighbor ibgp-clients peer-group
neighbor ibgp-clients remote-as 1
neighbor ibgp-clients update-source lo

# 2. Assigner les voisins au groupe
neighbor 1.1.1.2 peer-group ibgp-clients
neighbor 1.1.1.3 peer-group ibgp-clients
neighbor 1.1.1.4 peer-group ibgp-clients
```


### Types de routes EVPN

#### Type 2: MAC/IP Advertisement Route
- Annonce les adresses MAC apprises localement
- Peut inclure l'adresse IP associée (ARP binding)
- Format: `[2]:[EthTag]:[MAC]:[IP]`

```
Exemple d'apprentissage Type 2:
1. jerdos-p1basic-1 envoie un paquet ARP
2. jerdos-p1router-2 apprend la MAC 62:b7:1f:a6:5a:34
3. jerdos-p1router-2 annonce via BGP EVPN:
   Route Type 2: [2]:[0]:[48]:[62:b7:1f:a6:5a:34]
4. Le RR reflète vers tous les autres VTEPs
```

#### Type 3: Inclusive Multicast Ethernet Tag (IMET)
- Indique la présence d'un VTEP dans un VNI
- Utilisé pour le BUM traffic (Broadcast, Unknown unicast, Multicast)
- Format: `[3]:[EthTag]:[IPlen]:[OrigIP]`

```
Exemple Type 3:
Route: [3]:[0]:[32]:[1.1.1.2]
       │   │    │      │
       │   │    │      └─ IP du VTEP (loopback)
       │   │    └─ Longueur du préfixe IP
       │   └─ Ethernet Tag (0 = non utilisé)
       └─ Type de route (3 = IMET)
```

---

## Pré-requis et préparation

### Images Docker

Depuis le répertoire P3/, construire l'image du routeur FRR:

```bash
cd ../P3
docker build -t onyx/p1router:latest -f Dockerfile.router .
docker build -t onyx/p1basic:latest -f Dockerfile.basic .
```

### Services FRR requis

Pour ce projet, nous utilisons FRRouting (FRR) avec les démons suivants:
- **zebra**: Gestion des routes et interfaces
- **ospfd**: Protocole OSPF pour la connectivité L3
- **bgpd**: BGP avec support EVPN

---

## Configuration

### 1. Route Reflector (jerdos-p1router-1)

**Image Docker:** `onyx/p1router:latest`

#### Script de configuration système

```bash
#!/bin/bash
# config-rr.sh - Configuration du Route Reflector

# ==========================================
# CONFIGURATION DES INTERFACES RÉSEAU
# ==========================================

# Loopback - Utilisé comme Router ID pour OSPF et BGP
ip addr add 1.1.1.1/32 dev lo

# Interface vers jerdos-p1router-2 (Leaf)
ip link set eth0 up
ip addr add 10.1.1.1/30 dev eth0

# Interface vers jerdos-p1router-3 (Leaf)
ip link set eth1 up
ip addr add 10.1.1.5/30 dev eth1

# Interface vers jerdos-p1router-4 (Leaf)
ip link set eth2 up
ip addr add 10.1.1.9/30 dev eth2

echo "Interfaces configurées sur le Route Reflector"
```

#### Configuration FRR (vtysh)

```bash
vtysh
configure terminal

# ==========================================
# CONFIGURATION DU HOSTNAME
# ==========================================
hostname jerdos-p1router-1

# ==========================================
# CONFIGURATION OSPF
# ==========================================
# OSPF assure la connectivité IP entre tous les loopbacks
# C'est nécessaire pour que BGP puisse établir ses sessions

router ospf
 # Utilise le loopback comme Router ID pour la stabilité
 ospf router-id 1.1.1.1
 
 # Annonce le loopback dans OSPF (essentiel pour BGP)
 network 1.1.1.1/32 area 0
 
 # Annonce les réseaux point-à-point vers les Leafs
 network 10.1.1.0/30 area 0
 network 10.1.1.4/30 area 0
 network 10.1.1.8/30 area 0
exit

# ==========================================
# CONFIGURATION BGP AVEC EVPN
# ==========================================
router bgp 1
 # Router ID basé sur le loopback
 bgp router-id 1.1.1.1
 
 # Désactive la vérification de l'AS pour iBGP
 no bgp ebgp-requires-policy
 
 # ----------------------------------------
 # Configuration du neighbor group pour les clients RR
 # ----------------------------------------
 # 
 # PEER-GROUP : Qu'est-ce que c'est ?
 # ===================================
 # Un peer-group est un "modèle" de configuration que l'on applique
 # à plusieurs voisins BGP. Au lieu de répéter les mêmes commandes
 # pour chaque voisin, on les définit une fois dans le peer-group
 # et on assigne les voisins à ce groupe.
 #
 # Avantages :
 # - Réduit la duplication de configuration
 # - Facilite la maintenance (changement en un seul endroit)
 # - Améliore les performances (BGP traite le groupe comme une unité)
 #
 # Comment ça fonctionne :
 # 1. On crée le peer-group avec un nom (ici "ibgp-clients")
 # 2. On configure les paramètres communs dans le peer-group
 # 3. On assigne chaque voisin au peer-group
 # 4. Les voisins héritent automatiquement de la configuration du groupe
 #
 neighbor ibgp-clients peer-group
 neighbor ibgp-clients remote-as 1
 neighbor ibgp-clients update-source lo
 
 # Les 3 Leafs sont des clients du Route Reflector
 # Chaque voisin hérite automatiquement de :
 # - remote-as 1
 # - update-source lo
 neighbor 1.1.1.2 peer-group ibgp-clients
 neighbor 1.1.1.3 peer-group ibgp-clients
 neighbor 1.1.1.4 peer-group ibgp-clients
 
 # ----------------------------------------
 # Address Family L2VPN EVPN
 # ----------------------------------------
 address-family l2vpn evpn
  # Active les neighbors dans cette famille d'adresses
  neighbor ibgp-clients activate
  
  # Configure ce routeur comme Route Reflector
  # Les routes reçues seront reflétées vers les autres clients
  neighbor ibgp-clients route-reflector-client
 exit-address-family
exit

end
write memory
```

### 2. VTEP jerdos-p1router-2

**Image Docker:** `onyx/p1router:latest`

#### Script de configuration système

```bash
#!/bin/bash
# config-leaf-2.sh - Configuration du VTEP jerdos-p1router-2

# ==========================================
# CONFIGURATION DES INTERFACES RÉSEAU
# ==========================================

# Loopback - Router ID et adresse source VTEP
ip addr add 1.1.1.2/32 dev lo

# Interface vers le Route Reflector (eth0)
ip link set eth0 up
ip addr add 10.1.1.2/30 dev eth0

# Interface vers jerdos-p1basic-1 (L2 uniquement via eth1)
ip link set eth1 up

# ==========================================
# CONFIGURATION VXLAN
# ==========================================

# Création de l'interface VXLAN
# - id 10: VNI (VXLAN Network Identifier)
# - dstport 4789: Port UDP standard VXLAN
# - local: Adresse source du VTEP (loopback)
# - nolearning: Désactive l'apprentissage MAC local
#   (BGP EVPN gère l'apprentissage)
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.2 \
    nolearning

ip link set vxlan10 up

# ==========================================
# CONFIGURATION DU BRIDGE
# ==========================================

# Le bridge connecte l'interface locale avec le tunnel VXLAN
ip link add br0 type bridge
ip link set br0 up

# Ajout des interfaces au bridge
ip link set eth1 master br0
ip link set vxlan10 master br0

echo "VTEP jerdos-p1router-2 configuré"
```

#### Configuration FRR (vtysh)

```bash
vtysh
configure terminal

hostname jerdos-p1router-2

# ==========================================
# CONFIGURATION OSPF
# ==========================================
router ospf
 ospf router-id 1.1.1.2
 
 # Annonce le loopback (utilisé pour VTEP et BGP)
 network 1.1.1.2/32 area 0
 
 # Annonce le réseau vers le RR
 network 10.1.1.0/30 area 0
exit

# ==========================================
# CONFIGURATION BGP AVEC EVPN
# ==========================================
router bgp 1
 bgp router-id 1.1.1.2
 no bgp ebgp-requires-policy
 
 # Session iBGP vers le Route Reflector
 # update-source lo: Utilise le loopback comme source
 neighbor 1.1.1.1 remote-as 1
 neighbor 1.1.1.1 update-source lo
 
 # ----------------------------------------
 # Address Family L2VPN EVPN
 # ----------------------------------------
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  
  # Annonce ce VTEP pour le VNI 10
  # rd: Route Distinguisher (format Router-ID:VNI)
  # route-target: Import/Export des routes EVPN
  advertise-all-vni
 exit-address-family
exit

end
write memory
```

### 3. VTEP jerdos-p1router-3

**Image Docker:** `onyx/p1router:latest`

#### Script de configuration système

```bash
#!/bin/bash
# config-leaf-3.sh - Configuration du VTEP jerdos-p1router-3

# ==========================================
# CONFIGURATION DES INTERFACES RÉSEAU
# ==========================================

ip addr add 1.1.1.3/32 dev lo

# Interface vers le Route Reflector (via eth0)
ip link set eth0 up
ip addr add 10.1.1.6/30 dev eth0

# Interface vers jerdos-p1basic-2 (L2 uniquement via eth1)
ip link set eth1 up

# ==========================================
# CONFIGURATION VXLAN
# ==========================================

ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.3 \
    nolearning

ip link set vxlan10 up

# ==========================================
# CONFIGURATION DU BRIDGE
# ==========================================

ip link add br0 type bridge
ip link set br0 up

# eth1: vers jerdos-p1basic-2
ip link set eth1 master br0
ip link set vxlan10 master br0

echo "VTEP jerdos-p1router-3 configuré"
```

#### Configuration FRR (vtysh)

```bash
vtysh
configure terminal

hostname jerdos-p1router-3

router ospf
 ospf router-id 1.1.1.3
 network 1.1.1.3/32 area 0
 # Réseau vers RR via eth0
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
```

### 4. VTEP jerdos-p1router-4

**Image Docker:** `onyx/p1router:latest`

#### Script de configuration système

```bash
#!/bin/bash
# config-leaf-4.sh - Configuration du VTEP jerdos-p1router-4

# ==========================================
# CONFIGURATION DES INTERFACES RÉSEAU
# ==========================================

ip addr add 1.1.1.4/32 dev lo

# Interface vers le Route Reflector (via eth0)
ip link set eth0 up
ip addr add 10.1.1.10/30 dev eth0

# Interface vers jerdos-p1basic-3 (L2 uniquement via eth1)
ip link set eth1 up

# ==========================================
# CONFIGURATION VXLAN
# ==========================================

ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.4 \
    nolearning

ip link set vxlan10 up

# ==========================================
# CONFIGURATION DU BRIDGE
# ==========================================

ip link add br0 type bridge
ip link set br0 up

# eth1: vers jerdos-p1basic-3
ip link set eth1 master br0
ip link set vxlan10 master br0

echo "VTEP jerdos-p1router-4 configuré"
```

#### Configuration FRR (vtysh)

```bash
vtysh
configure terminal

hostname jerdos-p1router-4

router ospf
 ospf router-id 1.1.1.4
 network 1.1.1.4/32 area 0
 # Réseau vers RR via eth0
 network 10.1.1.8/30 area 0
exit

router bgp 1
 bgp router-id 1.1.1.4
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
```

### 5. Configuration des Hosts

Les hosts sont de simples containers qui n'ont pas besoin de FRR. Ils utilisent uniquement des adresses IP dans le réseau VXLAN (20.1.1.0/24).

#### jerdos-p1basic-1

```bash
#!/bin/bash
# config-host-1.sh

# Interface connectée à jerdos-p1router-2 (eth1) via eth0
ip link set eth0 up
ip addr add 20.1.1.1/24 dev eth0

echo "jerdos-p1basic-1 configuré avec IP 20.1.1.1"
```

#### jerdos-p1basic-2

```bash
#!/bin/bash
# config-host-2.sh

# Interface connectée à jerdos-p1router-3 (eth1) via eth0
ip link set eth0 up
ip addr add 20.1.1.2/24 dev eth0

echo "jerdos-p1basic-2 configuré avec IP 20.1.1.2"
```

#### jerdos-p1basic-3

```bash
#!/bin/bash
# config-host-3.sh

# Interface connectée à jerdos-p1router-4 (eth1) via eth0
ip link set eth0 up
ip addr add 20.1.1.3/24 dev eth0

echo "jerdos-p1basic-3 configuré avec IP 20.1.1.3"
```

---

## Tests et vérification

### 1. Vérification OSPF

Sur chaque routeur:

```bash
# Vérifier les voisins OSPF
vtysh -c "show ip ospf neighbor"

# Vérifier les routes OSPF
vtysh -c "show ip route ospf"

# Sur le RR, vous devriez voir tous les loopbacks:
# O   1.1.1.2/32 [110/20] via 10.1.1.2, eth0
# O   1.1.1.3/32 [110/20] via 10.1.1.6, eth1
# O   1.1.1.4/32 [110/20] via 10.1.1.10, eth2
```

### 2. Vérification BGP

```bash
# Vérifier les sessions BGP
vtysh -c "show bgp summary"

# Exemple de sortie sur un VTEP:
# Neighbor   V  AS   MsgRcvd  MsgSent  State/PfxRcd
# 1.1.1.1    4  1    xxx      xxx      0 (ou nombre de préfixes)
```

### 3. Vérification BGP EVPN

```bash
# Voir les routes L2VPN EVPN
vtysh -c "show bgp l2vpn evpn"

# Voir le résumé L2VPN EVPN
vtysh -c "show bgp l2vpn evpn summary"

# Routes Type 3 (IMET) - présentes même sans hosts
# Route Distinguisher: 1.1.1.2:2
# *> [3]:[0]:[32]:[1.1.1.2]
#       1.1.1.2                        32768 i

# Routes Type 2 (MAC/IP) - apparaissent quand les hosts sont actifs
# *>i[2]:[0]:[48]:[62:b7:1f:a6:5a:34]
#       1.1.1.2                    0    100      0 i
```

### 4. Vérification VXLAN

Sur les VTEPs:

```bash
# Voir la configuration VXLAN
ip -d link show vxlan10

# Voir la table FDB (Forwarding Database)
bridge fdb show dev vxlan10

# Les entrées FDB sont automatiquement peuplées par BGP EVPN
```

### 5. Test de connectivité

```bash
# Depuis jerdos-p1basic-1:
ping 20.1.1.2  # Vers jerdos-p1basic-2
ping 20.1.1.3  # Vers jerdos-p1basic-3

# Tracer le chemin
traceroute 20.1.1.2
```

### 6. Capture de trafic

Sur un VTEP ou le switch:

```bash
# Capturer le trafic VXLAN
tcpdump -i eth0 port 4789 -vv

# Dans Wireshark, filtres utiles:
# vxlan.vni == 10
# udp.port == 4789
# vxlan && icmp
```

---

## Résumé du flux de données

```
1. jerdos-p1basic-1 (20.1.1.1) veut pinger jerdos-p1basic-3 (20.1.1.3)

2. Le ping arrive sur jerdos-p1router-2 (VTEP)
   - Le bridge br0 reçoit la trame
   - BGP EVPN indique que 20.1.1.3 est derrière VTEP 1.1.1.4

3. jerdos-p1router-2 encapsule dans VXLAN:
   - Trame originale → Paquet UDP (port 4789)
   - Source IP: 1.1.1.2 (loopback)
   - Destination IP: 1.1.1.4 (loopback distant)
   - VNI: 10

4. Le paquet traverse le réseau L3:
   - Route via OSPF: 1.1.1.2 → 10.1.1.1 (RR) → 10.1.1.9 (vers VTEP-4)

5. jerdos-p1router-4 reçoit et décapsule:
   - Extrait la trame originale
   - Forward via br0 vers eth1

6. jerdos-p1basic-3 reçoit le ping et répond
   - Le chemin inverse est utilisé pour la réponse
```

---

## Commandes de diagnostic rapide

| Commande | Description |
|----------|-------------|
| `show ip ospf neighbor` | Voisins OSPF |
| `show ip route` | Table de routage complète |
| `show bgp summary` | État des sessions BGP |
| `show bgp l2vpn evpn` | Routes EVPN |
| `show bgp l2vpn evpn summary` | Résumé EVPN avec compteurs |
| `show evpn vni` | VNIs configurés |
| `show evpn mac vni 10` | MACs apprises pour VNI 10 |
| `bridge fdb show dev vxlan10` | Table FDB du bridge |
| `ip -d link show vxlan10` | Détails interface VXLAN |

---
