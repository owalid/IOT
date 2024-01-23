# Inception of things (IoT)

IoT est un projet qui permet de découvrir vagrant, argocd et kubernetes via 3 exercices et un exercice bonus orienté CI/CD avec une instance gitlab.

1) Mise en place d'une vm avec vagrant et d'un _dummy_ serveur avec k3s
2) Mise en place de 3 applications, avec une vm déployée avec vagrant, et un ingress qui dispatche les requêtes selon l'host http spécifié.
3) Mise en place d'un pipeline argocd avec k3d et mise à jour automatique d'une application selon le tag de version de l'image docker spécifié.
4) (Bonus) Mise en place d'une instance personnelle gitlab afin d'opérer comme dans la partie 3, mais sans github.


## 1) Mise en place de deux vm avec vagrant et de _dummy_ serveur / _server worker_  avec k3s
=> Contraintes :
- 2 vm lancées avec vagrant
- Les noms des vm doivent contenir notre identifiant 42 et S pour la vm _server_, SW pour la vm qui contient le _server worker_
- Deux ip dédiées pour chacune des vm sur l'interface réseau eth1
- Se connecter via ssh sans mot de passe
- Un Controlleur sur le _server_ via k3s
- Un agent sur le _server worker_ via k3s

=> Usage :
- `cd p1`
- `vagrant up`
- `vagrant ssh oelayadS` | `vagrant ssh oelayadSW`
- `sudo kubectl get nodes -o wide`
- `ip a show eth1` (le même commande peut être effectuée sur la vm qui contient le _server worker_)

![image](https://github.com/owalid/IOT/assets/61985948/b3a37744-3995-4015-82ab-0d78c55a8535)

## 2) Mise en place de 3 applications, avec une vm déployée avec vagrant, et un ingress qui dispatche les requêtes selon l'host http spécifié.
=> Contraintes :
- Utiliser vagrant pour mettre en place une vm
- Une adresse ip dédié pour la vm
- Mettre en place un cluster via k3s qui va servir via un ingress controller une des trois applications suivant l'en-tête `Host` de la requête http
- L'host peut-être `app1` ou `app2`, sinon par défaut c'est `app3` qui est servie.
- `app2` doit posséder deux _replicas_

Une image qui illustre cet exercice :

![Capture d’écran du 2024-01-23 12-50-35](https://github.com/owalid/IOT/assets/61985948/7919f83a-659b-4122-b22a-6884025c6b82)


=> Usage
- `cd p2`
- `vagrant up`
- `vagrant ssh chbadadS`

