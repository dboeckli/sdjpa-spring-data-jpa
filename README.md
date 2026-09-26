# Spring Data JPA and Hibernate: Beginner to Guru

Source code for the course *Spring Data JPA and Hibernate: Beginner to Guru*. A Spring Boot 4 demo project on
Java 25 that demonstrates the classic DAO pattern (with `EntityManager`) side by side with Spring Data JPA
repositories for the `Author`/`Book` domain - against H2 (MySQL-compat mode) and MySQL, with schema management
via Flyway and a Helm-based Docker/Kubernetes build & deploy setup.

## Architecture Overview

```mermaid
graph LR
    Client(["💻 Client"])

    subgraph App ["Spring Boot App :8080"]
        Dao["DAO Pattern\n(AuthorDaoImpl / BookDaoImpl\nEntityManager)"]
        Repos["Spring Data JPA\nRepositories"]
    end

    subgraph Domain ["Domain Model"]
        Model["Author / Book\n@GeneratedValue IDENTITY"]
    end

    subgraph Migration ["Schema Management"]
        Flyway["Flyway\ndb/migration"]
        H2Schema["h2-schema.sql\nh2-data.sql"]
    end

    subgraph Databases ["Databases"]
        H2[("H2\nIn-Memory")]
        MySQL[("MySQL\nDocker")]
    end

    Client -->|"actuator :8080"| App
    Dao --> Model
    Repos --> Model
    Dao <--> H2
    Dao <--> MySQL
    Repos <--> H2
    Repos <--> MySQL
    Flyway --> MySQL
    H2Schema --> H2
```

## Database Schema

```mermaid
erDiagram
    author {
        BIGINT       id PK "auto_increment"
        VARCHAR(255) first_name
        VARCHAR(255) last_name
    }

    book {
        BIGINT       id PK "auto_increment"
        VARCHAR(255) title
        VARCHAR(255) isbn
        VARCHAR(255) publisher
        BIGINT       author_id FK
    }

    author ||--o{ book : "author_id"
```

## Flyway

Flyway is enabled by default in the `mysql` profile (`application-mysql.yaml`). The profile starts MySQL on
port `3306` via the Docker Compose file `compose-mysql.yaml` and applies the schema migrations from
`src/main/resources/db/migration`. The `h2` profile runs against in-memory H2 (MySQL-compat mode) with
`h2-schema.sql`/`h2-data.sql` and Flyway disabled.

## Docker

The Docker Compose file mounts `src/scripts/init-mysql.sql` into `/docker-entrypoint-initdb.d/`. On the first
startup this script creates the database `bookdb` and the users `bookadmin` and `bookuser`.

### Deployment with Helm

Be aware that we are using a different namespace here (not default).

Go to the directory where the tgz file has been created after 'mvn install'

```powershell
cd target/helm/repo
```

unpack

```powershell
$file = Get-ChildItem -Filter sdjpa-spring-data-jpa-chart-*.tgz | Select-Object -First 1
tar -xvf $file.Name
```

install

```powershell
$APPLICATION_NAME = Get-ChildItem -Directory | Where-Object { $_.LastWriteTime -ge $file.LastWriteTime } | Select-Object -ExpandProperty Name
helm upgrade --install $APPLICATION_NAME ./$APPLICATION_NAME --namespace sdjpa-spring-data-jpa --create-namespace --wait --timeout 5m --debug
```

show logs

```powershell
kubectl get pods -n sdjpa-spring-data-jpa
```

replace $POD with pods from the command above

```powershell
kubectl logs $POD -n sdjpa-spring-data-jpa --all-containers
```

Show endpoints

```powershell
kubectl get endpoints -n sdjpa-spring-data-jpa
```

test

```powershell
helm test $APPLICATION_NAME --namespace sdjpa-spring-data-jpa --logs
```

status

```powershell
helm status $APPLICATION_NAME --namespace sdjpa-spring-data-jpa
```

uninstall

```powershell
helm uninstall $APPLICATION_NAME  --namespace sdjpa-spring-data-jpa
```

delete all

```powershell
kubectl delete all --all -n sdjpa-spring-data-jpa
```

create busybox sidecar

```powershell
kubectl run busybox-test --rm -it --image=busybox:1.36 --namespace=sdjpa-spring-data-jpa --command -- sh
```

You can use the actuator health endpoint to verify the app via port 30080: `http://localhost:30080/actuator/health`

## Running the Application

1. Choose between h2 or mysql for database schema management. (you can use one of the preconfigured intellij runners)
2. Start the application with the appropriate profile and properties.
3. The application will use Docker Compose to start MySQL and apply the database schema changes.

## Sandbox (local dev environment)

The sandbox is provisioned by the opencode-sandbox-kit and runs as a Docker container. It mounts this
repo, starts the agent, and connects the IntelliJ MCP server. The app runs on port `8080`; `compose-mysql.yaml`
provides MySQL.

Allow the kit source (GitHub without cloning):

```powershell
sbx settings set kit.allowedSources --% "[\"docker.io/\",\"github.com/dboeckli/\"]"
```

Start a new sandbox:

```powershell
sbx run opencode `
    --kit "git+https://github.com/dboeckli/opencode-sandbox-kit.git#dir=opencode-agent" `
    --template docker.io/domboeckli/sbx-opencode-tooling:latest `
    --skills=off `
    --static-mcp idea `
    . `
    "C:\development\maven-repo:ro"
```

Start the sandbox with Kubernetes support:

```powershell
sbx run opencode `
    --kit "git+https://github.com/dboeckli/opencode-sandbox-kit.git#dir=opencode-agent" `
    --template docker.io/domboeckli/sbx-opencode-tooling:latest `
    --skills=off `
    --static-mcp idea `
    . `
    "C:\development\maven-repo:ro" `
    "$env:USERPROFILE\.kube:ro"
```

Claude Code (Home) and Mammouth Code variants:

```powershell
sbx run claude `
    --kit "git+https://github.com/dboeckli/opencode-sandbox-kit.git#dir=opencode-agent" `
    --template docker.io/domboeckli/sbx-claude-tooling:latest `
    --skills=off `
    --static-mcp idea `
    . `
    "C:\development\maven-repo:ro"
```

```powershell
sbx run "git+https://github.com/dboeckli/opencode-sandbox-kit.git#dir=mammouth-agent" `
    --kit-arg imageTag=latest `
    --skills=off `
    --static-mcp idea `
    . `
    "C:\development\maven-repo:ro"
```

### Start the app

Start MySQL (H2 needs no Docker):

```shell
docker compose -f compose-mysql.yaml up
```

Then run one of the IntelliJ run configurations (`.run/Spring6Application h2.run.xml` or the MySQL
one) or start via `./mvnw spring-boot:run -Dspring-boot.run.profiles=h2`.

### Sandbox build quirk

The sandbox mounts the repo via filesystem passthrough, which blocks symlinks — Spotless's `npm install`
(prettier) would fail with `EPERM` unless npm skips bin links. The kit sets `npm_config_bin_links=false`
globally, so no manual export is needed.
