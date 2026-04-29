#!/bin/bash

# PostgreSQL 연결 정보
HOST=127.0.0.1
PORT=5432
USER=prod_user
DBNAME=prod_db
PGPASSWORD=prod_pass

OUTPUT_FILE=src/test/resources/init.sql

# PostgreSQL 컨테이너가 실행 중인지 확인
if ! docker ps | grep -q postgres-prod; then
  echo "❌ PostgreSQL 컨테이너가 실행되지 않았습니다. docker-compose up -d를 먼저 실행하세요."
  exit 1
fi

# 스키마만 덤프 (데이터 없이)
echo "📋 PostgreSQL 스키마를 덤프하는 중..."
PGPASSWORD=$PGPASSWORD pg_dump \
  --host=$HOST \
  --port=$PORT \
  --username=$USER \
  --dbname=$DBNAME \
  --schema-only \
  --no-owner \
  --no-privileges \
  --no-comments \
  --no-tablespaces \
  --format=plain \
  --file=$OUTPUT_FILE

if [ $? -eq 0 ]; then
  echo "✅ 스키마가 성공적으로 덤프되었습니다: $OUTPUT_FILE"
  
  # 불필요한 PostgreSQL 명령어들 제거
  echo "🔧 불필요한 PostgreSQL 명령어들을 제거하는 중..."
  
  # \restrict와 \unrestrict 제거
  sed -i '' '/\\restrict/d' $OUTPUT_FILE
  sed -i '' '/\\unrestrict/d' $OUTPUT_FILE

  # \script 명령어 제거 (있다면)
  sed -i '' '/\\script/d' $OUTPUT_FILE

  # 기타 불필요한 명령어들 제거
  sed -i '' '/^-- Dumped from database version/d' $OUTPUT_FILE
  sed -i '' '/^-- Dumped by pg_dump version/d' $OUTPUT_FILE

  # PG17+ 전용 설정 제거 (postgres:15 컨테이너 호환성)
  sed -i '' '/^SET transaction_timeout/d' $OUTPUT_FILE
  
  # 파일 크기 확인
  if [ -s $OUTPUT_FILE ]; then
    echo "📊 덤프된 파일 크기: $(wc -l < $OUTPUT_FILE) 줄"
    echo "📄 파일 내용 미리보기:"
    head -10 $OUTPUT_FILE
  else
    echo "⚠️  덤프된 파일이 비어있습니다."
  fi
else
  echo "❌ 스키마 덤프에 실패했습니다."
  exit 1
fi