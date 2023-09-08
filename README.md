# Ghost Docker Composer

Welcome to Ghost Docker Composer! This project aims to help you set up a Ghost blog in a Docker environment with ease using a shell script. It includes the necessary scripts and configuration files to get your Ghost blog up and running quickly and efficiently.
#### ![#f03c15](https://placehold.co/15x15/f03c15/f03c15.png) *Please Note: This project is currently in development and is not 100% completed yet. Please prepare for errors. however any contributions are greatly appreciated. This is my first public project, thank you for being a part of it!*

This project was made to allow myself to migrate and create production Ghost docker containers with ease. I am still very new to the development world and am appreciative of any suggestions or improvements made to this project.

- Currently being used to run: https://uniskela.space

## Features

- Automated setup and prepartion of Ghost blog in Docker.
- Environment variable configuration for Ghost and MySQL (Internal or External).
- Checks for Docker permissions and netstat availability.
- Checks for open ports.
- Checks if containers and volumes already exist.

## Prerequisites

- This script is optimised for **_Ubuntu 22.04 LTS_**
- [Docker](https://docs.docker.com/engine/install/ubuntu/) and [Docker Compose](https://docs.docker.com/compose/install/linux/#install-using-the-repository) installed on your machine.
- Shell access to the machine where Docker is running.
- [net-tools](https://packages.ubuntu.com/jammy/net-tools) (or the script will try to install via sudo apt)
- External MySQL Database is optional, or run an Internal MySQL database in stack

## Getting Started

1. Clone this repository to your SSH terminal using `git clone https://github.com/uniskela/ghost-docker-composer.git ghost && cd ghost`.
2. You may need to do `sudo chmod +x ./build.sh` then run the build script with `./build.sh`. 
3. This will guide you through the setup process, asking for necessary inputs along the way. The script will check for Docker permissions, create necessary environment variables, and compose the Docker stack.
4. Wait for the script to finish executing. It will check if the Docker stack has deployed and if the services are running successfully.

## Usage

Once the Docker stack is up and running, you can access your Ghost blog at the URL you provided during setup. 

To manage your Docker stack, you can use the following commands:

- To view the services in your stack, use: `docker ps --filter "name=ghost"`
- To view the logs of your stack, use: `docker logs ghost`
- To remove your stack, use: `docker rm -f ghost; docker volume rm ghost_ghost_content`

## Docker Images Used
- Ghost: https://hub.docker.com/_/ghost
- MySQL: https://hub.docker.com/_/mysql

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.

## Acknowledgements

- Thanks to the Ghost team for creating a great blogging platform.
- Thanks to the MySQL for their years of stability and security.
- Thanks to the Docker team for creating an amazing containerization platform.

## Disclaimer

This project is not affiliated with, sponsored by, or endorsed by Ghost or Docker. Use at your own risk. Always make sure to backup your data.