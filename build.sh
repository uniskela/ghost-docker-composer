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

# Function to create a Docker secret
create_secret() {
    # Check if the secret already exists
    if echo $(docker secret ls -f name=$1 -q); then
        # If it does, remove it
        docker secret rm $1
    fi
    # Create the secret
    echo $2 | docker secret create $1 -
}

# Initialize Docker Swarm if not already initialized
docker swarm init

# Welcome message
echo "Welcome to the Ghost blog Production Image Builder!"
echo "Built by Uniskela for https://uniskela.space"
sleep 2

prompt_and_confirm "Ghost Image Version"
echo "Refer to https://hub.docker.com/_/ghost/tags"
ghost_version=$result

# Replace the entire line 4 with the new image line
sed -i "4c\    image: ghost:$ghost_version" ./docker-compose.yml

prompt_and_confirm "Ghost Website URL"
echo $result | docker secret create database__connection__host -

# Prompt for External MySQL configuration
echo "----------------------------------------------------"
echo "External MySQL Configuration"
echo "----------------------------------------------------"
sleep 2


# Prompt for ext. MySQL configuration and create Docker secrets
prompt_and_confirm "Database Connection Hostname"
echo $result | docker secret create database__connection__host -
prompt_and_confirm "Database Connection Username"
echo $result | docker secret create database__connection__user -
prompt_and_confirm "Database Connection DB Name"
echo $result | docker secret create database__connection__database -
prompt_and_confirm "Database Connection Password"
echo $result | docker secret create database__connection__password -
prompt_and_confirm "Database Connection Port"
echo $result | docker secret create database__connection__port -


# Prompt for SMTP configuration
echo "----------------------------------------------------"
echo "Email SMTP Configuration"
echo "----------------------------------------------------"
sleep 2
# Prompt for SMTP configuration and create Docker secrets
prompt_and_confirm "Email From Address"
echo $result | docker secret create mail_from -
prompt_and_confirm "Email SMTP host"
echo $result | docker secret create mail_options_host -


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
echo $result | docker secret create mail_options_auth_user -
prompt_and_confirm "Email SMTP password"
echo $result | docker secret create mail_options_auth_pass -



# Prompt for SMTP port
prompt_and_confirm "Which SMTP Port"
echo $result | docker secret create mail_options_port -


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
echo -n 'Checking if Port 2368 is open'
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

# Check if containers are running
if [ "$(docker service ls -f name=ghost_stack_ghost)" ]; then
    echo "Containers are running successfully!"
else
    echo "Something went wrong. Please check the Docker logs for more information."
fi