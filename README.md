### elastic-cloud-kubernetes-con-k0s
 solucion para implentar ECK con kubernetes k0s sobre bare metal, esta solucion da de alta los siguientes operadores:

   * local-provisioner -> storage class para distribucion local
   * metal LB ->  implementa  metal lb con  uso sobre capa 2 y el CIR  "192.168.1.131-192.168.1.150" para cambiar el CIR el arhivo se encuentra "./01_pre_install_operators/02_metallbIOperator/02_ipPool.yml/"
   * ECK Operator - operador eck 

## operacion eck ###

la implementacion se administra como desde un helm chart  ubicado en "02_deploy/eckdeploy.values.yml" e dicho archivo se implementa los siguientes parametros de configuracion de la solucion  :

 * Configuraciones de despliegue
 * Anotaciones generales 
 * Especificaciones generales
 * Tipo de servicio general
 * Certificado a aplicar (tiene que existir previamente como secret)
 * Escalamiento de servicios

#### Instalacion de K0S #####
**Prerequisitos:** 
 *  crear usuario en cada maquina a dar de alta como role de cluster  ya sea para control plane o controller como para worker, para facilitar la implementacion existe un script en la carpeta 01_k0s_setup/crear_usuario.sh. especificar el nombre de usuario a crear y contraseña crear_usuario "$usuario1" "$pass1"
 *  una vez creado el usuario especificarlo en el script ./k0s.sh , el la variable $SSH_USER
 * parametrizar script k0s.sh  segun necesidad
 
 #### Configuración inicial
```markdown
| **Parámetro**        | **Valor**                         |
|----------------------|-----------------------------------|
| K0SCTL_VERSION       | v0.23.0                           |
| K0SCTL_BIN           | /usr/local/bin/k0sctl             |
| SSH_KEY              | $HOME/.ssh/id_rsa                 |
| CONFIG_FILE          | k0sctl.yaml                       |
| K0S_VERSION          | v1.32.3+k0s                       |
```
# Lista de nodos (IP o hostname)
MASTERS=("192.168.0.10")
NODES=("192.168.0.11" "192.168.0.12")  # Puedes agregar más nodos aquí
SSH_USER="ubuntu"
'
## Requerimientos ## 
 * OS: Ubuntu Server
 * Usuario: Super User
 * RSAkey: Crear clave rsa compartida en cada maquina a utilizar 
 * Binario K0sclt: binario instalacion cluster http://github.com/k0sproject/k0sctl#installation (maquina de control o management)
 * Binario kubectl : curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" & sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl  (maquina de control management debe tener acceso mediante kubeconfig )
 * Binario de helm : binario de helm https://helm.sh/es/docs/intro/install/


| **Rol**                  | **Memoria (RAM)** | **CPU virtual (vCPU)** |
|---------------------------|-------------------|-------------------------|
| Nodo controlador          | 1 GB             | 1 vCPU                 |
| Nodo de trabajo           | 0,5 GB           | 1 vCPU                 |
| Controlador + trabajador  | 1 GB             | 1 vCPU                 

###### Recomendaciones del nodo controlador#

| **# de nodos de trabajo** | **Número de pods** | **RAM recomendada** | **vCPU recomendada** |
|----------------------------|--------------------|----------------------|-----------------------|
| hasta 10                  | hasta 1000        | 1-2 GB              | 1-2 CPU virtuales     |
| hasta 50                  | hasta 5000        | 2-4 GB              | 2-4 CPU virtuales     |
| hasta 100                 | hasta 10000       | 4-8 GB              | 2-4 CPU virtuales     |
| hasta 500                 | hasta 50000       | 8-16 GB             | 4-8 CPU virtuales     |
| hasta 1000                | hasta 100000      | 16-32 GB            | 8-16 CPU virtuales    |
| hasta 5000                | hasta 150000      | 32-64 GB            | 16-32 vCPU            |


## proceso de instalacion K0s ####
 
 link de documentacion K0s: 
 https://docs.k0sproject.io/v1.21.2+k0s.1/k0sctl-install/

## proceso de deploy ### 

1 otorgar permisos de ejecucion con chmod +x a  ./install.sh script , el script acepta los  parametros:

     "Opciones:"
     " -h, --help    Muestra este mensaje de ayuda y sale"
     " -o, --operators Especifica el directorio base para los manifiestos de operadores de Kubernetes (por defecto: ./01_pre_install_operators)"
     " -e, --helm    Especifica el directorio base para los charts de Helm (por defecto: ./02_deploy/HelmChartECK)"
     " -n, --namespace Especifica el namespace para las instalaciones de Helm (por defecto: eck)"
     " --skip-operators Omite el despliegue de los manifiestos de operadores"
     " --skip-helm   Omite el despliegue de los charts de Helm"

## Valores por defecto ### 

        ```bash
        # Directorio base para los manifiestos de operadores de Kubernetes
        OPERATORS_BASE_DIR="./01_pre_install_operators"

        # Directorio base para los charts de Helm
        HELM_BASE_DIR="./02_deploy"

        # Namespace por defecto para las instalaciones de Helm
        HELM_NAMESPACE="eck"

        # Indica si se debe omitir el despliegue de los manifiestos de operadores
        SKIP_OPERATORS=false

        # Indica si se debe omitir el despliegue de los charts de Helm
        SKIP_HELM=false
        ```
#### alta de agente elastic agent

para instalar los elastic agent en las maquinas  se debe cumplir lo siguientes pasos:

* instalar certificado root CA con el que se dio de alta la implentacion de ECk
* descomprimir la el archivo elastic elastic-agent-8.16.6-windows-x86_64.zip ubicador en la carpeta ./elastic_agent_release
* ejecutar como administrador  el comando : 

```bash
.\elastic-agent.exe install --url=https://fleetserver.elk.external.com:8220 --enrollment-token=tokenapp== --fleet-server-host=https://fleetserver.elk.external.com:8220
```

// los valores de los endpoint son referenciales se deben cambiar por los endpoint de destino 