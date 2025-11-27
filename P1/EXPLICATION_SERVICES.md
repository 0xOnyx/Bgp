# Explication des Services de Routage - Actif et Configuré

## Qu'est-ce que "Actif et Configuré" ?

Un service de routage **"actif et configuré"** signifie que :

1. **Actif** : Le processus (daemon) est en cours d'exécution sur le routeur
2. **Configuré** : Le service a une configuration valide et peut échanger des informations de routage

---

## 1. BGPD - Service BGP Actif et Configuré

### Qu'est-ce que BGPD ?

**BGPD** (BGP Daemon) est le processus qui exécute le protocole BGP (Border Gateway Protocol) sur votre routeur.

### Que signifie "Actif et Configuré" pour BGPD ?

#### ✅ **Actif** signifie :
- Le processus `bgpd` est démarré et fonctionne
- Il écoute sur le port 2604 (port par défaut de BGP)
- Il peut recevoir et envoyer des messages BGP

#### ✅ **Configuré** signifie :
- Le fichier `/etc/frr/bgpd.conf` contient une configuration valide
- Au minimum :
  - Un AS (Autonomous System) est défini
  - Un router-id est configuré
  - Des réseaux à annoncer sont définis (optionnel)
  - Des voisins BGP sont configurés (optionnel)

### Exemple de configuration BGPD minimale

```bash
# Fichier /etc/frr/bgpd.conf
hostname bgpd
password bgpd
enable password bgpd
log file /var/log/frr/bgpd.log

# Configuration BGP
router bgp 65000
  bgp router-id 1.1.1.1
  network 192.168.1.0/24
```

### Comment vérifier que BGPD est actif et configuré ?

```bash
# 1. Vérifier que le processus est actif
ps aux | grep bgpd
# Devrait afficher : /usr/lib/frr/bgpd -d -A 127.0.0.1 ...

# 2. Vérifier la configuration via vtysh
vtysh
show ip bgp summary
show ip bgp neighbors
exit

# 3. Vérifier les logs
tail -f /var/log/frr/bgpd.log
```

### À quoi sert BGPD quand il est actif ?

- **Échange de routes** : Partage des informations de routage avec d'autres routeurs BGP
- **Sélection de chemins** : Choisit le meilleur chemin vers une destination
- **Gestion des politiques** : Applique des règles de routage (filtres, préférences)
- **Routage inter-AS** : Connecte différents réseaux autonomes

---

## 2. OSPFD - Service OSPF Actif et Configuré

### Qu'est-ce que OSPFD ?

**OSPFD** (OSPF Daemon) est le processus qui exécute le protocole OSPF (Open Shortest Path First) sur votre routeur.

### Que signifie "Actif et Configuré" pour OSPFD ?

#### ✅ **Actif** signifie :
- Le processus `ospfd` est démarré et fonctionne
- Il écoute sur le port 2606 (port par défaut d'OSPF)
- Il peut envoyer et recevoir des paquets OSPF (Hello, LSA, etc.)

#### ✅ **Configuré** signifie :
- Le fichier `/etc/frr/ospfd.conf` contient une configuration valide
- Au minimum :
  - Un router-id OSPF est défini
  - Des réseaux sont configurés dans des areas OSPF
  - Les interfaces réseau sont activées pour OSPF

### Exemple de configuration OSPFD minimale

```bash
# Fichier /etc/frr/ospfd.conf
hostname ospfd
password ospfd
enable password ospfd
log file /var/log/frr/ospfd.log

# Configuration OSPF
router ospf
  ospf router-id 1.1.1.1
  network 192.168.1.0/24 area 0
  network 10.0.0.0/24 area 0
```

### Comment vérifier que OSPFD est actif et configuré ?

```bash
# 1. Vérifier que le processus est actif
ps aux | grep ospfd
# Devrait afficher : /usr/lib/frr/ospfd -d -A 127.0.0.1 ...

# 2. Vérifier la configuration via vtysh
vtysh
show ip ospf neighbor
show ip ospf database
show ip ospf route
exit

# 3. Vérifier les logs
tail -f /var/log/frr/ospfd.log
```

### À quoi sert OSPFD quand il est actif ?

- **Découverte de voisins** : Trouve automatiquement les autres routeurs OSPF sur le réseau
- **Calcul du chemin le plus court** : Utilise l'algorithme de Dijkstra pour trouver les meilleurs chemins
- **Convergence rapide** : S'adapte rapidement aux changements de topologie (pannes, nouveaux liens)
- **Routage intra-AS** : Gère le routage à l'intérieur d'un même réseau/entreprise

---

## 3. IS-IS - Service de Routage IS-IS

### Qu'est-ce que IS-IS ?

**IS-IS** (Intermediate System to Intermediate System) est un protocole de routage à état de liens, similaire à OSPF mais basé sur le modèle OSI plutôt que TCP/IP.

### Qu'est-ce qu'un "Service de Routage IS-IS" ?

Un service de routage IS-IS est le processus (daemon) qui exécute le protocole IS-IS sur votre routeur. Dans FRRouting, c'est le processus **`isisd`**.

### Caractéristiques d'IS-IS

#### ✅ **Actif** signifie :
- Le processus `isisd` est démarré et fonctionne
- Il écoute sur le port 2608 (port par défaut d'IS-IS)
- Il peut envoyer et recevoir des PDU IS-IS (Protocol Data Units)

#### ✅ **Configuré** signifie :
- Le fichier `/etc/frr/isisd.conf` contient une configuration valide
- Au minimum :
  - Un NET (Network Entity Title) est défini
  - Des interfaces sont configurées pour IS-IS
  - Le niveau IS-IS est défini (Level-1, Level-2, ou les deux)

### Exemple de configuration IS-IS minimale

```bash
# Fichier /etc/frr/isisd.conf
hostname isisd
password isisd
enable password isisd
log file /var/log/frr/isisd.log

# Configuration IS-IS
router isis
  net 49.0001.0000.0000.0001.00
  is-type level-2-only
```

### Configuration d'une interface pour IS-IS

```bash
vtysh
configure terminal
interface eth0
  ip router isis
  isis circuit-type level-2-only
  exit
write memory
exit
```

### Comment vérifier que IS-IS est actif et configuré ?

```bash
# 1. Vérifier que le processus est actif
ps aux | grep isisd
# Devrait afficher : /usr/lib/frr/isisd -d -A 127.0.0.1 ...

# 2. Vérifier la configuration via vtysh
vtysh
show isis neighbor
show isis database
show isis route
exit

# 3. Vérifier les logs
tail -f /var/log/frr/isisd.log
```

### À quoi sert IS-IS quand il est actif ?

- **Routage à état de liens** : Chaque routeur connaît la topologie complète du réseau
- **Scalabilité** : Très efficace pour les grands réseaux d'opérateurs
- **Support MPLS** : Souvent utilisé avec MPLS dans les réseaux d'opérateurs
- **Routage hiérarchique** : Utilise des niveaux (Level-1 et Level-2) pour la hiérarchie

### Différences entre OSPF et IS-IS

| Caractéristique | OSPF | IS-IS |
|----------------|------|-------|
| **Modèle** | TCP/IP | OSI |
| **Areas** | Oui (areas OSPF) | Oui (Level-1/Level-2) |
| **Utilisation** | Réseaux d'entreprise | Grands opérateurs, MPLS |
| **Complexité** | Moyenne | Élevée |
| **Configuration** | Plus courante | Moins courante |

---

## Comparaison des Trois Services

### Tableau récapitulatif

| Service | Port | Usage Principal | Quand l'utiliser |
|---------|------|-----------------|------------------|
| **BGPD** | 2604 | Routage inter-AS | Connexions Internet, multi-sites |
| **OSPFD** | 2606 | Routage intra-AS | Réseaux d'entreprise |
| **ISISD** | 2608 | Routage intra-AS | Grands opérateurs, MPLS |

### Vérification globale des services

```bash
# Vérifier tous les processus FRR
ps aux | grep frr

# Devrait afficher :
# - zebra (gestionnaire)
# - bgpd (si actif)
# - ospfd (si actif)
# - isisd (si actif)

# Vérifier via vtysh
vtysh
show ip protocols    # Affiche tous les protocoles actifs
show running-config  # Affiche toute la configuration
exit
```
