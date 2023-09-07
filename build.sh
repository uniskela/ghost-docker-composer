#!/bin/bash

# Function to prompt for user input and confirm
prompt_and_confirm() {
    echo "Please enter your $1:"
    read var
    while true; do
        echo "You entered: $var"
        echo "Is this correct? (y/n)"
        read confirm
        if [ "$confirm" == "y" ]; then
            break
        else
            echo "Please re-enter your $1:"
            read var
        fi
    done
    result=$var
}

# Function to create a Docker secret and update docker-compose.yml
create_secret() {
    local secret_name=$1
    # Check if the secret already exists
    if [[ $(docker secret ls -f name=$secret_name -q) ]]; then
        # If it does, ask the user what they want to do
        echo "A Docker secret with the name $secret_name already exists."
        echo "What would you like to do?"
        echo "1. Remove the old secret and create a new one"
        echo "2. Keep the old secret"
        echo "3. Select a different name for the new secret"
        read -p "Please enter the number of your choice: " choice
        
        case $choice in
            1)
                # Remove the old secret and create a new one
                echo "Removing existing Docker secret: $secret_name"
                docker secret rm $secret_name
                ;;
            2)
                # Keep the old secret
                echo "Keeping existing Docker secret: $secret_name"
                return
                ;;
            3)
                # Select a different name for the new secret
                read -p "Please enter a new name for the Docker secret: " secret_name
                ;;
            *)
                echo "Invalid choice. Please run the script again."
                exit 1
                ;;
        esac
    fi
    # Create the secret
    echo "Creating new Docker secret: $secret_name"
    echo $2 | docker secret create $secret_name -
    # Update docker-compose.yml with the secret name
    sed -i "/secrets:/a \      - $secret_name" docker-compose.yml
}

# Check if user has Docker permissions
if ! docker info >/dev/null 2>&1; then
    echo "You do not have sufficient Docker permissions."
    echo "Attempting to add user to Docker group..."
    
    # Attempt to add user to Docker group
    sudo usermod -aG docker $USER
    
    echo "You may need to log out and log back in to apply these changes."
    exit 1
fi

# Display network interfaces and IP addresses
ip a

# Prompt user for IP address
read -p "Please enter an IP address for Docker Swarm to advertise: " ip_addr

# Initialize Docker Swarm with user-specified IP address
echo "----------------------------------------------------"
echo "Attempting to init Docker Swarm"
sleep 3
echo "Below is the Docker response:"
docker swarm init --advertise-addr $ip_addr
echo "----------------------------------------------------"

# Welcome message
echo "----------------------------------------------------"
echo "Welcome to the Ghost blog Production Image Builder!"
echo "Built by Uniskela for https://uniskela.space"
echo "----------------------------------------------------"
sleep 2

# Prompt for Ghost Image Version
echo "----------------------------------------------------"
echo "Refer to https://hub.docker.com/_/ghost/tags"
echo "----------------------------------------------------"
prompt_and_confirm "Ghost Image Version"

# Replace the entire line 4 with the new image line
sed -i "4c\    image: ghost:$ghost_version" ./docker-compose.yml

# Prompt for Ghost Website URL and create Docker secret
prompt_and_confirm "Ghost Website URL"
create_secret "database__connection__host" $result


# Prompt for External MySQL configuration
echo "----------------------------------------------------"
echo "External MySQL Configuration"
echo "----------------------------------------------------"
sleep 2


# Prompt for ext. MySQL configuration and create Docker secrets
prompt_and_confirm "Database Connection Hostname"
create_secret "database__connection__host" $result
prompt_and_confirm "Database Connection Username"
create_secret "database__connection__user" $result
prompt_and_confirm "Database Connection DB Name"
create_secret "database__connection__database" $result
prompt_and_confirm "Database Connection Password"
create_secret "database__connection__password" $result
prompt_and_confirm "Database Connection Port"
create_secret "database__connection__port" $result


# Prompt for SMTP configuration
echo "----------------------------------------------------"
echo "Email SMTP Configuration"
echo "----------------------------------------------------"
sleep 2
# Prompt for SMTP configuration and create Docker secrets
prompt_and_confirm "Email From Address"
create_secret "mail_from" $result
prompt_and_confirm "Email SMTP host"
create_secret "mail_options_host" $result


# Prompt for secure connection
echo "Does your SMTP use secure connection? (y/n)"
read mail__options__secure
if [ "$mail__options__secure" == "y" ]; then
    echo "true" | docker secret create mail_options_secure -
else
    echo "false" | docker secret create mail_options_secure -
fi

# Prompt for SMTP user and password
prompt_and_confirm "Email SMTP user"
create_secret "mail_options_auth_user" $result
prompt_and_confirm "Email SMTP password"
create_secret "mail_options_auth_pass" $result

# Prompt for SMTP port
prompt_and_confirm "Which SMTP Port"
create_secret "mail_options_port" $result



# Check if netstat is installed
if ! command -v netstat &> /dev/null
then
    echo "netstat could not be found. Installing net-tools..."
    # Update package lists
    sudo apt-get update
    # Install net-tools
    sudo apt-get install -y net-tools
fi
sleep 3 &
PID=$!
i=1
sp="/-\|"
echo -n 'Checking if Port 2368 is open. '
while [ -d /proc/$PID ]
do
  printf "\b${sp:i++%${#sp}:1}"
done
# Check if port 2368 is open
PORT=2368
if netstat -tuln | grep $PORT ; then
    echo "Port $PORT is not open. Please check your Docker configuration."
    sleep 5
    exit 1
    else
    echo "Port $PORT is open."
fi


# Deploy Docker stack
docker stack deploy -c docker-compose.yml ghost_stack

# Wait for a few seconds to let the stack start
sleep 5

# Check if containers are running
service_state=$(docker service ps --format '{{.CurrentState}}' ghost_stack_ghost)

if [[ $service_state == *"Running"* ]]; then
    echo "Containers are running successfully!"
else
    echo "Something went wrong. The service is not running."
    echo "Service state: $service_state"
    echo "Please check the Docker logs for more information."
    echo "Use the command: docker service logs ghost_stack_ghost"
fi
