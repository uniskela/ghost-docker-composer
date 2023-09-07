#!/bin/bash

# Function to prompt for user input and confirm
prompt_and_confirm() {
    local prompt_string=$1
    local secret_name=$2

    while true; do
        echo "Please enter your $prompt_string (or press Enter to use the existing secret, if available):"
        read var

        # If the user pressed Enter, check if a secret exists
        if [ -z "$var" ]; then
            if [[ $(docker secret ls -f name=$secret_name -q) ]]; then
                # If a secret exists, use it
                echo "Using existing Docker secret: $secret_name"
                result=$(docker secret inspect -f '{{.Spec.Name}}' $secret_name)
                break
            else
                # If no secret exists, warn the user and ask for the input again
                echo "Warning: No existing Docker secret found for $secret_name. Please enter a value."
                continue
            fi
        fi

        echo "You entered: $var"
        echo "Is this correct? (y/n, or press Enter to confirm)"
        read confirm
        if [ "$confirm" == "y" ] || [ -z "$confirm" ]; then
            result=$var
            break
        fi
    done
}





# Function to create a Docker secret and update docker-compose.yml
create_secret() {
    local secret_name=$1
    local secret_value=$2

    # If the user has chosen to use the existing secret, skip the three options
    if [[ "$secret_value" == "$secret_name" ]]; then
        echo "Using existing Docker secret: $secret_name"
        return
    fi

    # Check if the secret already exists
    if [[ $(docker secret ls -f name=$secret_name -q) ]]; then
        # If it does, ask the user what they want to do
        echo "Docker Secret already exists."
        echo "What would you like to do?"
        echo "1. Use New One"
        echo "2. Keep the old secret"
        echo "3. New secret name"
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
    echo $secret_value | docker secret create $secret_name -
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

# Function to validate IP addresses
validate_ip() {
    local ip=$1
    local valid=1

    IFS='.' read -ra addr <<< "$ip"
    [[ ${#addr[@]} -eq 4 ]] || valid=0
    for i in "${addr[@]}"; do
        [[ $i -ge 0 && $i -le 255 ]] || valid=0
    done

    echo "$valid"
}

# Prompt user for IP address
while true; do
    read -p "Please enter an IP address for Docker Swarm to advertise: " ip_addr
    if [[ $(validate_ip $ip_addr) -eq 1 ]]; then
        break
    else
        echo "Invalid IP address. Please enter a valid IP address."
    fi
done

# Initialize Docker Swarm with user-specified IP address
echo "Attempting to init Docker Swarm..."
docker_swarm_init_output=$(docker swarm init --advertise-addr $ip_addr)
if [[ $docker_swarm_init_output == *"Error response from daemon"* ]]; then
    echo "Error: Failed to initialize Docker Swarm."
    echo "Docker response: $docker_swarm_init_output"
    exit 1
else
    echo "Docker Swarm initialized successfully!"
fi

clear
# Welcome message
clear
echo "----------------------------------------------------"
echo "Welcome to the Ghost blog Swarm Builder!"
echo "Built by Uniskela for https://uniskela.space"
echo "----------------------------------------------------"
sleep 3
# Initialize Docker Swarm with user-specified IP address
echo "----------------------------------------------------"
echo "Attempting to init Docker Swarm..."
sleep 3
echo "Below is the Docker response:"
docker swarm init --advertise-addr $ip_addr
# Prompt for secure connection
echo "Continuing in 10 seconds, would you like cancel? (y/n)"
read continue_on
# Prompt for SMTP user and password only if secure connection is used
if [ "$continue_on" == "y" ]; then
    echo "Are you sure you want to cancel? (y/n)"
    read you_sure
        if [ "$you_sure" == "y" ]; then
        exit 1
        fi
fi
echo "Continuing on shortly...."
echo "----------------------------------------------------"

sleep 10

clear

# Prompt for Ghost Image Version
echo "----------------------------------------------------"
echo "Refer to https://hub.docker.com/_/ghost/tags"
echo "----------------------------------------------------"
prompt_and_confirm "Ghost Image Version"

# Replace the entire line 4 with the new image line
sed -i "4c\    image: ghost:$result" ./docker-compose.yml



# Prompt for Ghost Website URL and create Docker secret
prompt_and_confirm "Ghost Website URL" "database__connection__host"
create_secret "database__connection__host" $result
sleep 2
clear

# Prompt for External MySQL configuration
echo "----------------------------------------------------"
echo "External MySQL Configuration"
echo "----------------------------------------------------"
sleep 2


# Prompt for ext. MySQL configuration and create Docker secrets
prompt_and_confirm "Database Connection Hostname" "database__connection__host"
create_secret "database__connection__host" $result

sleep 2
clear

prompt_and_confirm "Database Connection Username" "database__connection__user"
create_secret "database__connection__user" $result 

sleep 2
clear

prompt_and_confirm "Database Connection DB Name" "database__connection__database"
create_secret "database__connection__database" $result

sleep 2
clear

prompt_and_confirm "Database Connection Password" "database__connection__password"
create_secret "database__connection__password" $result

sleep 2
clear

prompt_and_confirm "Database Connection Port" "database__connection__port"
create_secret "database__connection__port" $result

sleep 2
clear

# Prompt for SMTP configuration
echo "----------------------------------------------------"
echo "Email SMTP Configuration"
echo "----------------------------------------------------"
sleep 2
# Prompt for SMTP configuration and create Docker secrets
prompt_and_confirm "Email From Address" "mail_from"
create_secret "mail_from" $result

sleep 2
clear

prompt_and_confirm "Email SMTP host" "mail_options_host"
create_secret "mail_options_host" $result

sleep 2
clear

# Prompt for secure connection
while true; do
    read -p "Does your SMTP use secure connection? (y/n) " mail__options__secure
    if [[ "$mail__options__secure" == "y" || "$mail__options__secure" == "n" ]]; then
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# If secure connection is used, prompt for SMTP user and password and create Docker secrets
if [ "$mail__options__secure" == "y" ]; then
    prompt_and_confirm "Email SMTP user" "mail_options_auth_user"
    create_secret "mail_options_auth_user" $result

    prompt_and_confirm "Email SMTP password" "mail_options_auth_pass"
    create_secret "mail_options_auth_pass" $result
fi

# Create a Docker secret for SMTP secure connection
create_secret "mail_options_secure" $mail__options__secure


sleep 2

clear

# Prompt for SMTP port
prompt_and_confirm "SMTP Port" "mail_options_port"
create_secret "mail_options_port" $result

sleep 2
clear

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
netstat_output=$(netstat -tuln | grep $PORT)
if [[ -z $netstat_output ]]; then
    echo "Port $PORT is open."
else
    echo "Error: Port $PORT is not open. Please check your Docker configuration."
    exit 1
fi
sleep 2
clear

# Deploy Docker stack
docker stack deploy -c docker-compose.yml ghost_stack

# Wait for a few seconds to let the stack start
echo "Waiting for the stack to start..."
sleep 5

# Check if the stack has deployed
stack_services=$(docker stack services ghost_stack)

if [[ $stack_services == *"ghost_stack_ghost"* ]]; then
    echo "Stack has deployed successfully!"
else
    echo "Something went wrong. The stack did not deploy."
    echo "Please check the Docker logs for more information."
    echo "Use the command: docker service logs ghost_stack"
    exit 1
fi

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

# Provide next steps
echo "Your Ghost blog is now running in Docker!"
echo "You can access it at the URL you provided during setup."
echo "To manage your Docker stack, use the following commands:"
echo "- To view the services in your stack, use: docker stack services ghost_stack"
echo "- To view the tasks in your stack, use: docker stack ps ghost_stack"
echo "- To remove your stack, use: docker stack rm ghost_stack"
