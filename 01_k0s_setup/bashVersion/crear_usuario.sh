#!/bin/bash

# Función para crear un usuario
crear_usuario() {
  local nombre_usuario="$1"
  local contrasena="$2"

  # Verificar si el usuario ya existe
  if id -u "$nombre_usuario" >/dev/null 2>&1; then
    echo "El usuario '$nombre_usuario' ya existe."
    return 1
  fi

  # Crear el usuario
  sudo adduser "$nombre_usuario"
  if [ $? -ne 0 ]; then
    echo "Error al crear el usuario '$nombre_usuario'."
    return 1
  fi

  # Establecer la contraseña
  echo "$nombre_usuario:$contrasena" | sudo chpasswd
  if [ $? -ne 0 ]; then
    echo "Error al establecer la contraseña para '$nombre_usuario'."
    return 1
  fi

  # Agregar el usuario al grupo k0s
  sudo usermod -aG k0s "$nombre_usuario"
  if [ $? -ne 0 ]; then
    echo "Advertencia: No se pudo agregar el usuario '$nombre_usuario' al grupo 'k0s'. Asegúrate de que el grupo exista."
  else
    echo "Usuario '$nombre_usuario' agregado al grupo 'k0s'."
  fi

  # Otorgar permisos de administrador (sudo)
  sudo usermod -aG sudo "$nombre_usuario"
  if [ $? -ne 0 ]; then
    echo "Error al otorgar permisos de administrador (sudo) a '$nombre_usuario'."
    return 1
  fi

  echo "Usuario '$nombre_usuario' creado con éxito y con permisos de administrador."
}

# --- Inicio del script ---

echo "Script para crear usuarios en Ubuntu con permisos de administrador y grupo k0s."

# Solicitar información del primer usuario
read -p "Ingrese el nombre del primer usuario: " usuario1
read -s -p "Ingrese la contraseña para '$usuario1': " pass1
echo  # Salto de línea para ocultar la contraseña ingresada

crear_usuario "$usuario1" "$pass1"

# Preguntar si se desea crear otro usuario
read -p "¿Desea crear otro usuario? (s/n): " respuesta

while [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; do
  read -p "Ingrese el nombre del nuevo usuario: " nuevo_usuario
  read -s -p "Ingrese la contraseña para '$nuevo_usuario': " nueva_pass
  echo  # Salto de línea para ocultar la contraseña ingresada

  crear_usuario "$nuevo_usuario" "$nueva_pass"

  read -p "¿Desea crear otro usuario? (s/n): " respuesta
done

echo "Proceso de creación de usuarios completado."

exit 0