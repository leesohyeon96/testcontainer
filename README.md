# Testcontainer 예제 프로젝트

운영 DB 스키마를 그대로 복제하여 Testcontainers로 통합 테스트를 수행하는 방법을 보여주는 예제 프로젝트입니다.

## 목적

- 운영 DB(Docker Compose)에서 스키마만 덤프(`pg_dump -s`)
- 덤프된 `init.sql`을 Testcontainers PostgreSQL 컨테이너에 자동 적용
- 운영 스키마와 동일한 환경에서 JPA / MyBatis 통합 테스트 실행

## 기술 스택

| 분류 | 내용 |
|------|------|
| Language | Java 17 |
| Framework | Spring Boot 3.4.10 |
| ORM | JPA (Hibernate), MyBatis 3.0.5 |
| DB | PostgreSQL 15 |
| Test | JUnit 5, Testcontainers 1.20.3 |
| Build | Gradle 8.x |

## 프로젝트 구조

```
src/
├── main/
│   ├── java/com/shl/testcontainer/
│   │   ├── entity/User.java                          # JPA 엔티티
│   │   ├── repository/UserRepository.java            # Spring Data JPA 리포지토리
│   │   └── dao/UserDao.java                          # MyBatis 매퍼
│   └── resources/
│       └── application.properties
└── test/
    ├── java/com/shl/testcontainer/
    │   ├── TestcontainerApplicationTests.java        # 방식 1: @DynamicPropertySource
    │   └── TestcontainerServiceConnectionTests.java  # 방식 2: @ServiceConnection
    └── resources/
        ├── application-test.yml
        └── init.sql                                  # 운영 DB 스키마 덤프 (자동 생성됨)

docker-compose.yml    # 로컬 운영 DB 컨테이너
schema_dump.sh        # 운영 DB 스키마 추출 스크립트
```

## 사전 요구사항

- **Docker Desktop** — Testcontainers 및 로컬 PostgreSQL 컨테이너 실행에 필요
- **Java 17 이상** — `./gradlew` 사용 시 별도 설치 불필요
- **`pg_dump` CLI** — `schema_dump.sh` 실행에 필요

  ```bash
  # macOS (Homebrew)
  brew install libpq
  export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
  ```

## 로컬 실행 방법

### 1. 운영 DB 컨테이너 시작

```bash
docker compose up -d
```

`docker-compose.yml`에 정의된 PostgreSQL 컨테이너가 로컬 운영 DB 역할을 합니다.  
접속 정보 및 DB명은 `docker-compose.yml` 파일을 직접 확인하세요.

> `docker/init.sql`이 컨테이너 최초 실행 시 자동으로 적용되어 테이블이 생성됩니다.

### 2. 스크립트 실행 권한 부여 (최초 1회)

```bash
chmod +x schema_dump.sh
```

### 3. 운영 DB 스키마 덤프

```bash
./schema_dump.sh
```

- 운영 DB에서 스키마만(`--schema-only`) 추출하여 `src/test/resources/init.sql`에 저장합니다.
- 데이터는 포함되지 않습니다.

> **참고**: `init.sql`은 매 실행 시 덮어쓰이는 자동 생성 파일입니다. `.gitignore`에 이미 등록되어 있습니다.

### 4. 테스트 실행

```bash
./gradlew test
```

- `test` task 실행 시 `dumpSchema` task가 자동으로 먼저 실행됩니다 (`build.gradle` 의존 설정).
- Testcontainers가 PostgreSQL 컨테이너를 자동 생성하고 `init.sql`로 스키마를 초기화합니다.
- 테스트 완료 후 컨테이너는 자동으로 종료됩니다.

### 5. 운영 DB 컨테이너 종료

```bash
docker compose down
```

## 전체 흐름

```
docker compose up -d
      ↓
운영 DB (PostgreSQL 컨테이너)
      ↓  schema_dump.sh (pg_dump -s)
src/test/resources/init.sql
      ↓  ./gradlew test
PostgreSQLContainer (Testcontainers)
      ↓  init.sql 자동 적용
JPA / MyBatis 통합 테스트 실행
      ↓
컨테이너 자동 종료
```

## 컨테이너 연결 방식 비교

이 프로젝트에서는 Testcontainers와 Spring을 연결하는 두 가지 방식을 모두 구현해두었습니다.

### 방식 1. `@DynamicPropertySource` — `TestcontainerApplicationTests`

컨테이너에서 JDBC URL / 계정 정보를 직접 꺼내 Spring 프로퍼티에 수동으로 등록합니다.

```java
@Container
static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
        .withInitScript("init.sql");

@DynamicPropertySource
static void configureProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", postgres::getJdbcUrl);
    registry.add("spring.datasource.username", postgres::getUsername);
    registry.add("spring.datasource.password", postgres::getPassword);
    registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
}
```

- Spring Boot 2.x부터 사용 가능
- 어떤 컨테이너든 프로퍼티 이름을 자유롭게 지정할 수 있어 유연함
- Redis, Kafka 등 여러 컨테이너를 커스텀 프로퍼티로 연결할 때 적합

### 방식 2. `@ServiceConnection` — `TestcontainerServiceConnectionTests`

`@ServiceConnection` 어노테이션 하나로 Spring이 컨테이너 정보를 자동으로 읽어 주입합니다.

```java
@Container
@ServiceConnection
static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
        .withInitScript("init.sql");
```

- Spring Boot 3.1+, `spring-boot-testcontainers` 의존성 필요
- `@DynamicPropertySource` 메서드가 불필요해져 코드가 간결함
- PostgreSQL, Redis, Kafka 등 Spring이 공식 지원하는 컨테이너에서 사용 가능

| | `@DynamicPropertySource` | `@ServiceConnection` |
|---|---|---|
| 지원 버전 | Spring Boot 2.x+ | Spring Boot 3.1+ |
| 코드량 | 많음 | 적음 |
| 유연성 | 높음 (커스텀 프로퍼티 가능) | 지원 컨테이너 한정 |
| 추가 의존성 | 불필요 | `spring-boot-testcontainers` 필요 |
