#!/bin/bash

#===============================================================================
# Nombre del Script: deploy.sh
# Descripción: Script para desplegar recursos de Kubernetes desde directorios de proyectos.
# Autor: Tu Nombre
# Fecha: 2023-10-27 # Corregido el marcador de fecha
#===============================================================================

# Salir inmediatamente si un comando termina con un estado distinto de cero
set -e

# Tratar las variables no establecidas como un error
set -u

# Habilitar depuración (descomentar para depurar)
# set -x

# Capturar errores y realizar limpieza
trap 'echo "Ocurrió un error. Saliendo..."; exit 1;' ERR
# Nota: La función de limpieza actualmente está vacía. Agrega comandos específicos de limpieza aquí si es necesario.
trap 'cleanup' EXIT

#===============================================================================
# Funciones
#===============================================================================

# Función para mostrar el uso
usage() {
    echo "Uso: $0 [opciones]"
    echo "Opciones:"
    echo " -h, --help    Muestra este mensaje de ayuda y sale"
    echo " -o, --operators Especifica el directorio base para los manifiestos de operadores de Kubernetes (por defecto: ./01_pre_install_operators)"
    echo " -e, --helm    Especifica el directorio base para los charts de Helm (por defecto: ./02_deploy/HelmChartECK)"
    echo " -n, --namespace Especifica el namespace para las instalaciones de Helm (por defecto: eck)"
    echo " --skip-operators Omite el despliegue de los manifiestos de operadores"
    echo " --skip-helm   Omite el despliegue de los charts de Helm"
    exit 0
}

# Función para realizar limpieza
cleanup() {
    # echo "Limpiando archivos temporales..."
    # Agrega comandos de limpieza aquí si es necesario, por ejemplo, eliminar archivos temporales
    : # No hacer nada si no se requiere limpieza
}

# Función para registrar mensajes
log() {
    local message="$1"
    echo "[INFO] $message"
}

# Función para registrar errores
error_log() {
        local message="$1"
        echo "[ERROR] $message" >&2 # Enviar mensajes de error a stderr
}

# Función para desplegar manifiestos de Kubernetes (Operadores)
deploy_operatormanifests() {
    local base_dir="$1"
    if [[ ! -d "$base_dir" ]]; then
        error_log "El directorio de manifiestos de operadores $base_dir no existe o no es un directorio."
        # Salimos aquí porque el directorio base es esencial para este paso de despliegue
                exit 1
    fi

    log "Desplegando manifiestos de operadores de Kubernetes desde $base_dir..."
    # Buscar directorios que contengan manifiestos de Kubernetes dentro del directorio base
        # Usar find para mayor robustez y manejar posibles subdirectorios con manifiestos
        find "$base_dir" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
                if [[ -d "$dir" ]]; then
            log "Aplicando manifiestos en el directorio: $dir..."
            # Usar -R para aplicar recursivamente dentro del directorio encontrado
            if ! kubectl apply -f "$dir"; then
                                error_log "No se pudieron aplicar los manifiestos en $dir. Continuando con el siguiente directorio."
                                # Opcionalmente, podrías salir aquí en lugar de continuar
                                # exit 1
                        fi
        fi
    done
    log "Despliegue de manifiestos de operadores completado."
}
# Función para crear un secreto de Kubernetes
create_k8s_secret() {
    local secret_name="elasticsearch-test-es-cert"
    local namespace="eck"
    local secrets_dir="./03_ca_secrets"

    # Verificar si el directorio de secretos existe
    if [[ ! -d "$secrets_dir" ]]; then
        error_log "El directorio de secretos $secrets_dir no existe o no es un directorio."
        exit 1
    fi

    # Verificar si los archivos necesarios existen
    local ca_cert="$secrets_dir/tls.crt"
    local tls_cert="$secrets_dir/tls.crt"
    local tls_key="$secrets_dir/tls.key"

    if [[ ! -f "$ca_cert" || ! -f "$tls_cert" || ! -f "$tls_key" ]]; then
        error_log "Uno o más archivos necesarios para el secreto no existen en $secrets_dir."
        exit 1
    fi

    log "Creando el secreto de Kubernetes '$secret_name' en el namespace '$namespace'..."

    # Crear el secreto
    if ! kubectl -n "$namespace" create secret generic "$secret_name" \
        --from-file=ca.crt="$ca_cert" \
        --from-file=tls.crt="$tls_cert" \
        --from-file=tls.key="$tls_key" --dry-run=client -o yaml | kubectl apply -f -; then
        error_log "No se pudo crear el secreto '$secret_name' en el namespace '$namespace'."
        exit 1
    fi

    log "Secreto '$secret_name' creado exitosamente en el namespace '$namespace'."
}
# Función para desplegar charts de Helm
deploy_helmmanifests() {
    local base_dir="$1"
        local namespace="$2"

    if [[ ! -d "$base_dir" ]]; then
        error_log "El directorio de charts de Helm $base_dir no existe o no es un directorio."
        # Salimos aquí porque el directorio base es esencial para este paso de despliegue
                exit 1
    fi

        # Verificar si helm está instalado
        if ! command -v helm &> /dev/null; then
                error_log "El comando Helm no se encontró. Por favor, instala Helm."
                exit 1
        fi

    log "Desplegando charts de Helm desde $base_dir en el namespace '$namespace'..."
    # Buscar directorios que contengan charts de Helm dentro del directorio base
        # Un directorio de chart de Helm típicamente contiene un archivo Chart.yaml.
        find "$base_dir" -mindepth 1 -maxdepth 1 -type d | while read -r chart_dir; do
                if [[ -f "$chart_dir/Chart.yaml" ]]; then
            local chart_name=$(basename "$chart_dir")
                        # Usar un nombre de release más robusto, tal vez una combinación del nombre del chart y un identificador único,
                        # o permitir sobrescribirlo. Por ahora, usar el nombre del directorio como nombre de release.
                        local release_name="$chart_name"

            log "Instalando el chart de Helm '$chart_name' (nombre de release '$release_name') desde $chart_dir en el namespace '$namespace'..."

                        # Verificar si el release ya existe en el namespace objetivo
                        if helm status "$release_name" --namespace "$namespace" &> /dev/null; then
                                log "El release de Helm '$release_name' ya existe en el namespace '$namespace'. Actualizando..."
                                if ! helm upgrade "$release_name" "$chart_dir" --install --namespace "$namespace" --create-namespace; then
                                        error_log "No se pudo actualizar el release de Helm '$release_name' en el namespace '$namespace'. Continuando con el siguiente chart."
                                        # Opcionalmente, salir aquí
                                        # exit 1
                                fi
                        else
                                log "El release de Helm '$release_name' no existe en el namespace '$namespace'. Instalando..."
                                if ! helm install "$release_name" "$chart_dir" --namespace "$namespace" --create-namespace; then
                                        error_log "No se pudo instalar el release de Helm '$release_name' en el namespace '$namespace'. Continuando con el siguiente chart."
                                        # Opcionalmente, salir aquí
                                        # exit 1
                                fi
                        fi
        else
                        log "Saltando el directorio '$chart_dir' ya que no parece ser un chart de Helm (falta Chart.yaml)."
        fi
    done
    log "Despliegue de Helm completado."
}

#===============================================================================
# Script Principal
#===============================================================================

# Valores por defecto
OPERATORS_BASE_DIR="./02_pre_install_operators"
HELM_BASE_DIR="./04_deploy"
HELM_NAMESPACE="eck"
SKIP_OPERATORS=false
SKIP_HELM=false


# Analizar argumentos usando getopts para un mejor manejo de opciones
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -o|--operators)
            if [[ -n "$2" ]]; then
                OPERATORS_BASE_DIR="$2"
                shift
            else
                error_log "Error: --operators requiere un argumento de directorio."
                usage
            fi
            ;;
        -e|--helm)
            if [[ -n "$2" ]]; then
                HELM_BASE_DIR="$2"
                shift
            else
                error_log "Error: --helm requiere un argumento de directorio."
                 usage
            fi
            ;;
                -n|--namespace)
                        if [[ -n "$2" ]]; then
                                HELM_NAMESPACE="$2"
                                shift
                        else
                                error_log "Error: --namespace requiere un argumento de namespace."
                                usage
                        fi
                        ;;
                --skip-operators)
                        SKIP_OPERATORS=true
                        ;;
                --skip-helm)
                        SKIP_HELM=true
                        ;;
        *)
            error_log "Opción desconocida: $1"
            usage
            ;;
    esac
    shift
done

# Ejecutar despliegues según las opciones
if ! $SKIP_OPERATORS; then
        deploy_operatormanifests "$OPERATORS_BASE_DIR"
else
        log "Saltando el despliegue de manifiestos de operadores."
fi
      
      create_k8s_secret

if ! $SKIP_HELM; then
        deploy_helmmanifests "$HELM_BASE_DIR" "$HELM_NAMESPACE"
else
        log "Saltando el despliegue de charts de Helm."
fi

log "Script finalizado."

exit 0