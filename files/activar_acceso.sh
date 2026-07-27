#!/usr/bin/env bash
set -euo pipefail

# Directorio .ssh del usuario que ejecuta el script
SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_ed25519"          # nombre por defecto -> SSH lo usa sin -i
AUTH_KEYS="$SSH_DIR/authorized_keys"

# 1. Asegurar que existe ~/.ssh con permisos correctos
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# 2. No sobrescribir una clave existente sin avisar
if [ -f "$KEY_FILE" ]; then
    echo "ERROR: ya existe $KEY_FILE. Bórrala o renómbrala antes de continuar." >&2
    exit 1
fi

# 3. Generar el par de claves (sin passphrase; usa -N "..." si quieres una)
ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "$USER@$(hostname)"

# 4. Permisos correctos de las claves
chmod 600 "$KEY_FILE"
chmod 644 "$KEY_FILE.pub"

# 5. Añadir la pública al final de authorized_keys (sin borrar las existentes)
touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
cat "$KEY_FILE.pub" >> "$AUTH_KEYS"