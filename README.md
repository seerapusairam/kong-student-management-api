# Student Management API with Kong Gateway

This project sets up a Student Management API using a Node.js application, secured and managed by Kong Gateway. It includes Redis for caching/session management and Konga for easy administration of Kong.

The architecture follows modern DevOps principles, separating the application build process from the deployment process. The application is containerized and pushed to a Docker registry, and the deployment is managed via Docker Compose, which pulls the pre-built image.

---

## Architecture

The system uses a gateway-first architecture. All client requests are sent to the Kong API Gateway, which acts as a single, unified entry point. Kong is responsible for initial traffic management before forwarding valid requests to the backend Student API service.

```
                                      +-----------------------------+
                                      |     KONG API GATEWAY        |
                                      | (localhost:8000)            |
[Client] --- (API Requests) --------->|                             |
                                      |  - Routing                  |
                                      |  - Rate Limiting            |
                                      +-----------------------------+
                                                  |
                                      (Internal Docker Network)
                                                  |
                                +----------------------------------+
                                |                                  |
                      +---------------------+           +----------------------+
                      | Student API Service |---------> |   MongoDB Database   |
                      | (Node.js/Express)   |           +----------------------+
                      +---------------------+
                                |
                                |
                      +---------------------+
                      |    Redis Cache      |
                      +---------------------+
```

---
## Features

This deployment repository provides:
* **API Gateway Layer:** Implements Kong as a single, secure entry point for the backend service.
* **Centralized Traffic Control:** The rate-limiting logic, previously handled in the Node.js application, has been removed from the application code and is now managed and enforced at the edge by the Kong Gateway.
* **Full Stack Orchestration:** A single `docker-compose` command launches the entire environment.

For a complete list of the **application's features** (CRUD operations, JWT authentication, etc.), please refer to the main application repository:
* **[Student Management API Repository](https://github.com/seerapusairam/student-management-api)**

---

## Services

The project uses `docker-compose` to orchestrate the following services:

- **`app`**: The Node.js Student Management API. It connects to Redis for data operations.
- **`redis`**: A Redis instance used by the `app` for caching or session management.
- **`kong-db`**: A PostgreSQL database specifically for Kong Gateway's configuration.
- **`kong-migrations`**: A service to run Kong database migrations, ensuring the database schema is up-to-date.
- **`kong-gateway`**: The Kong API Gateway, which acts as a proxy for the `app` service, providing security, traffic control, and other API management features.
- **`konga`**: A powerful open-source GUI for Kong Admin API, making it easy to manage services, routes, plugins, and consumers.

## Getting Started

### Prerequisites

- Docker and Docker Compose installed on your machine.

### Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/seerapusairam/kong-student-management-api.git
    cd kong-student-management-api
    ```

2.  **Create a `.env` file:**
    Create a `.env` file in the root directory of the project with the following environment variables. Replace the placeholder values with your actual secrets and desired configurations.

    ```
    URL=<your-mongodb-connection-string>
    REDIS_URL=redis://redis:6379
    JWT_SECRET=your_jwt_secret_key
    JWT_EXP=1h
    PORT=3000
    ```

    *   `URL`: The base URL for your application.
    *   `JWT_SECRET`: A secret key for signing JWT tokens.
    *   `JWT_EXP`: Expiration time for JWT tokens (e.g., `1h`, `7d`).
    *   `PORT`: The port on which your Node.js application will run internally within the Docker network.

3.  **Start the services:**
    ```bash
    docker-compose up -d
    ```
    This command will:
    *   Pull necessary Docker images for Redis, PostgreSQL, Kong, and Konga.
    *   Start all services in detached mode (`-d`).

4.  **Verify services are running:**
    ```bash
    docker-compose ps
    ```
    You should see all services listed with a `Up` status.

## Accessing the Services

*   **Kong Gateway (Proxy Port):** `http://localhost:8000`
    This is where your API consumers will interact with your services after you configure Kong.
*   **Kong Admin API:** `http://localhost:8001`
    Used for programmatic administration of Kong.
*   **Konga UI:** `http://localhost:1337`
    Access the Konga interface to manage your Kong Gateway. You will need to set up a connection to Kong Admin API (`http://kong-gateway:8001`) within Konga.

## Configuring Kong (via Konga)

1.  Navigate to `http://localhost:1337` in your browser.
2.  Follow the on-screen instructions to set up your Konga user.
3.  Once logged in, add a new Kong connection:
    *   **Name:** `My Kong` (or any descriptive name)
    *   **Kong Admin URL:** `http://kong-gateway:8001` (This is the internal Docker network address for Kong's Admin API)
    *   Click "Submit" and then "Test Connection" to ensure it's working.
    *   Activate the connection.

4.  **Add your Student Management API as a Service in Kong:**
    *   In Konga, go to "Services" -> "Add New Service".
    *   **Name:** `student-api-service`
    *   **Protocol:** `http`
    *   **Host:** `app` (This is the Docker service name for your Node.js application)
    *   **Port:** `3000` (The internal port of your Node.js application)
    *   Click "Submit Service".

5.  **Add a Route for your Service:**
    *   Go to the newly created `student-api` service.
    *   Click "Add New Route".
    *   **Name:** `student-routes`
    *   **Protocols:** `http`, `https`
    *   **Hosts:** (Leave empty or specify if you have a domain)
    *   **Paths:** `/api/students`
    *   Ensure **strip_path** is set to `No` for both routes.
    *   Click `Submit Route`.
    *   Similarly you can do for `user-routes` `/api/user`.

Now, requests to `http://localhost:8000/students` (or your configured path) will be routed through Kong to your Node.js application.

## API Usage Examples

### 1. Register and Log In
```bash
# Register a new user
curl -X POST http://localhost:8000/api/user/register -H "Content-Type: application/json" -d '{"name":"test", "email":"test@example.com", "password":"password123"}'

# Log in to get a token
curl -X POST http://localhost:8000/api/user/login -H "Content-Type: application/json" -d '{"email":"test@example.com", "password":"password123"}'
```
### 2. Access a Protected Route
(Replace YOUR_TOKEN_HERE with the token you received from the login step)

```bash
curl http://localhost:8000/api/students -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Stopping the Services

To stop all running services and remove their containers, networks, and volumes:

```bash
docker-compose down -v
```

This will also remove the `kong_db_data` volume, so Kong's database will be reset. If you want to keep the data, remove the `-v` flag.

## Contributing

Feel free to contribute to this project by opening issues or submitting pull requests.

## License

This project is for educational purposes and is open to anyone to use and modify.


## Author

**Sairam S**