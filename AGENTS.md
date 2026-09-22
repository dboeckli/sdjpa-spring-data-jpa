# AGENTS.md

Spring Boot 4 (parent 4.1.1) / Spring Data JPA demo project on **Java 25** (enforced by the
maven-enforcer plugin). Single Maven module, package `ch.dboeckli.guru.jpa.hibernate.dao`. It
demonstrates the classic **DAO pattern** (`AuthorDaoImpl`/`BookDaoImpl` with `EntityManager`)
side by side with **Spring Data JPA repositories** (`AuthorRepository`/`BookRepository`) for the
entities `Author` and `Book`, against H2 (MySQL-compat mode) and MySQL, with schema management
via **Flyway**. App port `8080`.

## Build & test commands

- Full build: `./mvnw clean verify` — format checks, unit (`*Test`, surefire) + IT (`*IT`, failsafe)
  tests, Helm lint/template.
- Unit tests only: `./mvnw test` (H2-based tests). Single test:
  `./mvnw test -Dtest=BookRepositoryWithH2Test#methodName`.
- `./mvnw clean install` additionally builds the Docker image and packages the Helm chart into
  `target/helm/repo/`. Skip the Docker build with `-Dskip.docker.build=true`.
- `-Dskip.start.stop.springboot=true` skips the in-build app boot (spring-boot:start/stop).
- Run locally: `./mvnw spring-boot:run -Dspring-boot.run.profiles=h2` (or `mysql`).

After changing code, always verify: run the relevant Maven goal above and report its output
(evidence, not just "done").

## Profiles

- `h2`: in-memory H2 in MySQL-compat mode (no Docker).
- `mysql`: MySQL via Docker Compose — `compose-mysql.yaml`; schema via Flyway (`db/migration`).
- IntelliJ run configs in `.run/`: `Spring6Application h2`, `Spring6Application mysql`,
  `deploy-k8s`, `test-k8s`, `uninstall-k8s`, `clear docker`.

## Sandbox build quirk (background)

This sandbox mounts the repo via filesystem passthrough, which blocks symlinks — Spotless's
`npm install` (prettier) would fail with `EPERM` unless npm skips bin links. The sandbox kit sets
`npm_config_bin_links=false` globally (`spec.yaml` → `environment.variables`), so no manual export
is needed here. On a normal host (Windows/CI) this does not apply either.

## Formatting is enforced (fails the `validate` phase)

- Java: Spring Java Format → fix with `./mvnw spring-javaformat:apply`.
- Everything else (pom.xml, `**/*.md`, json, `src/main/resources/application*.yaml`, `**/*.sh`):
  Spotless → fix with `./mvnw spotless:apply`.
- Spotless flexmark also formats markdown, so this file and any `.md` edits must stay flexmark-clean;
  run `./mvnw spotless:apply` after editing markdown.

## Test conventions

- Naming matters: `*Test` = unit (surefire), `*IT` = integration (failsafe).
- H2 tests: DAO tests (`dao/h2`) and repository tests (`repository/h2`) against in-memory H2
  (MySQL-compat mode).
- MySQL ITs: `@ActiveProfiles("test_mysql")` (`dao/mysql`, `repository/mysql`); they need Docker
  (MySQL from the test profile).
- A custom `TestClassOrderer` sorts test classes; `LocaleExtension` forces `Locale.US`.

## Architecture

- `dao/` classic DAO pattern (`AuthorDao`/`BookDao` interfaces, `*DaoImpl` with `EntityManager`);
  `domain/` JPA entities (`Author`, `Book`); `repository/` Spring Data JPA repositories.
- Schema migrations: `src/main/resources/db/migration` (Flyway only).
- `log/` (`LogMessage`, `ConfigChangeListener`) + `config/RequestLoggingConfig` for contextual
  logging/request tracing.

## Deploy / CI

- Deployment is Helm-only: chart in `helm-charts/` (parent `sdjpa-spring-data-jpa-chart`, MySQL
  subchart `sdjpa-spring-data-jpa-mysql-chart`), packaged to `target/helm/repo/`, release name =
  artifactId, namespace `sdjpa-spring-data-jpa`.
- CI (`.github/workflows/`): `maven-build.yml` builds + deploys snapshots and triggers
  `deploy-and-test-cluster.yml`; `release.yml` runs `mvn release:prepare release:perform` on
  main/master only (version must be `-SNAPSHOT`); SonarCloud analysis runs in the `analyze` job.
- Dependency updates are managed via `.github/renovate.json`; validate changes with
  `renovate-config-validator`.
