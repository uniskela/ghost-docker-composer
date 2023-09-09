#!/bin/bash
clear
bold=$(tput bold)
underline=$(tput smul)
italic=$(tput sitm)
info=$(tput setaf 2)
error=$(tput setaf 160)
warn=$(tput setaf 214)
reset=$(tput sgr0)

# Welcome message
echo "----------------------------------------------------"
echo "Welcome to the Ghost blog Docker composer!"
echo "${italic}Built by Uniskela: https://github.com/uniskela/ghost-docker-composer${reset}"
echo "----------------------------------------------------"
sleep 5


clear
# Check if user has Docker installed
echo "----------------------------------------------------"
echo "Checking Docker installation...."
sleep 2
if ! command -v docker &> /dev/null; then
    echo "Docker Engine is not installed."
    echo "Please follow Docker's installation instructions:"
    echo "https://docs.docker.com/engine/install/ubuntu/#installation-methods"
    echo "----------------------------------------------------"
    exit 1
else
    echo "Docker is installed."
fi

# Check if direnv is installed
echo "----------------------------------------------------"
echo "Checking direnv installation...."
sleep 2
if ! command -v direnv &> /dev/null; then
    echo "direnv is not installed."
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
        echo "direnv installed successfully!"
    else
        echo "Please follow direnv's installation instructions:"
        echo "https://direnv.net/docs/installation.html"
        echo "----------------------------------------------------"
        exit 1
    fi
else
    echo "direnv is installed."
    echo "----------------------------------------------------"
fi




# Add checks for other packages here...

echo "Done! Continuing on..."
echo "----------------------------------------------------"
sleep 5
clear



# Ask the user for confirmation before removing the existing docker-compose.yml and prod/.envrc files
echo "----------------------------------------------------"
warn=$(tput setaf 214)
reset=$(tput sgr0)
echo "${warn}##!!Please be aware!!##${reset}"
echo "This will remove any existing docker-compose.yml and"
echo "prod/.envrc files from this directory."
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
    cp ./template.yml ./docker-compose.yml
    sleep 1

    # Create a new prod/.envrc file
    echo "Creating a new prod/.envrc file..."
    touch ./prod/.envrc
    sleep 1

    echo "Done! Your docker-compose.yml and prod/.envrc files have been refreshed."
else
    echo "Operation cancelled. Your docker-compose.yml and prod/.envrc files have not been changed."
    echo "----------------------------------------------------"
    exit 1
fi
echo "----------------------------------------------------"
sleep 3




# Function to prompt for user input and confirm
prompt_and_confirm() {
    local prompt_string=$1
    local env_var_name=$2

    # Check if the environment variable is already set
    if grep -q "$env_var_name" prod/.envrc; then
        echo "----------------------------------------------------"
        echo "The environment variable $env_var_name is already set to $(grep "$env_var_name" prod/.envrc | cut -d '=' -f2-)."
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
            echo "$env_var_name set successfully!"
            echo "----------------------------------------------------"
            sleep 3
            clear
            break
        fi
    done
}



clear
# Prompt for Ghost Image Version
prompt_and_confirm "Ghost Image Version" "GHOST_IMAGE_VERSION"
echo "----------------------------------------------------"
echo "To ensure you enter the correct value, please" 
echo "refer to: https://hub.docker.com/_/ghost/tags"

# Replace the entire line 4 with the new image line
sed -i "5c\    image: ghost:${GHOST_IMAGE_VERSION}" ./docker-compose.yml

# Prompt for Ghost Website URL and create Docker secret
prompt_and_confirm "Ghost Website URL" "database__connection__host"

# Prompt for MySQL configuration type
echo "----------------------------------------------------"
echo "MySQL Configuration"
echo "----------------------------------------------------"
echo "Please choose the type of MySQL configuration:"
echo "1. Internal"
echo "2. External"
read -r -p "Enter your choice (1 or 2): " choice

if [[ "$choice" == "1" ]]; then
    # Uncomment MySQL service and volume in template.yml using sed
    sed -i '/#  mysql:/,/  mysql_data:/ { s/^#  // }' ./template.yml
    sed -i '/#  mysql_data:/ { s/^#  // }' ./template.yml

    # Add the necessary indentation back in
    sed -i '/mysql:/,/mysql_data:/ { s/^/  / }' ./template.yml

    # Correct the indentation for the mysql_data volume
    sed -i '/mysql_data:/ { s/^/  / }' ./template.yml
fi


    # Prompt for internal MySQL configuration
    echo "----------------------------------------------------"
    echo "Internal MySQL Configuration"
    echo "----------------------------------------------------"
    prompt_and_confirm "MySQL Root Password" "MYSQL_ROOT_PASSWORD"
    prompt_and_confirm "MySQL Database" "MYSQL_DATABASE"
    # Record the database name for the ghost database connection
    export DATABASE_CONNECTION_DATABASE=$MYSQL_DATABASE
    prompt_and_confirm "MySQL User" "MYSQL_USER"
    # Record the user for the ghost database connection
    export DATABASE_CONNECTION_USER=$MYSQL_USER
    prompt_and_confirm "MySQL Password" "MYSQL_PASSWORD"
    # Record the password for the ghost database connection
    export DATABASE_CONNECTION_PASSWORD=$MYSQL_PASSWORD
    # Set the hostname and port for the ghost database connection
    export DATABASE_CONNECTION_HOST="mysql"
    export DATABASE_CONNECTION_PORT="3306"
elif [[ "$choice" == "2" ]]; then
    # Prompt for external MySQL configuration
    echo "----------------------------------------------------"
    echo "External MySQL Configuration"
    echo "----------------------------------------------------"
    prompt_and_confirm "Database Connection Hostname" "DATABASE_CONNECTION_HOST"
    prompt_and_confirm "Database Connection Username" "DATABASE_CONNECTION_USER"
    prompt_and_confirm "Database Connection DB Name" "DATABASE_CONNECTION_DATABASE"
    prompt_and_confirm "Database Connection Password" "DATABASE_CONNECTION_PASSWORD"
    prompt_and_confirm "Database Connection Port" "DATABASE_CONNECTION_PORT"
else
    echo "Invalid choice. Please enter 1 for Internal or 2 for External."
    exit 1
fi


# Prompt for SMTP configuration
echo "----------------------------------------------------"
echo "Email SMTP Configuration"
echo "----------------------------------------------------"
sleep 2
# Prompt for SMTP configuration and create Docker secrets
prompt_and_confirm "Email From Address" "mail_from"

sleep 2
clear

prompt_and_confirm "Email SMTP host" "mail_options_host"

sleep 2
clear

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
    prompt_and_confirm "Email SMTP user" "mail_options_auth_user"

    prompt_and_confirm "Email SMTP password" "mail_options_auth_pass"
fi


sleep 2

clear

# Prompt for SMTP port
prompt_and_confirm "SMTP Port" "mail_options_port"

sleep 2
clear
# Check if netstat is installed
echo "----------------------------------------------------"
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
echo "Done! Continuing on..."
echo "----------------------------------------------------"
sleep 3 
clear
# Function to prompt for port number and check if it's open
prompt_for_port() {
    while true; do
        echo "Please enter a port number for Ghost:"
        read -r PORT

        netstat_output=$(netstat -tuln | grep "$PORT")
        if [[ -z $netstat_output ]]; then
            echo "Port $PORT is open."
            break
        else
            echo "Error: Port $PORT is not open. Please try another port."
        fi
    done
}

echo "----------------------------------------------------"
echo "Preparing Ghost options..."
sleep 2

prompt_for_port


echo "Done! Continuing on..."
echo "----------------------------------------------------"
sleep 3 
clear

echo "----------------------------------------------------"
echo "Checking if containers and volumes already exist..."
sleep 2

# Check if 'ghost' container already exists
ghost_container=$(docker ps -a --filter "name=ghost" --format '{{.Names}}')
if [[ $ghost_container == *"ghost"* ]]; then
    echo "The 'ghost' container already exists."
    read -r -p "Would you like to stop and remove it? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        docker stop ghost
        docker rm ghost
    else
        echo "Cannot proceed with the 'ghost' container already existing. Exiting."
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
        echo "Cannot proceed with the 'ghost_ghost_content' volume already existing. Exiting."
        exit 1
    fi
fi

echo "Done! Continuing on..."
echo "----------------------------------------------------"
sleep 3 
clear


echo "----------------------------------------------------"
echo "Loding direnv variables..."
sleep 2

cd prod
direnv allow

echo "Attempting to compose Docker..."
sleep 2


# Deploy Docker stack
docker compose --env-file .envrc up -d --name ghost

# Wait for a few seconds to let the stack start
echo "Waiting for the container to start..."
sleep 5

# Check if the stack has deployed
stack_services=$(docker ps --filter "name=ghost")

if [[ $stack_services == *"ghost"* ]]; then
    echo "Stack has deployed successfully!"
else
    echo "Something went wrong. The stack did not deploy."
    echo "Please check the Docker logs for more information."
    echo "Use the command: docker logs ghost"
    exit 1
fi

# Check if containers are running
service_state=$(docker ps --filter "name=ghost" --format '{{.State}}')

if [[ $service_state == *"Up"* ]]; then
    echo "Containers are running successfully!"
else
    echo "Something went wrong. The service is not running."
    echo "Service state: $service_state"
    echo "Please check the Docker logs for more information."
    echo "Use the command: docker logs ghost"
fi

# Provide next steps
echo "Your Ghost blog is now running in Docker!"
echo "You can access it at the URL you provided during setup."
echo "To manage your Docker stack, use the following commands:"
echo "- To view the services in your stack, use: docker ps --filter \"name=ghost\""
echo "- To view the logs of your stack, use: docker logs ghost"
echo "- To remove your stack, use: docker rm -f ghost; docker volume rm ghost_ghost_content"
