# Student Management API with Kong Gateway

This project provides a complete deployment environment for the [Student Management API](https://github.com/seerapusairam/student-management-api), placing it behind a customized Kong API Gateway.

The architecture follows modern DevOps principles. The application is a pre-built Docker image pulled from a registry, and the entire stack is orchestrated via Docker Compose. The gateway itself is customized with a custom Lua plugins and is managed declaratively using `decK`.

---

## Architecture

The system uses a gateway-first architecture. All client requests are sent to the Kong API Gateway, which acts as a single, unified entry point. Kong is responsible for initial traffic management before forwarding valid requests to the backend Student API service.

```
                                      +-----------------------------+
                                      |     KONG API GATEWAY        |
                                      | (with custom Lua plugin)    |
[Client] --- (API Requests) --------->|                             |
                                      | Declarative Config (decK)   |
                                      | Rate Limiting, Logging, etc.|
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

This repository provides the deployment configuration to run the student-management-api behind the Kong API Gateway. This architecture enables powerful, centralized API management capabilities.

* **Custom Kong Gateway:** The deployment builds a custom Kong Docker image to include a **custom Lua plugin**, demonstrating gateway extensibility.
* **Declarative Management:** Kong's entire configuration (services, routes, plugins) is managed declaratively in a `kong.yaml` file and applied automatically with **`decK`**. This eliminates manual setup and ensures a repeatable, version-controlled environment.
* **Centralized Policy Enforcement:** Offloads key policies from the application to the gateway, including:
    * **Rate Limiting**
    * **Centralized Logging** (`http-log`)
    * **Response Transformation**
* **Full Stack Orchestration:** A single `docker-compose up` command launches the entire environment, including the application, custom gateway, PostgreSQL database and Redis cache.

For a complete list of the **application's features**, please refer to its main repository:
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

* Docker and Docker Compose installed.
* [decK](https://developer.konghq.com/deck/get-started/) installed on your local machine.

### Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/seerapusairam/kong-student-management-api.git
    cd kong-student-management-api
    ```

2.  **Create a `.env` file:**
    Use the `.env.example` file as a template to create a `.env` file with your secret values.
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

3.  **Build and Start the Services:**
    This command builds the custom Kong image and starts all services.
    ```bash
    docker-compose up -d --build
    ```
    This command will:
    *   Pull necessary Docker images for Redis, PostgreSQL, Kong, and Konga.
    *   Start all services in detached mode (`-d`).
    *   `--build` ensures that any modifications to your custom Kong image are applied.

4.  **Configure Kong using decK:**
    Apply the declarative configuration to the running Kong instance with a single command.
    ```bash
    deck sync -s kong.yaml
    ```

Your API is now live and accessible through the Kong Gateway at `http://localhost:8000`.

---

## Accessing the Services

*   **Kong Gateway (Proxy Port):** `http://localhost:8000`
    This is where your API consumers will interact with your services after you configure Kong.
*   **Kong Admin API:** `http://localhost:8001`
    Used for programmatic administration of Kong.
*   **Konga UI:** `http://localhost:1337`
    Access the Konga interface to manage your Kong Gateway. You will need to set up a connection to Kong Admin API (`http://kong-gateway:8001`) within Konga.

---

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
    *   Go to the newly created `student-api-service` service.
    *   Click "Add New Route".
    *   **Name:** `student-routes`
    *   **Protocols:** `http`, `https`
    *   **Hosts:** (Leave empty or specify if you have a domain)
    *   **Paths:** `/api/students`
    *   Ensure **strip_path** is set to `No`.
    *   Click `Submit Route`.

    *   **Note:** After running `deck sync -s kong.yaml`, the `user-routes` for `/api/user` should already be configured. You can verify its presence in Konga under "Services" -> "student-api-service" -> "Routes".

6. **Add Plugins to Enhance the API:**
    * This is where you can apply the policies you've developed.
    * Rate Limiting: On the student-api-service, add the rate-limiting plugin to protect the API from overuse.
    * Centralized Logging: Add the http-log plugin and point it to a log collection endpoint to capture detailed request/response data.
    * Response Transformation: On the student-routes route, add the response-transformer plugin to remove internal fields and clean up headers for public clients.
    * **Custom Authentication Plugin:** On the `student-routes` route, add the `custom-plugin`. This plugin validates an `X-Auth-Token` header against a configured password and, if successful, adds an `X-Custom-Header` to the response. You will need to configure the `password` and optionally `token_name` (defaults to `X-Auth-Token`) for this plugin.

Now, requests to `http://localhost:8000/api/students` (or your configured path) will be routed through Kong to your Node.js application.

---

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
# You will see the custom header 'X-Custom-Header' in the response
curl http://localhost:8000/api/students -H "Authorization: Bearer YOUR_TOKEN_HERE" -H "Content-Type: application/json" -H "X-Auth-Token: Qweasdzxc@123" 
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
