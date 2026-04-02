# GSSHBZ-RESTAPI

## Overview

This project is a backend REST API built with Vapor and Swift for the GSS HBŽ search and rescue organization in Bosnia and Herzegovina. The API is designed to manage and streamline the digital armory system, handling equipment leasing, inventory management, and tracking.

---

## Prerequisites

Before you begin, make sure you have the following installed on your local machine:

- **Swift**: The programming language used for this project. You can download and install Swift from the [official Swift website](https://swift.org/download/).
- **Docker**: For creating and managing containers. You can download and install Docker from the [official Docker website](https://www.docker.com/products/docker-desktop).

---

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
   ```

Once Vapor is installed, you can use the `vapor` command to manage your Vapor projects.

### Create Docker Container for Local Testing

1. Open your terminal.
2. Run the following command to create and start a PostgreSQL container:

   ```sh
   docker run --name gsshbz-test-environment \
     -e POSTGRES_DB=gsshbz_database \
     -e POSTGRES_USER=gsshbz_username \
     -e POSTGRES_PASSWORD=gsshbz_password \
     -p 5436:5432 \
     -d postgres
   ```

   This command sets up a PostgreSQL container with the necessary environment variables and maps port 5432 in the container to port 5436 on your host machine.

### Start the Vapor Project

1. Navigate to the project directory in your terminal:

   ```sh
   cd path/to/your/project
   ```

2. Build and run the Vapor project with the following command:

   ```sh
   vapor run
   ```

This will start the Vapor server, and you should be able to access the API at `http://localhost:8080`.

---

## Security Setup

### Generating `keypair.jwks`

The application loads a JWKS (JSON Web Key Set) file to sign and verify JWTs. The file path is resolved from the app's working directory and can be overridden via the `JWKS_KEYPAIR_FILE` environment variable. The JWKS is only loaded outside of the `.testing` environment.

#### Step 1 — Generate an RSA private key

```sh
openssl genrsa -out private.pem 2048
```

#### Step 2 — Extract the public key

```sh
openssl rsa -in private.pem -pubout -out public.pem
```

#### Step 3 — Convert to JWKS format

Create a file named `generate-jwks.js` and run it with Node.js:

```js
const { createPrivateKey } = require('crypto');
const fs = require('fs');

const pem = fs.readFileSync('private.pem', 'utf8');
const key = createPrivateKey(pem);
const jwk = key.export({ format: 'jwk' });

jwk.kid = 'gsshbz-key';
jwk.use = 'sig';
jwk.alg = 'RS256';

const jwks = { keys: [jwk] };
fs.writeFileSync('keypair.jwks', JSON.stringify(jwks, null, 2));
console.log('keypair.jwks generated successfully.');
```

```sh
node generate-jwks.js
```

#### Step 4 — Place the file in the project root

By default, the app looks for `keypair.jwks` in the working directory (project root). You can override this by setting the `JWKS_KEYPAIR_FILE` environment variable to a custom relative path:

```sh
# Default — no env var needed, the app will load:
# <workingDirectory>/keypair.jwks

# Custom path example
export JWKS_KEYPAIR_FILE=Resources/my-custom-keypair.jwks
```

#### Expected `keypair.jwks` structure

```json
{
  "keys": [
    {
      "kty": "RSA",
      "kid": "gsshbz-key",
      "use": "sig",
      "alg": "RS256",
      "n": "<base64url-modulus>",
      "e": "AQAB",
      "d": "<base64url-private-exponent>",
      "p": "<base64url-prime1>",
      "q": "<base64url-prime2>"
    }
  ]
}
```

> ⚠️ **Never commit `keypair.jwks` or any `.pem` files to version control.** Add them to `.gitignore` immediately.

---

## Database Configuration

The app connects to a PostgreSQL database. Configuration is driven entirely by environment variables, with fallback defaults for local development.

| Environment Variable | Default (local) | Description |
|---|---|---|
| `DATABASE_HOST` | `localhost` | PostgreSQL host |
| `DATABASE_PORT` | `5436` | PostgreSQL port |
| `DATABASE_USERNAME` | `gsshbz_username` | Database user |
| `DATABASE_PASSWORD` | `gsshbz_password` | Database password |
| `DATABASE_NAME` | `gsshbz_database` | Database name |

TLS is disabled for the database connection (`tls: .disable`). In production on fly.io, database connectivity is handled via fly.io's internal private network, so TLS at the database connection level is not required.

---

## Deployment (fly.io)

This API is deployed on [fly.io](https://fly.io). fly.io automatically handles HTTPS/TLS termination at the edge, so no certificate configuration is needed inside the Vapor app itself.

### Setting secrets on fly.io

Set your environment variables as fly.io secrets:

```sh
fly secrets set DATABASE_HOST=your-db-host
fly secrets set DATABASE_PORT=5432
fly secrets set DATABASE_USERNAME=your-db-user
fly secrets set DATABASE_PASSWORD=your-db-password
fly secrets set DATABASE_NAME=your-db-name
```

---

## Environment Variables Summary

| Variable | Required | Description |
|---|---|---|
| `JWKS_KEYPAIR_FILE` | No | Path to `keypair.jwks` (defaults to `keypair.jwks` in working directory) |
| `DATABASE_HOST` | Yes (prod) | PostgreSQL hostname |
| `DATABASE_PORT` | No | PostgreSQL port (default: `5436` locally) |
| `DATABASE_USERNAME` | Yes (prod) | Database username |
| `DATABASE_PASSWORD` | Yes (prod) | Database password |
| `DATABASE_NAME` | Yes (prod) | Database name |

---

## .gitignore Recommendations

```
*.pem
*.key
*.csr
keypair.jwks
.env
```
