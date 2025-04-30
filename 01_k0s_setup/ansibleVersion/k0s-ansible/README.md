# k0s Ansible Playbook

Crea un clúster de Kubernetes usando Ansible y la distribución de Kubernetes upstream [k0s](https://github.com/k0sproject/k0s).

## Playbooks incluidos

`deploy.yml`:

```ShellSession
$ ansible-playbook deploy.yml -i inventory/inventory.yml
```

Tu inventario debe incluir al menos un nodo `initial_controller` y un nodo `worker`. Para obtener un plano de control altamente disponible, se pueden agregar más nodos `controller`. El primer controlador inicial crea tokens que se escriben en los nodos cuando se ejecuta el playbook.

`delete.yml`:

```ShellSession
$ ansible-playbook delete.yml -i inventory/inventory.yml
```

Elimina k0s junto con todos sus archivos, directorios y servicios de todos los hosts.

## Guía paso a paso

Puedes encontrar una guía de usuario sobre cómo usar este playbook en la [documentación de k0s](https://docs.k0sproject.io/main/examples/ansible-playbook/).



Prueba la conexión SSH a todas las instancias en tu archivo `inventory.yml`:

```ShellSession
$ ansible -i inventory/inventory.yml -m ping all
k0s-4 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
k0s-1 | SUCCESS => {
...
```

Crea tu clúster:

```ShellSession
$ ansible-playbook site.yml -i inventory/inventory.yml
...
TASK [k0s/initial_controller : print kubeconfig command] *******************************************************
Friday 22 January 2021  15:32:44 +0100 (0:00:00.247)       0:04:25.177 ********
ok: [k0s-1] => {
    "msg": "Para usar el clúster: export KUBECONFIG=/Users/dev/k0s-ansible/inventory/artifacts/k0s-kubeconfig.yml"
}
...
PLAY RECAP *****************************************************************************************************
...
Friday 22 January 2021  15:32:58 +0100 (0:00:00.575)       0:04:39.234 ********
===============================================================================
download : Descargar binario k0s k0s-v0.10.0-beta1-amd64 ------------------------------------------------ 225.86s
prereq : Instalar paquetes apt -------------------------------------------------------------------------- 17.30s
k0s/initial_controller : Esperar al apiserver de k8s ---------------------------------------------------- 15.34s
k0s/controller : Esperar al apiserver de k8s ------------------------------------------------------------- 3.36s
Gathering Facts ----------------------------------------------------------------------------------------- 1.35s
prereq : Crear directorios de k0s ----------------------------------------------------------------------- 0.86s
Gathering Facts ----------------------------------------------------------------------------------------- 0.84s
k0s/worker : Crear servicio de k0s worker con comando de instalación ------------------------------------ 0.80s
Gathering Facts ----------------------------------------------------------------------------------------- 0.79s
k0s/initial_controller : Crear servicio de k0s initial controller con comando de instalación ------------ 0.76s
k0s/initial_controller : Habilitar y verificar servicio de k0s ------------------------------------------ 0.74s
k0s/controller : Crear servicio de k0s controller con comando de instalación ---------------------------- 0.72s
prereq : Escribir el archivo de configuración de k0s ---------------------------------------------------- 0.69s
Gathering Facts ----------------------------------------------------------------------------------------- 0.68s
Gathering Facts ----------------------------------------------------------------------------------------- 0.65s
k0s/worker : Habilitar y verificar servicio de k0s ------------------------------------------------------ 0.58s
k0s/controller : Habilitar y verificar servicio de k0s ------------------------------------------------- 0.53s
k0s/worker : Escribir el archivo de token de k0s en el worker ------------------------------------------ 0.48s
k0s/controller : Escribir el archivo de token de k0s en el controller ----------------------------------- 0.44s
k0s/initial_controller : Establecer IP del controller en kubeconfig ------------------------------------- 0.32s
```

Conéctate a tu nuevo clúster de Kubernetes. La configuración está lista para usarse en el directorio `inventory/artifacts`:

```ShellSession
$ export KUBECONFIG=/Users/dev/k0s-ansible/inventory/artifacts/k0s-kubeconfig.yml
$ kubectl get nodes -o wide
NAME    STATUS   ROLES    AGE   VERSION        INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k0s-4   Ready    <none>   17m   v1.20.2-k0s1   192.168.64.57   <none>        Ubuntu 20.04.1 LTS   5.4.0-62-generic   containerd://1.4.3
k0s-5   Ready    <none>   17m   v1.20.2-k0s1   192.168.64.58   <none>        Ubuntu 20.04.1 LTS   5.4.0-62-generic   containerd://1.4.3
$ kubectl run hello-k0s --image=quay.io/prometheus/busybox --rm -it --restart=Never --command -- sh -c "echo hello k0s"
hello k0s
pod "hello-k0s" deleted
```