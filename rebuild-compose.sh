#!/bin/bash

# Remove the existing docker-compose.yml file
echo "Removing existing docker-compose.yml file..."
rm -f ./docker-compose.yml
sleep 1

# Copy the template to create a new docker-compose.yml file
echo "Creating a new docker-compose.yml file from template..."
cp ./docker-compose-template.yml ./docker-compose.yml
sleep 1

echo "Done! Your docker-compose.yml file has been refreshed."
