# Guide Complet VXLAN - P2

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
   - [Topologie du réseau](#topologie-du-réseau)
   - [Spécifications techniques](#spécifications-techniques)
   - [Plan d'adressage](#plan-dadressage)
2. [Pré-requis et préparation](#pré-requis-et-préparation)
   - [Images Docker](#1-images-docker)
3. [Configuration](#étape-3-configuration)
   - [Option A: Configuration automatique (scripts)](#option-a-configuration-automatique-scripts)
   - [Option B: Configuration manuelle](#option-b-configuration-manuelle)
     - [Configuration de routeur_wil-1](#1-configuration-de-routeur_wil-1)
       - [Mode Statique (Unicast)](#mode-statique-unicast)
       - [Mode Multicast (Dynamique)](#mode-multicast-dynamique)
     - [Configuration de routeur_wil-2](#2-configuration-de-routeur_wil-2)
       - [Mode Statique (Unicast)](#mode-statique-unicast-1)
       - [Mode Multicast (Dynamique)](#mode-multicast-dynamique-1)
     - [Configuration de host_wil-1](#3-configuration-de-host_wil-1)
     - [Configuration de host_wil-2](#4-configuration-de-host_wil-2)
5. [Tests et vérification](#tests-et-vérification)
   - [Vérification de la configuration VXLAN](#1-vérification-de-la-configuration-vxlan)
   - [Tests de connectivité](#2-tests-de-connectivité)
   - [Capture de trafic VXLAN](#3-capture-de-trafic-vxlan)
   - [Passage en mode multicast](#passage-en-mode-multicast)

---

## Vue d'ensemble

Ce projet implémente un réseau VXLAN (Virtual eXtensible Local Area Network) selon la RFC 7348, permettant de créer un réseau de couche 2 étendu sur une infrastructure de couche 3. Le VXLAN encapsule les trames Ethernet dans des paquets UDP.

### Topologie du réseau

```
                    VXLAN (ID: 10)
                         
    host_wil-1  ←→  routeur_wil-1  ←→  Switch_wil  ←→  routeur_wil-2  ←→  host_wil-2
    (10.1.1.1)      (30.1.1.1/eth0)    (e0/e1)      (30.1.1.2/eth0)    (10.1.1.2)
                         ↓                                    ↓
                      (br0) ←------ VXLAN Tunnel -------→  (br0)
                    (vxlan10)                             (vxlan10)
```

### Spécifications techniques

| Paramètre | Valeur |
|-----------|--------|
| **VXLAN ID** | 10 |
| **Interface VXLAN** | vxlan10 |
| **Bridge** | br0 |
| **Port UDP** | 4789 (standard) |
| **Groupe Multicast** | 239.1.1.1 (mode dynamique) |
| **Réseau de transport** | 30.1.1.0/24 |
| **Réseau VXLAN** | 10.1.1.0/24 |

### Plan d'adressage

**Réseau de transport (L3) - 30.1.1.0/24:**
- routeur_wil-1 eth0: `30.1.1.1/24`
- routeur_wil-2 eth0: `30.1.1.2/24`

**Réseau VXLAN (L2 étendu) - 10.1.1.0/24:**
- host_wil-1 eth0: `10.1.1.1/24`
- host_wil-2 eth0: `10.1.1.2/24`

---

## Pré-requis et préparation

### 1. Images Docker

Depuis le répertoire P1/, construire les images:

```bash
cd ../P1
docker build -t onyx/p1router:latest -f Dockerfile.router .
docker build -t onyx/p1basic:latest -f Dockerfile.basic .
```

**Images créées:**
- `onyx/p1router:latest` → pour les routeurs VXLAN
- `onyx/p1basic:latest` → pour les hosts et switch


### Étape 3: Configuration



#### Option A: Configuration automatique (scripts)

**1. Copier les scripts dans chaque container:**

```bash
# Depuis votre machine hôte
docker cp P2/config-router-1.sh <container_id>:/tmp/
docker cp P2/config-router-2.sh <container_id>:/tmp/
docker cp P2/config-host-1.sh <container_id>:/tmp/
docker cp P2/config-host-2.sh <container_id>:/tmp/
docker cp P2/config-switch.sh <container_id>:/tmp/
```

**2. Exécuter les scripts:**

```bash
# Sur routeur_wil-1
chmod +x /tmp/config-router-1.sh
/tmp/config-router-1.sh static    # ou multicast

# Sur routeur_wil-2
chmod +x /tmp/config-router-2.sh
/tmp/config-router-2.sh static    # ou multicast

# Sur host_wil-1
chmod +x /tmp/config-host-1.sh
/tmp/config-host-1.sh

# Sur host_wil-2
chmod +x /tmp/config-host-2.sh
/tmp/config-host-2.sh

# Sur Switch_wil
chmod +x /tmp/config-switch.sh
/tmp/config-switch.sh
```

#### Option B: Configuration manuelle

##### 1. Configuration de routeur_wil-1

**Image Docker:** `onyx/p1router:latest`

###### Mode Statique (Unicast)

```bash
#!/bin/bash
# Configuration des interfaces
# eth0 : interface externe vers le switch (réseau de transport 30.1.1.0/24)
# eth1 : interface interne vers host_wil-1 (port bridge L2 uniquement)

# Configuration de l'interface externe
ip link set eth0 up
ip addr add 30.1.1.1/24 dev eth0

# Configuration de l'interface interne (pas d'IP nécessaire, fonctionne en L2)
ip link set eth1 up

# ===================================
# CONFIGURATION VXLAN MODE STATIQUE
# ===================================

# Création de l'interface VXLAN
# - id 10 : identifiant VXLAN (VNI)
# - dstport 4789 : port UDP VXLAN standard (RFC 7348)
# - dev eth0 : interface physique sous-jacente pour le transport
# - local 30.1.1.1 : adresse IP source pour l'encapsulation
# - remote 30.1.1.2 : adresse IP du VTEP distant (mode point-à-point)
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    dev eth0 \
    local 30.1.1.1 \
    remote 30.1.1.2

# Activation de l'interface VXLAN
ip link set vxlan10 up

# Création du bridge br0
# Le bridge connecte l'interface locale (eth1) avec le tunnel VXLAN (vxlan10)
# Permet la commutation L2 entre le réseau local et le réseau distant
ip link add br0 type bridge
ip link set br0 up

# Ajout des interfaces au bridge
# eth1 : connexion vers host_wil-1 (trafic local)
# vxlan10 : tunnel VXLAN vers routeur_wil-2 (trafic distant)
ip link set eth1 master br0
ip link set vxlan10 master br0

# Note: Le bridge br0 n'a pas besoin d'adresse IP
# Il fonctionne en couche 2 uniquement pour la commutation
```

###### Mode Multicast (Dynamique)

```bash
#!/bin/bash
# Configuration des interfaces
ip link set eth0 up
ip addr add 30.1.1.1/24 dev eth0

# eth1 fonctionne en couche 2 uniquement (port du bridge)
ip link set eth1 up

# ===================================
# CONFIGURATION VXLAN MODE MULTICAST
# ===================================

# Création de l'interface VXLAN avec multicast
# - group 239.1.1.1 : adresse de groupe multicast
#   Tous les VTEPs (VXLAN Tunnel Endpoints) rejoignent ce groupe
#   pour découvrir automatiquement les autres membres
# - ttl 5 : Time To Live pour limiter la portée du multicast
# 
# Avantages:
# - Découverte automatique des VTEPs
# - Pas besoin de configurer manuellement chaque pair
# - Scale mieux avec plusieurs membres
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    dev eth0 \
    local 30.1.1.1 \
    group 239.1.1.1 \
    ttl 5

# Activation de l'interface VXLAN
ip link set vxlan10 up

# Création du bridge
ip link add br0 type bridge
ip link set br0 up

# Ajout des interfaces au bridge
ip link set eth1 master br0
ip link set vxlan10 master br0
```


##### 2. Configuration de routeur_wil-2

**Image Docker:** `onyx/p1router:latest`

###### Mode Statique (Unicast)

```bash
#!/bin/bash
# Configuration des interfaces
ip link set eth0 up
ip addr add 30.1.1.2/24 dev eth0

# eth1 fonctionne en couche 2 uniquement (port du bridge)
ip link set eth1 up

# ===================================
# CONFIGURATION VXLAN MODE STATIQUE
# ===================================

# Création de l'interface VXLAN
# Configuration similaire à routeur_wil-1 mais inversée:
# - local 30.1.1.2 : adresse IP locale (inversée)
# - remote 30.1.1.1 : adresse IP du VTEP distant (inversée)
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    dev eth0 \
    local 30.1.1.2 \
    remote 30.1.1.1

ip link set vxlan10 up

# Création du bridge
ip link add br0 type bridge
ip link set br0 up

# Ajout des interfaces au bridge
ip link set eth1 master br0
ip link set vxlan10 master br0
```

###### Mode Multicast (Dynamique)

```bash
#!/bin/bash
# Configuration des interfaces
ip link set eth0 up
ip addr add 30.1.1.2/24 dev eth0

# eth1 fonctionne en L2 uniquement (pas d'IP nécessaire)
ip link set eth1 up

# ===================================
# CONFIGURATION VXLAN MODE MULTICAST
# ===================================

# Création de l'interface VXLAN avec le même groupe multicast
# Tous les routeurs VXLAN utilisent le même groupe (239.1.1.1)
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    dev eth0 \
    local 30.1.1.2 \
    group 239.1.1.1 \
    ttl 5

ip link set vxlan10 up

# Création du bridge
ip link add br0 type bridge
ip link set br0 up

# Ajout des interfaces au bridge
ip link set eth1 master br0
ip link set vxlan10 master br0
```

---

##### 3. Configuration de host_wil-1

**Image Docker:** `onyx/p1basic:latest`

```bash
#!/bin/bash
# Fichier: config-host-1.sh

# Configuration de l'interface
ip link set eth0 up
ip addr add 10.1.1.1/24 dev eth0

# Pas de configuration VXLAN nécessaire sur les hosts
# Ils communiquent simplement via le bridge du routeur

echo "Configuration de host_wil-1 terminée"
echo "Adresse IP: 10.1.1.1/24"
```

---

##### 4. Configuration de host_wil-2

**Image Docker:** `onyx/p1basic:latest`

```bash
#!/bin/bash
# Fichier: config-host-2.sh

# Configuration de l'interface
ip link set eth0 up
ip addr add 10.1.1.2/24 dev eth0

echo "Configuration de host_wil-2 terminée"
echo "Adresse IP: 10.1.1.2/24"
```

---

## Tests et vérification

### 1. Vérification de la configuration VXLAN

#### Sur routeur_wil-1

```bash
# Vérifier la configuration détaillée de l'interface VXLAN
ip -d link show vxlan10

```

```bash
# Vérifier les interfaces du bridge
bridge link show br0
```

```bash
# Vérifier la table FDB (Forwarding Database)
bridge fdb show dev vxlan10
```

```bash
# Vérifier le groupe multicast (mode multicast uniquement)
ip maddr show dev eth0

```

```bash
# Statistiques VXLAN
ip -s link show vxlan10

# Affiche les paquets RX (reçus/décapsulés) et TX (transmis/encapsulés)
```

#### Sur routeur_wil-2

Même commandes que sur routeur_wil-1.

### 2. Tests de connectivité

```bash
# Depuis host_wil-1
ping 10.1.1.2 -c 4

# Flux du paquet:
# 1. Ping part de host_wil-1 (10.1.1.1)
# 2. Arrive sur routeur_wil-1 via eth1
# 3. Bridge br0 forward vers vxlan10
# 4. VXLAN encapsule dans UDP (30.1.1.1 → 30.1.1.2:4789)
# 5. Paquet traverse le réseau physique via Switch_wil
# 6. VXLAN décapsule sur routeur_wil-2
# 7. Bridge br0 forward vers eth1
# 8. Ping arrive sur host_wil-2 (10.1.1.2)
```

```bash
# Test avec traceroute
traceroute 10.1.1.2

# Afficher la table ARP
arp -n

# Sur les routeurs, surveiller l'apprentissage MAC en temps réel
watch -n 1 'bridge fdb show dev vxlan10'
```

### 3. Capture de trafic VXLAN



**Filtres Wireshark utiles:**
```
udp.port == 4789                     # Tout le trafic VXLAN
vxlan.vni == 10                      # VXLAN avec VNI 10 spécifique
ip.src == 30.1.1.1                   # Paquets depuis routeur_wil-1
vxlan && icmp                        # Pings encapsulés dans VXLAN
```


#### Passage en mode multicast

**Sur routeur_wil-1:**
```bash
# Supprimer l'ancienne configuration
ip link del vxlan10
ip link del br0

# Reconfigurer en multicast
/tmp/config-router-1.sh multicast
```

**Sur routeur_wil-2:**
```bash
# Supprimer l'ancienne configuration
ip link del vxlan10
ip link del br0

# Reconfigurer en multicast
/tmp/config-router-2.sh multicast
```

**Vérification du mode multicast:**
```bash
# Vérifier le groupe multicast
ip maddr show dev eth0

# Vérifier la config VXLAN
ip -d link show vxlan10 | grep group

# Sortie attendue: group 239.1.1.1
```

---

