# P1 - Configuration GNS3 avec Docker et FRRouting

Ce projet contient deux images Docker simples pour GNS3 :
- **Image basique** : Alpine + busybox
- **Image routeur** : Ubuntu + FRRouting (BGPD, OSPFD, IS-IS)


# Build

```bash
docker build -t onyx/p1router:latest -f Dockerfile.router .
docker build -t onyx/p1basic:latest -f Dockerfile.basic .
```


## Références

- [Documentation FRRouting](https://docs.frrouting.org/)
- [Documentation GNS3](https://docs.gns3.com/)
- [Documentation Docker](https://docs.docker.com/)

