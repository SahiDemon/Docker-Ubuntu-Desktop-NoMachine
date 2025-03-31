#!/bin/bash

# Exit on any error
set -e

# Configuration
NGROK_TOKEN="2UnatP7VbgJIoyS3gtu50XxVOoe_48TKQZ4J5aKKcZWT4iu3T"
NGROK_REGION="ap"
SSH_PORT=22
USERNAME=$(whoami)
PASSWORD=$(openssl rand -base64 12)

# Install ngrok if not present
if ! command -v ngrok &> /dev/null; then
    echo "Installing ngrok..."
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt update && sudo apt install -y ngrok
fi

# Configure ngrok
ngrok config add-authtoken "$NGROK_TOKEN"

# Start ngrok in the background
ngrok tcp --region "$NGROK_REGION" "$SSH_PORT" > /dev/null &

# Wait for ngrok to start and get the URL
sleep 5
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' | sed 's|tcp://||')
NGROK_HOST=$(echo "$NGROK_URL" | cut -d: -f1)
NGROK_PORT=$(echo "$NGROK_URL" | cut -d: -f2)

# Output connection details in JSON format
cat << EOF
{
    "host": "$NGROK_HOST",
    "port": $NGROK_PORT,
    "username": "$USERNAME",
    "password": "$PASSWORD"
}
EOF 