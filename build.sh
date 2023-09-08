#!/bin/bash
clear
# Remove the existing docker-compose.yml file
echo "----------------------------------------------------"
echo "Removing existing docker-compose.yml file..."
rm -f ./docker-compose.yml
sleep 1

# Copy the template to create a new docker-compose.yml file
echo "Creating a new docker-compose.yml file from template..."
cp ./docker-compose-template.yml ./docker-compose.yml
sleep 1

echo "Done! Your docker-compose.yml file has been refreshed."
echo "----------------------------------------------------"
sleep 3
clear
# Function to prompt for user input and confirm
prompt_and_confirm() {
    local prompt_string=$1
    local env_var_name=$2

    # Check if the environment variable is already set
    if [ ! -z "${!env_var_name}" ]; then
        echo "----------------------------------------------------"
        echo "The environment variable $env_var_name is already set to ${!env_var_name}."
        echo "Would you like to keep this value? (y/n, or press Enter to confirm)"
        read confirm
        if [ "$confirm" == "y" ] || [ -z "$confirm" ]; then
            return
            clear
            echo "----------------------------------------------------"
            echo "$env_var_name set successfully!"
            echo "----------------------------------------------------"
            sleep 3
            clear
        fi
    fi

    while true; do
        echo "----------------------------------------------------" 
        echo "Please enter your $prompt_string:"
        read var

        echo "----------------------------------------------------"
        echo "You entered: $var"
        echo "Is this correct? (y/n, or press Enter to confirm)"
        read confirm
        if [ "$confirm" == "y" ] || [ -z "$confirm" ]; then
            export $env_var_name=$var
            break
            clear
            echo "----------------------------------------------------"
            echo "$env_var_name set successfully!"
            echo "----------------------------------------------------"
            sleep 3
            clear
        fi
                clear
            echo "----------------------------------------------------"
            echo "$env_var_name set successfully!"
            echo "----------------------------------------------------"
            sleep 3
            clear
    done
}




# Check if user has Docker permissions
echo "----------------------------------------------------"
echo "Checking Docker permissions...."
sleep 2
if ! docker info >/dev/null 2>&1; then
    echo "You do not have sufficient Docker permissions."
    echo "Attempting to add user to Docker group..."
    sleep 1
    
    # Attempt to add user to Docker group
    sudo usermod -aG docker $USER
    
    echo "You may need to log out and log back in to apply these changes."
    sleep 3
    exit 1
fi
echo "Done! Continuing on..."
echo "----------------------------------------------------"
sleep 3


clear
# Welcome message
clear
echo "----------------------------------------------------"
echo "Welcome to the Ghost blog Docker composer!"
echo "Built by Uniskela at https://github.com/uniskela/ghost-docker-composer"
echo "----------------------------------------------------"
sleep 5


clear
# Prompt for Ghost Image Version
echo "## Refer to https://hub.docker.com/_/ghost/tags"
prompt_and_confirm "Ghost Image Version" "GHOST_IMAGE_VERSION"

# Replace the entire line 4 with the new image line
sed -i "5c\    image: ghost:${GHOST_IMAGE_VERSION}" ./docker-compose.yml
   clear
    echo "----------------------------------------------------"
    echo "Ghost Image Version set successfully!"
    echo "----------------------------------------------------"
    sleep 3
    clear


# Prompt for Ghost Website URL and create Docker secret
prompt_and_confirm "Ghost Website URL" "database__connection__host"

   clear
    echo "----------------------------------------------------"
    echo "Ghost Website URL set successfully!"
    echo "----------------------------------------------------"
    sleep 3
    clear

# Prompt for MySQL configuration type
echo "----------------------------------------------------"
echo "MySQL Configuration"
echo "----------------------------------------------------"
echo "Please choose the type of MySQL configuration:"
echo "1. Internal"
echo "2. External"
read -p "Enter your choice (1 or 2): " choice

if [[ "$choice" == "1" ]]; then
    # Uncomment MySQL service and volume in docker-compose.yml using sed
    sed -i '/#  mysql:/,/  mysql_data:/ { s/^#  // }' ./docker-compose.yml
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
        read PORT

        netstat_output=$(netstat -tuln | grep $PORT)
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
    read -p "Would you like to stop and remove it? (y/n): " confirm
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
    read -p "Would you like to remove it? (y/n): " confirm
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
echo "Attempting to compose Docker..."
sleep 2
# Deploy Docker stack
docker-compose up -d --name ghost

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
