#!/bin/bash

# 대안 방법: Docker 컨테이너 내부에서 직접 실행
OUTPUT_FILE=src/test/resources/init.sql

echo "📋 Docker 컨테이너 내부에서 스키마 덤프 중..."

# Docker 컨테이너 내부에서 pg_dump 실행
docker exec postgres-prod pg_dump \
  --username=prod_user \
  --dbname=prod_db \
  --schema-only \
  --no-owner \
  --no-privileges \
  --no-comments \
  --no-tablespaces \
  --format=plain > $OUTPUT_FILE

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
  
  # 파일 내용 확인
  if [ -s $OUTPUT_FILE ]; then
    echo "📊 덤프된 파일 크기: $(wc -l < $OUTPUT_FILE) 줄"
  else
    echo "⚠️  덤프된 파일이 비어있습니다."
  fi
else
  echo "❌ 스키마 덤프에 실패했습니다."
  exit 1
fi
