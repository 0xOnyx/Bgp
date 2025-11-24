# P1 - Configuration GNS3 avec Docker et Quagga

Ce projet contient deux images Docker simples pour GNS3 :
- **Image basique** : Alpine + busybox
- **Image routeur** : Ubuntu + Quagga (BGPD, OSPFD, IS-IS)

## Structure du projet

```
P1/
├── Dockerfile.basic          # Image Docker basique (Alpine + busybox)
├── Dockerfile.router         # Image Docker routeur (Ubuntu + quagga)
├── GUIDE_PROTOCOLES.md         # Guide complet des protocoles (BGP, OSPF, IS-IS)
├── config/                   # Fichiers de configuration exemple
│   ├── zebra.conf.example
│   ├── bgpd.conf.example
│   ├── ospfd.conf.example
│   └── isisd.conf.example
└── README.md                 # Ce fichier
```

## Prérequis

- Docker installé et configuré
- GNS3 installé et configuré
- Accès à internet pour télécharger les images de base

## Installation rapide

### Construction des images

```bash
cd P1

# Image basique
docker build -f Dockerfile.basic -t votre_login-basic:latest .

# Image routeur
docker build -f Dockerfile.router -t votre_login-router:latest .
```


docker tag local-image-name jeremyds/my-app:v1
docker push jeremyds/my-app:latest



### Configuration dans GNS3

1. Ouvrir GNS3 → `Edit > Preferences > Docker`
2. Ajouter les images: `votre_login-basic` et `votre_login-router`
3. Créer votre topologie avec ces images

## Images Docker

### Image basique (`votre_login-basic`)

- **Base**: Alpine Linux
- **Contenu**:
  - busybox
  - iproute2
  - iputils
  - tcpdump
  - net-tools
  - bash

Cette image est utilisée pour les équipements réseau simples qui n'ont pas besoin de services de routage avancés.

### Image routeur (`votre_login-router`)

- **Base**: Ubuntu 22.04
- **Contenu**:
  - quagga (zebra, bgpd, ospfd, isisd)
  - busybox
  - Outils réseau (iproute2, iputils-ping)

Cette image contient tous les services de routage demandés:
- **Zebra**: Service de routage de base
- **BGPD**: Protocole BGP (Border Gateway Protocol)
- **OSPFD**: Protocole OSPF (Open Shortest Path First)
- **ISISD**: Protocole IS-IS (Intermediate System to Intermediate System)

## Utilisation simple

### Configuration d'un routeur

```bash
# 1. Configurer l'interface réseau
ip addr add 192.168.1.1/24 dev eth0
ip link set eth0 up

# 2. Configurer Quagga
vtysh
configure terminal
router bgp 65000
  bgp router-id 1.1.1.1
  network 192.168.1.0/24
  exit
write memory
exit
```


### Fichiers de configuration

Les fichiers de configuration se trouvent dans `/etc/quagga/`:
- `zebra.conf`: Configuration du service de routage de base
- `bgpd.conf`: Configuration BGP
- `ospfd.conf`: Configuration OSPF
- `isisd.conf`: Configuration IS-IS

Des exemples commentés sont disponibles dans le dossier `config/`.

## Utilisation dans GNS3

### Création d'un projet

1. Créer un nouveau projet dans GNS3
2. Ajouter des équipements depuis la barre d'outils:
   - Utiliser `votre_login-basic` pour les machines simples
   - Utiliser `votre_login-router` pour les routeurs
3. Connecter les équipements avec des câbles
4. Démarrer tous les équipements

### Configuration des interfaces

Les interfaces réseau sont configurées dynamiquement par GNS3. Aucune adresse IP n'est configurée par défaut.

Pour configurer une interface:

```bash
# Dans le conteneur
ip addr add 192.168.1.1/24 dev eth0
ip link set eth0 up

# Ou via vtysh pour les routeurs
vtysh
configure terminal
interface eth0
  ip address 192.168.1.1/24
```

### Connexion aux conteneurs

Dans GNS3, vous pouvez:
- Cliquer sur un équipement pour ouvrir une console
- Utiliser `docker exec` depuis le terminal:
  ```bash
  docker exec -it <container_name> /bin/bash
  ```

## Export du projet GNS3

### Sauvegarder les images Docker

```bash
# Sauvegarder l'image basique
docker save votre_login-basic:latest -o votre_login-basic.tar

# Sauvegarder l'image routeur
docker save votre_login-router:latest -o votre_login-router.tar
```

### Créer l'archive ZIP

```bash
# Créer un dossier avec tous les fichiers
mkdir -p export-gns3
cp Dockerfile.basic Dockerfile.router export-gns3/
cp -r config export-gns3/
cp README.md GUIDE_PROTOCOLES.md export-gns3/
cp votre_login-*.tar export-gns3/ 2>/dev/null || true

# Créer l'archive
zip -r votre_login-gns3-project.zip export-gns3/
```

### Importer les images

```bash
# Charger les images sauvegardées
docker load -i votre_login-basic.tar
docker load -i votre_login-router.tar
```

## Dépannage

### Les services ne démarrent pas

Vérifiez les logs:
```bash
docker logs <container_name>
cat /var/log/quagga/*.log
ps aux | grep quagga
```

### Problèmes de connectivité

1. Vérifiez que les interfaces sont actives:
   ```bash
   ip link show
   ```

2. Vérifiez les routes:
   ```bash
   ip route show
   ```

3. Testez la connectivité:
   ```bash
   ping <adresse_ip>
   ```

### Problèmes avec quagga

1. Vérifiez que les services sont actifs:
   ```bash
   ps aux | grep quagga
   ```

2. Vérifiez les fichiers de configuration:
   ```bash
   cat /etc/quagga/*.conf
   ```

3. Testez la connexion aux services:
   ```bash
   telnet localhost 2601  # zebra
   telnet localhost 2604  # bgpd
   telnet localhost 2606  # ospfd
   telnet localhost 2608  # isisd
   ```

## Notes importantes

- **Aucune adresse IP n'est configurée par défaut** - vous devez configurer les interfaces selon votre topologie
- Les noms des machines doivent contenir votre login (ex: `wil-router`, `wil-basic`)
- Les images sont conçues pour fonctionner dans GNS3 avec Docker
- Les services de routage sont démarrés automatiquement au démarrage du conteneur routeur

## Documentation

- **`GUIDE_PROTOCOLES.md`** : Guide complet expliquant BGP, OSPF, IS-IS et leur utilité (recommandé pour comprendre les protocoles)

## Références

- [Documentation Quagga](https://www.quagga.net/docs.php)
- [Documentation GNS3](https://docs.gns3.com/)
- [Documentation Docker](https://docs.docker.com/)

