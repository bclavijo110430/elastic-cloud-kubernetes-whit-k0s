#!/bin/bash
# Configuración inicial
K0SCTL_VERSION="v0.23.0"
K0SCTL_BIN="/usr/local/bin/k0sctl"
SSH_KEY="$HOME/.ssh/id_rsa"
CONFIG_FILE="k0sctl.yaml"
K0S_VERSION="v1.32.3+k0s"

# Lista de nodos (IP o hostname)
MASTERS=("192.168.0.10")
NODES=("192.168.0.11" "192.168.0.12")  # Puedes agregar más nodos aquí
SSH_USER="ubuntu"

echo "🔐 Verificando clave SSH..."

# Crear clave si no existe
if [ ! -f "$SSH_KEY" ]; then
  echo "🔧 Generando clave SSH..."
  ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
fi

echo "🚀 Copiando clave SSH a nodos..."

# Copiar clave SSH pública a cada nodo maestro
for MASTER in "${MASTERS[@]}"; do
  echo "🔗 Copiando clave a $MASTER.."
  ssh-copy-id -i "$SSH_KEY.pub" "$SSH_USER@$MASTER"
done

# Copiar clave SSH pública a cada nodo worker
for NODE in "${NODES[@]}"; do
  echo "🔗 Copiando clave a $NODE..."
  ssh-copy-id -i "$SSH_KEY.pub" "$SSH_USER@$NODE"
done

echo "📦 Verificando instalación de k0sctl..."

# Descargar k0sctl si no existe
if [ ! -f "$K0SCTL_BIN" ]; then
  echo "⬇️ Descargando k0sctl..."
  curl -sSLf "https://github.com/k0sproject/k0sctl/releases/download/$K0SCTL_VERSION/k0sctl-linux-amd64" -o k0sctl
  chmod +x k0sctl
  sudo mv k0sctl "$K0SCTL_BIN"
fi

echo "📝 Generando archivo de configuración $CONFIG_FILE..."

# Crear archivo k0sctl.yaml
cat > "$CONFIG_FILE" <<EOF
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: my-k0s-cluster
spec:
  hosts:
$(for MASTER in "${MASTERS[@]}"; do
cat << EON
    - role: controller
      ssh:
        address: $MASTER # replace with the controller's IP address
        user: $SSH_USER
        keyPath: $SSH_KEY
EON
done)
$(for NODE in "${NODES[@]}"; do
cat <<EON
    - role: worker
      ssh:
        address: $NODE
        user: $SSH_USER
        keyPath: $SSH_KEY
EON
done)
  k0s:
    version: "$K0S_VERSION"
EOF

echo " Desplegando el clúster k0s con k0sctl..."

k0sctl apply --config "$CONFIG_FILE"  --trace

echo  "Clúster desplegado con éxito. Obteniendo kubeconfig..."
k0sctl kubeconfig --config "$CONFIG_FILE" > kubeconfig

echo " Proceso completado. Puedes usar kubeconfig con kubectl:"
echo "export KUBECONFIG=\$PWD/kubeconfig"

##test

k0s kubectl get nodes