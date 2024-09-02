# GSSHBZ-RESTAPI

## Overview

This project is a backend REST API built with Vapor and Swift for the GSS HBŽ search and rescue organization in Bosnia and Herzegovina. The API is designed to manage and streamline the digital armory system, handling equipment leasing, inventory management, and tracking.

## Prerequisites

Before you begin, make sure you have the following installed on your local machine:

- **Swift**: The programming language used for this project. You can download and install Swift from the [official Swift website](https://swift.org/download/).
- **Docker**: For creating and managing containers. You can download and install Docker from the [official Docker website](https://www.docker.com/products/docker-desktop).

## Installation

### Install Swift

1. Visit the [Swift downloads page](https://swift.org/download/).
2. Download and install the latest stable release for your operating system.
3. Follow the instructions provided on the Swift website to complete the installation.

### Install Vapor

1. Open your terminal.
2. Install Vapor using the Swift Package Manager with the following command:

   ```sh
   brew install vapor

Once Vapor is installed, you can use the vapor command to manage your Vapor projects.

### Create Docker Container for Local Testing

    Open your terminal.

    Run the following command to create and start a PostgreSQL container:

    sh

    docker run --name gsshbz-test-environment \
      -e POSTGRES_DB=gsshbz_database \
      -e POSTGRES_USER=gsshbz_username \
      -e POSTGRES_PASSWORD=gsshbz_password \
      -p 5436:5432 \
      -d postgres

    This command sets up a PostgreSQL container with the necessary environment variables and maps port 5432 in the container to port 5436 on your host machine.

Start the Vapor Project

    Navigate to the project directory in your terminal:

    cd path/to/your/project

Build and run the Vapor project with the following command:

    vapor run

This will start the Vapor server, and you should be able to access the API at http://localhost:8080.
