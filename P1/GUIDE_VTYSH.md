# Guide d'utilisation de vtysh avec FRRouting

## Introduction

`vtysh` est l'interface en ligne de commande pour configurer FRRouting (FRR). C'est comme un shell interactif pour configurer vos protocoles de routage.

## Démarrage rapide

### 1. Accéder à vtysh

Une fois dans votre conteneur routeur, tapez simplement :

```bash
vtysh
```

Vous verrez un prompt comme :
```
router#
```

### 2. Entrer en mode configuration

Pour configurer, vous devez entrer en mode "configure terminal" :

```bash
configure terminal
```

Le prompt change en :
```
router(config)#
```

### 3. Sortir de vtysh

- `exit` : Sort du mode actuel (configuration → privilégié → utilisateur)
- `quit` ou `Ctrl+D` : Quitte complètement vtysh

## Commandes de base

### Voir l'aide
```bash
?
help
```

### Voir la configuration actuelle
```bash
show running-config
```

### Sauvegarder la configuration
```bash
write memory
# ou
write file
```

## Configuration des interfaces

### Configurer une adresse IP sur une interface

```bash
vtysh
configure terminal
interface eth0
  ip address 192.168.1.1/24
  no shutdown
exit
write memory
```

### Voir les interfaces
```bash
show interface
show ip interface brief
```

## Configuration BGP

### Exemple complet : Configurer BGP

```bash
vtysh
configure terminal

# Entrer dans la configuration BGP
router bgp 65000

  # Définir le router-id
  bgp router-id 1.1.1.1

  # Annoncer un réseau
  network 192.168.1.0/24

  # Ajouter un voisin BGP
  neighbor 192.168.2.1 remote-as 65001

  # Sortir de la configuration BGP
  exit

# Sauvegarder
write memory
exit
```

### Voir les informations BGP

```bash
# Voir les routes BGP
show ip bgp

# Voir les voisins BGP
show ip bgp neighbors

# Voir le résumé BGP
show ip bgp summary
```

## Configuration OSPF

### Exemple complet : Configurer OSPF

```bash
vtysh
configure terminal

# Entrer dans la configuration OSPF
router ospf

  # Définir le router-id
  ospf router-id 1.1.1.1

  # Configurer un réseau dans l'area 0
  network 192.168.1.0/24 area 0
  network 10.0.0.0/24 area 0

  # Sortir de la configuration OSPF
  exit

# Sauvegarder
write memory
exit
```

### Voir les informations OSPF

```bash
# Voir les voisins OSPF
show ip ospf neighbor

# Voir la base de données OSPF
show ip ospf database

# Voir les routes OSPF
show ip ospf route
```

## Configuration IS-IS

### Exemple complet : Configurer IS-IS

```bash
vtysh
configure terminal

# Entrer dans la configuration IS-IS
router isis

  # Définir le NET (Network Entity Title)
  net 49.0001.0000.0000.0001.00

  # Activer IS-IS sur une interface
  exit
interface eth0
  ip router isis
  isis circuit-type level-2-only
  exit

# Sauvegarder
write memory
exit
```

### Voir les informations IS-IS

```bash
# Voir les voisins IS-IS
show isis neighbor

# Voir la base de données IS-IS
show isis database
```

## Commandes utiles pour diagnostiquer

### Voir toutes les routes
```bash
show ip route
```

### Voir les routes d'un protocole spécifique
```bash
show ip route bgp      # Routes BGP
show ip route ospf     # Routes OSPF
show ip route isis     # Routes IS-IS
show ip route connected # Routes directement connectées
```

### Voir les processus actifs
```bash
show processes
```

### Voir les logs
```bash
# Dans le shell (pas dans vtysh)
tail -f /var/log/frr/bgpd.log
tail -f /var/log/frr/ospfd.log
tail -f /var/log/frr/zebra.log
```

## Exemples pratiques complets

### Exemple 1 : Routeur simple avec OSPF

```bash
# 1. Configurer l'interface
ip addr add 192.168.1.1/24 dev eth0
ip link set eth0 up

# 2. Configurer OSPF
vtysh
configure terminal
router ospf
  ospf router-id 192.168.1.1
  network 192.168.1.0/24 area 0
  exit
write memory
exit
```

### Exemple 2 : Routeur avec BGP et OSPF

```bash
vtysh
configure terminal

# Configuration OSPF pour le réseau interne
router ospf
  ospf router-id 1.1.1.1
  network 192.168.1.0/24 area 0
  exit

# Configuration BGP pour connexion externe
router bgp 65000
  bgp router-id 1.1.1.1
  network 192.168.1.0/24
  neighbor 10.0.0.2 remote-as 65001
  exit

write memory
exit
```

### Exemple 3 : Vérifier que tout fonctionne

```bash
vtysh

# Vérifier les interfaces
show ip interface brief

# Vérifier les routes
show ip route

# Vérifier les voisins OSPF
show ip ospf neighbor

# Vérifier les voisins BGP
show ip bgp neighbors

exit
```

## Astuces

### Mode non-interactif
Vous pouvez exécuter des commandes vtysh directement sans entrer en mode interactif :

```bash
vtysh -c "show ip route"
vtysh -c "configure terminal" -c "router bgp 65000" -c "bgp router-id 1.1.1.1" -c "end" -c "write memory"
```

### Annuler une configuration
```bash
# Dans le mode configuration
no router bgp 65000    # Supprime toute la configuration BGP
no network 192.168.1.0/24  # Supprime une route annoncée
```

### Voir l'historique des commandes
Utilisez les flèches ↑ et ↓ pour naviguer dans l'historique (comme dans bash).

## Dépannage

### Les services ne répondent pas
```bash
# Vérifier que les processus sont actifs
ps aux | grep frr

# Vérifier les logs
cat /var/log/frr/*.log
```

### Impossible de se connecter à vtysh
Assurez-vous que zebra est démarré :
```bash
ps aux | grep zebra
```

### Les routes ne s'affichent pas
```bash
# Vérifier que les protocoles sont activés
show ip protocols

# Vérifier les routes dans zebra
show ip route
```

## Raccourcis utiles

- `conf t` = `configure terminal`
- `end` = Sort du mode configuration (équivalent à plusieurs `exit`)
- `do` = Exécute une commande show depuis le mode configuration
  - Exemple : `do show ip route` (depuis le mode config)

## Structure des commandes

```
vtysh
  ├── Mode utilisateur (router#)
  │   ├── show ... (voir les informations)
  │   └── configure terminal
  │       └── Mode configuration (router(config)#)
  │           ├── router bgp/ospf/isis
  │           ├── interface ...
  │           └── ...
```

## Ressources

- Documentation FRRouting : https://docs.frrouting.org/
- Commandes vtysh : `vtysh` puis `?` ou `help`

---

## Cheat Sheet - Référence Rapide des Commandes

Cette section récapitule toutes les commandes essentielles pour configurer et dépanner les réseaux avec FRRouting, VXLAN, BGP EVPN et les protocoles de routage.

### 📋 Table des matières du Cheat Sheet

1. [Commandes système (ip, bridge)](#commandes-système)
2. [Commandes VXLAN](#commandes-vxlan)
3. [Commandes FRR (vtysh) - Configuration](#commandes-frr-configuration)
4. [Commandes FRR (vtysh) - Vérification](#commandes-frr-vérification)
5. [Commandes de test et diagnostic](#commandes-de-test)

---

### 1. Commandes système

#### Configuration des interfaces

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ip addr add X.X.X.X/Y dev INTERFACE` | Ajoute une adresse IP à une interface | `ip addr add 1.1.1.1/32 dev lo` |
| `ip link set INTERFACE up` | Active une interface | `ip link set eth0 up` |
| `ip addr show` | Affiche toutes les adresses IP | `ip addr show` |
| `ip -br addr show` | Affiche les adresses en format compact | `ip -br addr show` |

**Exemple d'utilisation :**
```bash
# Configurer le loopback
ip addr add 1.1.1.2/32 dev lo

# Configurer une interface physique
ip link set eth0 up
ip addr add 10.1.1.2/30 dev eth0

# Vérifier
ip -br addr show
```

#### Configuration du bridge

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ip link add br0 type bridge` | Crée un bridge | `ip link add br0 type bridge` |
| `ip link set br0 up` | Active le bridge | `ip link set br0 up` |
| `ip link set INTERFACE master br0` | Ajoute une interface au bridge | `ip link set eth1 master br0` |
| `bridge link show br0` | Affiche les interfaces du bridge | `bridge link show br0` |
| `bridge fdb show dev vxlan10` | Affiche la table FDB (MAC learning) | `bridge fdb show dev vxlan10` |
| `ip link set INTERFACE nomaster` | Retire une interface du bridge | `ip link set eth1 nomaster` |
| `ip link del br0` | Supprime le bridge | `ip link del br0` |

**Exemple complet :**
```bash
# Créer et activer le bridge
ip link add br0 type bridge
ip link set br0 up

# Ajouter les interfaces
ip link set eth1 master br0      # Interface vers host
ip link set vxlan10 master br0   # Interface VXLAN

# Vérifier
bridge link show br0
```

---

### 2. Commandes VXLAN

#### Création d'interface VXLAN

**Mode Statique (Unicast):**
```bash
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    dev eth0 \
    local <IP_LOCAL> \
    remote <IP_DISTANT>
```

**Mode Multicast (Dynamique):**
```bash
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    dev eth0 \
    local <IP_LOCAL> \
    group 239.1.1.1 \
    ttl 5
```

**Mode BGP EVPN (sans apprentissage MAC local):**
```bash
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.2 \
    nolearning

ip link set vxlan10 up
```

#### Gestion VXLAN

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ip link set vxlan10 up` | Active l'interface VXLAN | `ip link set vxlan10 up` |
| `ip -d link show vxlan10` | Affiche les détails VXLAN | `ip -d link show vxlan10` |
| `ip link del vxlan10` | Supprime l'interface VXLAN | `ip link del vxlan10` |

**Paramètres expliqués :**
- `id 10` : VNI (VXLAN Network Identifier)
- `dstport 4789` : Port UDP standard VXLAN
- `local 1.1.1.2` : Adresse source (loopback du VTEP)
- `remote 30.1.1.2` : Adresse IP du VTEP distant (mode point-à-point)
- `group 239.1.1.1` : Groupe multicast (mode dynamique)
- `nolearning` : Désactive l'apprentissage MAC local (BGP EVPN gère ça)

---

### 3. Commandes FRR - Configuration

#### Entrer dans vtysh

```bash
vtysh                    # Entre dans le shell FRR
configure terminal       # Passe en mode configuration
```

#### Configuration OSPF

| Commande | Description | Exemple |
|----------|-------------|---------|
| `router ospf` | Entre dans la config OSPF | `router ospf` |
| `ospf router-id X.X.X.X` | Définit le Router ID | `ospf router-id 1.1.1.1` |
| `network X.X.X.X/Y area Z` | Annonce un réseau dans OSPF | `network 1.1.1.2/32 area 0` |
| `exit` | Sort de la config OSPF | `exit` |

**Exemple complet OSPF :**
```bash
vtysh
configure terminal
router ospf
 ospf router-id 1.1.1.2
 network 1.1.1.2/32 area 0        # Loopback
 network 10.1.1.0/30 area 0      # Réseau vers RR
exit
write memory
```

#### Configuration BGP de base

| Commande | Description | Exemple |
|----------|-------------|---------|
| `router bgp AS_NUMBER` | Active BGP avec AS number | `router bgp 1` |
| `bgp router-id X.X.X.X` | Définit le Router ID BGP | `bgp router-id 1.1.1.2` |
| `no bgp ebgp-requires-policy` | Simplifie la config (lab) | `no bgp ebgp-requires-policy` |
| `neighbor X.X.X.X remote-as Y` | Déclare un voisin BGP | `neighbor 1.1.1.1 remote-as 1` |
| `neighbor X.X.X.X update-source lo` | Utilise loopback comme source | `neighbor 1.1.1.1 update-source lo` |
| `neighbor NAME peer-group` | Crée un peer-group | `neighbor ibgp-clients peer-group` |
| `neighbor X.X.X.X peer-group GROUP` | Assigne un voisin à un groupe | `neighbor 1.1.1.2 peer-group ibgp-clients` |

**Exemple BGP de base (sur un Leaf) :**
```bash
router bgp 1
 bgp router-id 1.1.1.2
 no bgp ebgp-requires-policy
 neighbor 1.1.1.1 remote-as 1
 neighbor 1.1.1.1 update-source lo
```

**Exemple BGP avec peer-group (sur le RR) :**
```bash
router bgp 1
 bgp router-id 1.1.1.1
 no bgp ebgp-requires-policy
 
 # Créer le peer-group
 neighbor ibgp-clients peer-group
 neighbor ibgp-clients remote-as 1
 neighbor ibgp-clients update-source lo
 
 # Assigner les voisins au groupe
 neighbor 1.1.1.2 peer-group ibgp-clients
 neighbor 1.1.1.3 peer-group ibgp-clients
 neighbor 1.1.1.4 peer-group ibgp-clients
```

**💡 Explication du peer-group :**
- Le peer-group permet de regrouper plusieurs voisins avec les mêmes paramètres
- Au lieu de répéter `remote-as 1` et `update-source lo` pour chaque voisin, on les configure une fois dans le groupe
- Tous les voisins assignés au groupe héritent automatiquement de ces paramètres
- Avantage : maintenance plus facile (un seul changement s'applique à tous)

#### Configuration BGP EVPN

| Commande | Description | Exemple |
|----------|-------------|---------|
| `address-family l2vpn evpn` | Entre dans la config EVPN | `address-family l2vpn evpn` |
| `neighbor X.X.X.X activate` | Active EVPN pour ce voisin | `neighbor 1.1.1.1 activate` |
| `neighbor X.X.X.X route-reflector-client` | Configure comme client RR | `neighbor ibgp-clients route-reflector-client` |
| `advertise-all-vni` | Annonce tous les VNIs locaux | `advertise-all-vni` |
| `exit-address-family` | Sort de la config EVPN | `exit-address-family` |

**Exemple BGP EVPN (sur un Leaf) :**
```bash
address-family l2vpn evpn
 neighbor 1.1.1.1 activate
 advertise-all-vni
exit-address-family
```

**Exemple BGP EVPN (sur le RR) :**
```bash
# Créer un peer-group
neighbor ibgp-clients peer-group
neighbor ibgp-clients remote-as 1
neighbor ibgp-clients update-source lo

# Ajouter les Leafs au groupe
neighbor 1.1.1.2 peer-group ibgp-clients
neighbor 1.1.1.3 peer-group ibgp-clients
neighbor 1.1.1.4 peer-group ibgp-clients

# Configurer EVPN
address-family l2vpn evpn
 neighbor ibgp-clients activate
 neighbor ibgp-clients route-reflector-client
exit-address-family
```

#### Configuration IS-IS

| Commande | Description | Exemple |
|----------|-------------|---------|
| `router isis` | Entre dans la config IS-IS | `router isis` |
| `net NET_ADDRESS` | Définit le NET (Network Entity Title) | `net 49.0001.0000.0000.0001.00` |
| `ip router isis` | Active IS-IS sur une interface | (dans `interface eth0`) |
| `isis circuit-type level-2-only` | Configure le type de circuit | (dans `interface eth0`) |

#### Sauvegarder et quitter

| Commande | Description |
|----------|-------------|
| `end` | Sort du mode configuration |
| `write memory` | Sauvegarde la configuration dans `/etc/frr/frr.conf` |
| `write file` | Sauvegarde dans un fichier spécifique |

---

### 4. Commandes FRR - Vérification

#### Commandes OSPF

| Commande | Description | Ce qu'elle affiche |
|----------|-------------|-------------------|
| `show ip ospf neighbor` | Liste les voisins OSPF | État des adjacences OSPF |
| `show ip ospf database` | Base de données OSPF | LSAs OSPF |
| `show ip route ospf` | Routes apprises via OSPF | Routes avec préfixe "O" |
| `show ip route` | Table de routage complète | Toutes les routes (C, O, B, etc.) |

**Exemple de sortie :**
```bash
vtysh -c "show ip ospf neighbor"
# Affiche:
# Neighbor ID     Pri   State      Dead Time   Interface
# 1.1.1.1         1     Full/DR    00:00:35    eth0

vtysh -c "show ip route ospf"
# Affiche:
# O   1.1.1.1/32 [110/20] via 10.1.1.1, eth0
# O   1.1.1.3/32 [110/20] via 10.1.1.1, eth0
```

#### Commandes BGP

| Commande | Description | Ce qu'elle affiche |
|----------|-------------|-------------------|
| `show ip bgp` | Routes BGP IPv4 | Table de routage BGP |
| `show ip bgp neighbors` | Détails des voisins BGP | État et statistiques des sessions |
| `show ip bgp summary` | État des sessions BGP | Sessions BGP (IPv4 unicast) |
| `show bgp l2vpn evpn summary` | Résumé EVPN | Sessions BGP EVPN avec compteurs |
| `show bgp l2vpn evpn` | Routes EVPN détaillées | Routes Type 2, Type 3, etc. |
| `show running-config` | Configuration actuelle | Toute la config FRR |

**Exemple de sortie :**
```bash
vtysh -c "show bgp summary"
# Affiche:
# Neighbor   V  AS   MsgRcvd  MsgSent  State/PfxRcd
# 1.1.1.1    4  1    15       15       0

vtysh -c "show bgp l2vpn evpn"
# Affiche:
# Route Distinguisher: 1.1.1.2:2
# *> [3]:[0]:[32]:[1.1.1.2]
#       1.1.1.2                        32768 i
# *>i[2]:[0]:[48]:[62:b7:1f:a6:5a:34]
#       1.1.1.2                    0    100      0 i
```

**Codes de statut dans les routes EVPN :**
- `*` = Route valide
- `>` = Route sélectionnée (best path)
- `i` = Route interne (iBGP)
- `[2]` = Type 2 (MAC/IP)
- `[3]` = Type 3 (IMET)

#### Commandes IS-IS

| Commande | Description | Ce qu'elle affiche |
|----------|-------------|-------------------|
| `show isis neighbor` | Liste les voisins IS-IS | État des adjacences IS-IS |
| `show isis database` | Base de données IS-IS | LSPs IS-IS |

#### Commandes générales

| Commande | Description |
|----------|-------------|
| `show ip interface brief` | Liste toutes les interfaces avec leurs adresses IP |
| `show ip route` | Table de routage complète |
| `show ip route bgp` | Routes BGP uniquement |
| `show ip route ospf` | Routes OSPF uniquement |
| `show ip route isis` | Routes IS-IS uniquement |
| `show ip route connected` | Routes directement connectées |
| `show ip protocols` | Protocoles de routage actifs |
| `show processes` | Processus FRR actifs |

---

### 5. Commandes de test et diagnostic

#### Tests de connectivité

| Commande | Description | Usage |
|----------|-------------|-------|
| `ping X.X.X.X` | Test de connectivité IP | `ping 1.1.1.1` (vers loopback) |
| `ping -c 4 X.X.X.X` | Ping avec 4 paquets | `ping -c 4 20.1.1.2` |
| `traceroute X.X.X.X` | Trace le chemin réseau | `traceroute 20.1.1.3` |

**Exemple :**
```bash
# Depuis un host
ping 20.1.1.2        # Vers un autre host
ping -c 4 20.1.1.3   # 4 pings vers un autre host

# Depuis un routeur
ping 1.1.1.1         # Vers le RR
ping 1.1.1.3         # Vers un autre Leaf
```

#### Capture de trafic

| Commande | Description | Usage |
|----------|-------------|-------|
| `tcpdump -i INTERFACE port 4789` | Capture trafic VXLAN | `tcpdump -i eth0 port 4789` |
| `tcpdump -i INTERFACE host X.X.X.X` | Capture trafic vers/ depuis IP | `tcpdump -i eth0 host 1.1.1.2` |
| `tcpdump -i INTERFACE -vv` | Mode verbeux | `tcpdump -i eth0 port 4789 -vv` |

**Exemple :**
```bash
# Capturer le trafic VXLAN
tcpdump -i eth0 port 4789 -vv

# Capturer le trafic vers un VTEP spécifique
tcpdump -i eth0 host 1.1.1.4 -vv
```

#### Vérification des interfaces et bridges

| Commande | Description | Usage |
|----------|-------------|-------|
| `ip link show` | Liste toutes les interfaces | `ip link show` |
| `ip -d link show vxlan10` | Détails de l'interface VXLAN | `ip -d link show vxlan10` |
| `bridge link show br0` | Interfaces dans le bridge | `bridge link show br0` |
| `bridge fdb show dev vxlan10` | Table FDB (MAC learning) | `bridge fdb show dev vxlan10` |

**Exemple :**
```bash
# Voir toutes les interfaces
ip link show

# Voir les détails VXLAN
ip -d link show vxlan10 | grep -E "vni|local|group"

# Voir les MACs apprises
bridge fdb show dev vxlan10
```

#### Vérification des logs

```bash
# Dans le shell (pas dans vtysh)
tail -f /var/log/frr/bgpd.log
tail -f /var/log/frr/ospfd.log
tail -f /var/log/frr/zebra.log
cat /var/log/frr/*.log
```

#### Vérification des processus

```bash
# Vérifier que les processus sont actifs
ps aux | grep frr
ps aux | grep zebra
```

---

**💡 Astuce :** Utilisez `vtysh -c "COMMANDE"` pour exécuter une commande FRR directement depuis le shell Linux, sans entrer dans vtysh interactif.

