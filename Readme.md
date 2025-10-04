🚀 사전 준비

1️⃣ Docker Desktop 설치

Testcontainers와 로컬 PostgreSQL 컨테이너가 필요합니다.

Docker 설치 가이드

2️⃣ Gradle, Java 17 이상 설치

./gradlew를 사용해도 무방합니다.

🧰 환경 구성

1️⃣ 운영 DB 컨테이너 띄우기

docker compose up -d


docker-compose.yml에 정의된 PostgreSQL 컨테이너가 “운영 DB” 역할을 합니다.
이 안에는 실제 서비스에서 사용하는 테이블이 생성되어 있어야 합니다.

2️⃣ 운영 DB 스키마 추출

./schema_dump.sh


해당 스크립트는 운영DB로부터 스키마만 덤프(pg_dump -s) 하여
src/test/resources/init.sql에 저장합니다.

💡 이 파일은 Testcontainers가 테스트 DB를 초기화할 때 자동으로 로드됩니다.

3️⃣ 테스트 실행

./gradlew test


Testcontainers가 자동으로 PostgreSQL 테스트 컨테이너를 생성합니다.

init.sql을 이용해 운영DB 스키마를 복제한 후 테스트를 수행합니다.

테스트 완료 시 컨테이너는 자동 종료됩니다.

🧩 전체 흐름
운영DB (docker compose)
↓  pg_dump -s
init.sql
↓
PostgreSQLContainer (Testcontainers)
↓
테스트 코드 실행

🧹 테스트 후 정리

테스트 완료 후 운영 DB 컨테이너를 종료하려면 아래 명령어를 실행합니다.

docker compose down

⚙️ 참고

schema_dump.sh는 실행 권한이 있어야 합니다.

chmod +x schema_dump.sh


테스트 실행 시 dumpSchema Gradle task가 자동 실행되도록 설정되어 있습니다.

init.sql은 자동으로 덮어써지므로 git 관리 대상에서 제외(.gitignore)하는 것을 권장합니다.
