#!/bin/bash
clear
bold=$(tput bold)
underline=$(tput smul)
info=$(tput setaf 2)
error=$(tput setaf 160)
warn=$(tput setaf 214)
reset=$(tput sgr0)

# Welcome message
echo "----------------------------------------------------"
echo "${bold}Welcome to the Ghost blog Docker composer!${reset}"
echo "${underline}https://github.com/uniskela/ghost-docker-composer${reset}"
echo ""
echo "${warn}Please note: This project is currently in development.${reset}"
echo "----------------------------------------------------"
sleep 5


clear
# Check if user has Docker installed
echo "----------------------------------------------------"
echo "Checking Docker installation...."
sleep 2
if ! command -v docker &> /dev/null; then
    echo "${error}Docker Engine is not installed.${reset}"
    echo "Please follow Docker's installation instructions:"
    echo "https://docs.docker.com/engine/install/ubuntu/#installation-methods"
    echo "----------------------------------------------------"
    exit 1
else
    echo "${info}Docker is installed.${reset}"
fi

# Check if direnv is installed
echo "----------------------------------------------------"
echo "Checking direnv installation...."
sleep 2
if ! command -v direnv &> /dev/null; then
    echo "${warn}direnv is not installed.${reset}"
    echo "Would you like to install it now (via sudo apt-get)? (y/n)"
    read -r confirm
    if [ "$confirm" == "y" ]; then
        echo "Installing direnv..."
        sudo apt-get update
        sudo apt-get install direnv
        echo "eval \"\$(direnv hook bash)\"" >> "$HOME/.bashrc"
        # Use the $HOME environment variable to get the home directory of the current user
        if [ -f "$HOME/.bashrc" ]; then
            # shellcheck disable=SC1091
            source "$HOME/.bashrc"
        else
            echo "$HOME/.bashrc does not exist"
        fi
        echo "${info}direnv installed successfully!${reset}"
    else
        echo "${error}direnv is not installed.${reset}"
        echo "Please follow direnv's installation instructions:"
        echo "https://direnv.net/docs/installation.html"
        echo "----------------------------------------------------"
        exit 1
    fi
else
    echo "${info}direnv is installed.${reset}"
    echo "----------------------------------------------------"
fi
# Check if netstat is installed
echo "Checking for netstat...."
sleep 2
# Check if netstat is installed
if ! command -v netstat &> /dev/null
then
    echo "netstat could not be found. Installing net-tools..."
    # Update package lists
    sudo apt-get update
    # Install net-tools
    sudo apt-get install -y net-tools
fi
    echo "${info}net-tools is installed.${reset}"
    echo "----------------------------------------------------"
sleep 3 
clear



# Ask the user for confirmation before removing the existing docker-compose.yml and prod/.envrc files
echo "----------------------------------------------------"
warn=$(tput setaf 214)
reset=$(tput sgr0)
echo "${warn}##!!Please be aware!!##${reset}"
echo "This will remove any existing docker-compose.yml and prod/.envrc files from this directory."
read -r -p "Are you sure you want to continue? [y/N] " response
echo "----------------------------------------------------"
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    clear
    echo "----------------------------------------------------"
    echo "Removing existing docker-compose.yml and prod/.envrc files..."
    rm -f ./docker-compose.yml
    rm -f ./prod/.envrc
    sleep 1

    # Check if the prod directory exists, if not create it
    if [ ! -d "prod" ]; then
      mkdir prod
    fi

    # Copy the template to create a new docker-compose.yml file
    echo "Creating a new docker-compose.yml file from template..."
    cp ./template ./docker-compose.yml
    sleep 1

    # Create a new prod/.envrc file
    echo "Creating a new prod/.envrc file..."
    touch ./prod/.envrc
    sleep 1

    echo "${info}Done! Your docker-compose.yml and prod/.envrc files have been refreshed.${reset}"
else
    echo "${error}Operation cancelled. Your docker-compose.yml and prod/.envrc files have not been changed.${reset}"
    echo "If you would like to continue, please backup your directory."
    echo "----------------------------------------------------"
    exit 1
fi
echo "----------------------------------------------------"
sleep 3




# Function to prompt for user input and confirm
addenv() {
    local prompt_string=$1
    local env_var_name=$2

    # Check if the environment variable is already set
    if grep -q "$env_var_name" prod/.envrc; then
        echo "----------------------------------------------------"
        echo "${warn}The environment variable $env_var_name is already set to $(grep "$env_var_name" prod/.envrc | cut -d '=' -f2-).${reset}"
        echo "Would you like to keep this value? (y/n, or press Enter to confirm)"
        read -r confirm
        if [ "$confirm" == "y" ] || [ -z "$confirm" ]; then
            return
        fi
    fi

    while true; do
        echo "----------------------------------------------------"
        echo "Please enter your $prompt_string:"
        read -r var
        echo "----------------------------------------------------"
        echo "You entered: $var"
        echo "Is this correct? (y/n, or press Enter to confirm)"
        read -r confirm
        if [ "$confirm" == "y" ] || [ -z "$confirm" ]; then
            echo "----------------------------------------------------"
            echo "export $env_var_name=$var" >> prod/.envrc
            echo "${info}$env_var_name set successfully!${reset}"
            echo "----------------------------------------------------"
            sleep 3
            clear
            break
        fi
    done
}



clear
# Prompt for Ghost Image Version
echo "----------------------------------------------------"
echo "${warn}To ensure you enter the correct value, please" 
echo "refer to: https://hub.docker.com/_/ghost/tags${reset}"
addenv "Ghost Image Version" "GHOST_IMAGE_VERSION"

# Allow direnv to load the .envrc file
# shellcheck disable=SC2164
cd prod
direnv allow .
# shellcheck disable=SC2103
cd ..

# Source the prod/.envrc file to load the GHOST_IMAGE_VERSION variable
# shellcheck disable=SC1091
source prod/.envrc

# Replace the entire line 4 with the new image line
sed -i "5c\    image: ghost:${GHOST_IMAGE_VERSION}" ./docker-compose.yml


while true; do
    # Prompt for MySQL configuration type
    echo "----------------------------------------------------"
    echo "${underline}MySQL Configuration${reset}"
    echo "----------------------------------------------------"
    echo "Please choose the type of MySQL configuration:"
    echo "1. Internal"
    echo "2. External"
    read -r -p "Enter your choice (1 or 2): " choice

    if [[ "$choice" == "1" ]]; then
    # Uncomment MySQL service in docker-compose.yml using sed
    sed -i '/#  db:/,/#  db:/ s/^#  //' ./docker-compose.yml
    # Correct the indentation for the db volume
    sed -i '/db:/ { s/^/  / }' ./docker-compose.yml

    # Add data volume to the volumes section in docker-compose.yml
    sed -i '/ghost_content:/a \  data:' ./docker-compose.yml

        # Prompt for internal MySQL configuration
        clear
        echo "----------------------------------------------------"
        echo "${underline}Internal MySQL Configuration${reset}"
        echo "----------------------------------------------------"
        addenv "MySQL Root Password" "MYSQL_ROOT_PASSWORD"
        addenv "MySQL Database" "MYSQL_DATABASE"
        addenv "MySQL User" "MYSQL_USER"
        addenv "MySQL Password" "MYSQL_PASSWORD"
        # Add the DATABASE_CONNECTION_HOST and DATABASE_CONNECTION_PORT environment variables to prod/.envrc
        echo "----------------------------------------------------"
        echo "Including additional env variables for Ghost..."

        # Allow direnv to load the .envrc file
        # shellcheck disable=SC2164
        cd prod
        direnv allow .
        # shellcheck disable=SC2103
        cd ..

        # shellcheck disable=SC1091
        source prod/.envrc


        {
            echo "export DATABASE_CONNECTION_HOST=db"
            echo "export DATABASE_CONNECTION_USER=$MYSQL_USER"
            echo "export DATABASE_CONNECTION_DATABASE=$MYSQL_DATABASE"
            echo "export DATABASE_CONNECTION_PASSWORD=$MYSQL_PASSWORD"
            echo "export DATABASE_CONNECTION_PORT=3306"
        } >> prod/.envrc

        # shellcheck disable=SC1091
        source prod/.envrc  


        break
    elif [[ "$choice" == "2" ]]; then
        # Prompt for external MySQL configuration
        clear
        echo "----------------------------------------------------"
        echo "${underline}External MySQL Configuration${reset}"
        echo "----------------------------------------------------"
        addenv "Database Connection Hostname" "DATABASE_CONNECTION_HOST"
        addenv "Database Connection Username" "DATABASE_CONNECTION_USER"
        addenv "Database Connection DB Name" "DATABASE_CONNECTION_DATABASE"
        addenv "Database Connection Password" "DATABASE_CONNECTION_PASSWORD"
        addenv "Database Connection Port" "DATABASE_CONNECTION_PORT"
        break
    else
        echo "Invalid choice. Please enter 1 for Internal or 2 for External."
    fi
done


    echo "----------------------------------------------------"
    echo "${info}Database Configuration Complete!${reset}"
    echo "----------------------------------------------------"
    sleep 2
    clear

# Prompt for SMTP configuration
echo "----------------------------------------------------"
echo "${underline}Email SMTP Configuration${reset}"
echo "----------------------------------------------------"
sleep 2
# Prompt for SMTP configuration and create Docker secrets
addenv "Email From Address" "mail_from"

addenv "Email SMTP host" "mail_options_host"

# Prompt for SMTP port
addenv "SMTP Port" "mail_options_port"

# Prompt for secure connection
while true; do
    read -r -p "Does your SMTP use secure connection? (y/n) " mail__options__secure
    if [[ "$mail__options__secure" == "y" || "$mail__options__secure" == "n" ]]; then
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# If secure connection is used, prompt for SMTP user and password and create Docker secrets
if [ "$mail__options__secure" == "y" ]; then
    addenv "Email SMTP user" "mail_options_auth_user"

    addenv "Email SMTP password" "mail_options_auth_pass"
fi


sleep 2

clear



echo "----------------------------------------------------"
echo "${info}SMTP Configuration Complete!${reset}"
echo "----------------------------------------------------"
sleep 2
clear

# Function to prompt for port number and check if it's open
prompt_for_port() {
    while true; do
        echo "Please enter a port number for Ghost:"
        read -r PORT

        netstat_output=$(netstat -tuln | grep "$PORT")
        if [[ -z $netstat_output ]]; then
            echo "${info}Port $PORT is open.${reset}"
            break
        else
            echo "${warn}Error: Port $PORT is not open. Please try another port."
        fi
    done
}


echo "----------------------------------------------------"
echo "${underline}Ghost Setup Configuration${reset}"
echo "----------------------------------------------------"
sleep 2

prompt_for_port

addenv "Admin URL" "admin_url"

echo "----------------------------------------------------"
echo "${info}Ghost Configuration Complete!${reset}"
echo "----------------------------------------------------"
sleep 2
clear

echo "----------------------------------------------------"
echo "Checking if containers and volumes already exist..."
sleep 2



# Check if 'ghost' container already exists
ghost_container=$(docker ps -a --filter "name=ghost" --format '{{.Names}}')
if [[ $ghost_container == *"ghost"* ]]; then
    echo "${warn}The 'ghost' container already exists.${reset}"
    read -r -p "Would you like to stop and remove it? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        docker stop ghost
        docker rm ghost
    else
        echo "${error}Cannot proceed with the 'ghost' container already existing. Exiting.${reset}"
        exit 1
    fi
fi

# Check if 'ghost_ghost_content' volume already exists
ghost_volume=$(docker volume ls --filter "name=ghost_ghost_content" --format '{{.Name}}')
if [[ $ghost_volume == *"ghost_ghost_content"* ]]; then
    echo "The 'ghost_ghost_content' volume already exists."
    read -r -p "Would you like to remove it? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        docker volume rm ghost_ghost_content
    else
        echo "${error}Cannot proceed with the 'ghost_ghost_content' volume already existing. Exiting.${reset}"
        exit 1
    fi
fi

echo "${info}Done! Continuing on...${reset}"
echo "----------------------------------------------------"
sleep 3 
clear


echo "----------------------------------------------------"
echo "Loding direnv variables..."
sleep 2

# Allow direnv to load the .envrc file
# shellcheck disable=SC2164
cd prod
direnv allow .
# shellcheck disable=SC2103
cd ..

echo "Attempting to compose Docker..."
sleep 2


# Deploy Docker stack
docker compose up -d ghost

# Wait for a few seconds to let the stack start
echo "Waiting for the container to start..."
sleep 5
clear

echo "----------------------------------------------------"
echo "Checking container deployment status"
echo "----------------------------------------------------"
sleep 2

# Check if the stack has deployed
stack_services=$(docker ps --filter "name=ghost")

if [[ $stack_services == *"ghost"* ]]; then
    echo "${info}Stack has deployed successfully!${error}"
else
    echo "${error}Something went wrong. The stack did not deploy.${reset}"
    echo "Please check the Docker logs for more information."
    echo "Use the command: docker logs ghost"
    exit 1
fi

# Check if containers are running
service_state=$(docker ps --filter "name=ghost" --format '{{.State}}')

if [[ $service_state == *"Up"* ]]; then
    echo "${info}Containers are running successfully!${reset}"
else
    echo "${error}Something went wrong. The service is not running.${reset}"
    echo "Service state: $service_state"
    echo "Please check the Docker logs for more information."
    echo "Use the command: docker logs ghost"
    exit 1
fi

# Provide next steps
echo "${info}Your Ghost blog is now running in Docker!"
echo "You can access it at the URL you provided during setup."
echo "To manage your Docker stack, use the following commands:"
echo "- To view the services in your stack, use: docker ps --filter \"name=ghost\""
echo "- To view the logs of your stack, use: docker logs ghost"
echo "- To remove your stack, use: docker rm -f ghost; docker volume rm ghost_ghost_content"
