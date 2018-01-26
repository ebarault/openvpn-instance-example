# OpenVPN

Serveur [OpenVPN](https://www.openvpn.net/)

## Mise en route

Installer une instance EC2 Amazon Linux avec Git et Docker et un enregistrement DNS (par exemple via le code terraform, une instance avec dns_record)

Se connecter dessus

    sudo su
    mkdir /data
    git clone git@gitlab.tools.lagrangenumerique.fr:infra/openvpn.git
    cd openvpn

Eventuellement éditer le `playbook.yml` pour adapter la liste des clients. Préciser le domaine (à refaire à chaque fois, ou mettre `DOMAIN=tools.lagrangenumerique.fr` dans `/etc/environment`)

    export DOMAIN=tools.lagrangenumerique.fr

Puis démarrer

    ./start.sh

Après quoi il n'y a plus qu'a récupérer les configs et faire un test en local. Si vous avez un bastion et l'IP interne, le script `test.sh` fait le taff

    ./test.sh 10.0.1.181 rgarrigue

Les fichiers de configuration des clients sont dans les dossiers `client_keys_udp` et `client_keys_tcp`, prêt à être distribués.

## En cas de soucis

Sur le serveur un `./reset.sh` supprime l'existant pour tout régénérer, mais nécessitera une redistribution des configurations. Pour debugguer vérifier le fichier .ovpn du client, regarder dans `/var/log/syslog` du client Ubuntu et dans `docker logs -f ovpn-tcp` ou `docker logs -f ovpn-udp` du serveur.

Problème connu 1, les loads balancers d'Amazon, ou AWS ELB ne supportent pas l'UDP. Les tests n'ont pas été concluant, il a fallut tout mettre sur une AWS EC2 classique sans ELB.

Problème connu 2, Ubuntu 16.04 embarque NetworkManager 1.2 (contre upstream stable atm 1.10, Ubuntu 18.04 en 1.10, Ubuntu 17.10 en 1.8), qui 

## Des explications

### Côté serveur

Le `start.sh` est grandement inspiré de cette documentation : https://github.com/kylemanna/docker-openvpn/blob/master/docs/docker-compose.md, ainsi que https://github.com/kylemanna/docker-openvpn/blob/master/docs/tcp.md. Le `playbook.yml` se base sur https://github.com/dave-burke/ansible-playbook/blob/master/roles/vpn/tasks/main.yml

Le VPN est configuré tant pour l'UDP sur le port OpenVPN usuel 1194, que pour le TCP sur le 443 parce que ce port est toujours ouvert en sortie et qu'un flux chiffré n'y étonnes pas. Pour un déploiement sur AWS, attention les ELB ne gèrent pas l'UDP. De plus le TCP n'a pas voulu marcher, alors qu'il fonctionne quand il n'y pas d'ELB...

Le MTU, le DNS et le mot de passe PKI sont configurés dans les variables `playbook.yml`. Si vous voulez des surcharger, il est préférable d'éditer `start.sh` en ajoutant un `-e VAR=VALEUR` à la commande `ansible-playbook`

### Côté clients

L'installation génère des fichiers .ovpn (contenant clé, certificat, sans mot de passe) pour les clients définis dans la variable ansible `openvpn_clients`, qui sont placés dans les dossiers `/data/ha_instance/client_keys_udp` et `/data/ha_instance/client_keys_tcp`. Et donc a récupérer et distribuer à la main, bien que le script `test.sh` puisse aider. Sauf raison spécifique, **préférer l'UDP**

Pour l'utiliser sur Ubuntu (ou toute distribution utilisant apt et Network Manager à priori), `sudo apt install network-manager-openvpn-gnome network-manager-openvpn`. Puis dans l'interface réseau Network Manager, ajouter un nouveau VPN en important le fichier. Alternative via la CLI, `nmcli connection import type openvpn file rgarrigue.ovpn`.
