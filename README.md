# Traefik 3.x Reverse Proxy with Step-CA for Local HTTPS
 
This project sets up a robust local reverse proxy environment using Traefik 3.x and Step-CA to issue and manage valid HTTPS certificates for development domains (e.g., `.test`, `.local`). This setup is ideal for local development and especially recommended for **WSL2 (Windows Subsystem for Linux)** environments.
 
 ⚠️ SECURITY WARNING: DEVELOPMENT USE ONLY!
This configuration uses a custom, self-signed Certificate Authority (Step-CA) and is strictly for local development, testing, and private environments. DO NOT use this setup in any public-facing or production deployment, as the certificates will not be trusted externally.

## 🚀 Goals
 

*   Provide automatic, trusted HTTPS for all Docker services using the ACME protocol.
     
*   Use Step-CA as a local Certificate Authority (CA) to replace self-signed certificates.
     
*   Use Traefik's `tlschallenge` on a single, unified Docker network (`web-proxy`).
     

## ⚙️ Prerequisites
 

*   Docker and Docker Compose (v2) installed.
     
*   Basic understanding of Traefik and Docker networks.
     

## 📝 Environment Variables (`.env`)
 
Create a `.env` file at the root of the project to configure the services.
 

| Variable | Description | Constraint | Used by |
| -------- | ----------- | ---------- | ------- |
| `DOMAIN_SUFFIX` | The domain extension for all local services (e.g., `.test` or `.local`). | **Must start with a period (**`.`). | Traefik &amp; Step-CA |
| `TRAEFIK_EMAIL` | Administrative email required by the ACME protocol. | Must be a valid email format (can be a placeholder like `admin@traefik.test`). | Traefik &amp; Step-CA |
| `ORGANISATION` | Name of the organization for the Step-CA Root Certificate. | e.g., `MyCompanyDev` | Step-CA |
| `STEP_CA_PASSWORD` | Strong password used to secure the Step-CA Key. | **Mandatory** | Step-CA |

## 📦 Build and Run the Stack
 

### 1\. File Structure
 
Ensure you have the following directories and files created before starting:
 

    .
    ├── .env
    ├── docker-compose.yml
    ├── step-ca
    │   └── Dockerfile
    │   └── entrypoint.sh  <-- Contains domain and email validation
    ├── step-ca-datas/     <-- Persistent data for Step-CA and CA certificates
    └── traefik-config/    <-- Persistent data for Traefik (acme.json)

### 2\. Initial File Persistence Note
 
The `traefik-config/acme.json` file is where Traefik stores ACME account data and issued certificates.
 
> **Persistence Note:** This file is typically committed to the repository (empty) to ensure the directory structure and permissions are correct on clone. Do not delete this file unless you intend to reset all ACME accounts.
 
If `traefik-config/acme.json` is accidentally deleted, recreate it with the correct permissions:
 

    mkdir -p traefik-config
    touch traefik-config/acme.json
    chmod 600 traefik-config/acme.json

### 3\. Launch
 
Build the custom Step-CA image and launch the entire stack:
 

    docker compose up --build -d

## 🔐 Trusting the Root CA
 
After the stack is running, you must trust the Step-CA root certificate (`root_ca.crt`) on your host machine to avoid browser warnings.
 

1.  Locate the certificate: It is mounted from `./step-ca-datas/certs/root_ca.crt`.
     
2.  Install the certificate into your operating system's trust store.
     

## 💻 Accessing Traefik
 
Once the CA is trusted and the containers are healthy, you can access the Traefik Dashboard.
 

*   **URL:** `https://traefik.test` (if `DOMAIN_SUFFIX=.test` in your `.env`)
     

## 🔗 Integrating a New Project
 
To expose a new application (like a web service or API) through Traefik, add its service definition to the **main** `docker-compose.yml` file and apply the necessary labels.
 
**Example: Adding a simple** `whoami` service
 

      whoami:
        image: traefik/whoami
        container_name: whoami
        labels:
          - traefik.enable=true
          - traefik.http.routers.whoami.rule=Host(`whoami.test`)
          - traefik.http.routers.whoami.entrypoints=websecure
          - traefik.http.routers.whoami.tls.certresolver=stepca
        networks:
          - web-proxy

> **Note on Domain:** In this example, `whoami.test` is hardcoded. This approach assumes that your `DOMAIN_SUFFIX` is `.test`. If your suffix is different (e.g., `.local`), you must adjust the `Host` rule accordingly.
 
**Important:** The new service **must** join the `web-proxy` network for Traefik to discover it.
 

### 🗑️ Cleanup
 
To stop and remove all services, volumes, and networks:
 

    docker compose down -v

This ensures a clean slate for the next run.
 

## 📜 License
 
This project is licensed under the **MIT License**.
 
This means you are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software, provided you include the original copyright and permission notice.
 
> **Note on Third-Party Tools:** This license covers the configuration files (`docker-compose.yml`, custom scripts, etc.). The Docker software, Traefik, and Step-CA are governed by their respective licenses. Please refer to their official documentation for licensing information.
 

## 🤝 Contributing
 
Contributions are always welcome! Whether you have suggestions for new features, bug reports, or improvements to the documentation or scripts, please feel free to:
 

1.  **Fork** the repository.
     
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
     
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
     
4.  Push to the branch (`git push origin feature/AmazingFeature`).
     
5.  Open a Pull Request.
     

Your help makes this project better for everyone.