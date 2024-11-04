#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Ask the user for the resource directory location
read -p "Enter the resource directory location or press Enter to use default (/var/www/SwiftHTTPServer): " resource_dir
resource_dir=${resource_dir:-/var/www/SwiftHTTPServer}
export RESOURCE_DIR="/var/www/SwiftHTTPServer"

echo -e "${GREEN}Using resource directory: ${resource_dir}${RESET}"

# Ask the user to choose the build configuration
read -p "Choose the build configuration (release/debug, default is debug): " build_type
build_type=${build_type:-debug}

# Validate the build type
if [[ "${build_type}" != "release" && "${build_type}" != "debug" ]]; then
    echo -e "${RED}Invalid build type specified. Please choose either 'release' or 'debug'. Exiting...${RESET}"
    exit 1
fi

echo -e "${GREEN}Using build configuration: ${build_type}${RESET}"

# Step 1: Build the project
echo -e "${GREEN}Building the Swift HTTP Server in ${build_type} mode...${RESET}"
swift build -c ${build_type}

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed. Exiting...${RESET}"
    exit 1
fi
echo -e "${GREEN}Build successful.${RESET}"

# Step 2: Move the executable to /usr/local/bin
echo -e "${GREEN}Moving the executable to /usr/local/bin...${RESET}"
sudo mv .build/${build_type}/SwiftHTTPServer /usr/local/bin/

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to move the executable. Exiting...${RESET}"
    exit 1
fi
echo -e "${GREEN}Executable moved to /usr/local/bin.${RESET}"

# Step 3: Create the resources directory if it doesn't exist
echo -e "${GREEN}Creating ${resource_dir} directory if it doesn't exist...${RESET}"
if [ ! -d "${resource_dir}" ]; then
    sudo mkdir -p "${resource_dir}"
    echo -e "${GREEN}${resource_dir} directory created.${RESET}"
else
    echo -e "${GREEN}${resource_dir} directory already exists.${RESET}"
    echo -e "${GREEN}Removing old files from ${resource_dir}.${RESET}"
    sudo rm -rf ${resource_dir}/*
fi

# Step 4: Set the correct permissions for the resources directory
echo -e "${GREEN}Setting permissions for ${resource_dir}...${RESET}"
sudo chown -R $USER:$USER "${resource_dir}"
sudo chmod -R 755 "${resource_dir}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to set permissions. Exiting...${RESET}"
    exit 1
fi
echo -e "${GREEN}Permissions set for ${resource_dir}.${RESET}"

# Copy resources
echo -e "${GREEN}Copying resource files to ${resource_dir}...${RESET}"
sudo cp -r Resources/* ${resource_dir}

# Step 5: Add the server to the system PATH (if necessary)
if ! command -v SwiftHTTPServer &> /dev/null; then
    echo -e "${GREEN}Adding SwiftHTTPServer to the system PATH...${RESET}"
    sudo ln -s /usr/local/bin/SwiftHTTPServer /usr/bin/SwiftHTTPServer
    echo -e "${GREEN}SwiftHTTPServer added to the system PATH.${RESET}"
else
    echo -e "${GREEN}SwiftHTTPServer is already in the system PATH.${RESET}"
fi

# Step 6: Move config to /etc/SwiftHTTPServer/config.json
sudo mkdir /etc/SwiftHTTPServer
sudo cp Sources/SwiftHTTPServer/config.json /etc/SwiftHTTPServer/config.json

# Final message to the user
echo -e "${GREEN}Setup complete! You can now run the server by using the following command:${RESET}"
echo -e "${GREEN}  SwiftHTTPServer run${RESET}"

