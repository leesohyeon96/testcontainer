#!/bin/bash

# init.sql 파일 정리 스크립트
OUTPUT_FILE=src/test/resources/init.sql

if [ ! -f $OUTPUT_FILE ]; then
  echo "❌ $OUTPUT_FILE 파일이 존재하지 않습니다."
  exit 1
fi

echo "🧹 init.sql 파일을 정리하는 중..."

# 백업 생성
cp $OUTPUT_FILE ${OUTPUT_FILE}.backup

# 불필요한 PostgreSQL 명령어들 제거
echo "🔧 불필요한 명령어들을 제거하는 중..."

# \restrict와 \unrestrict 제거 (해시값 포함)
sed -i '' '/\\restrict.*/d' $OUTPUT_FILE
sed -i '' '/\\unrestrict.*/d' $OUTPUT_FILE

# \script 명령어 제거
sed -i '' '/\\script/d' $OUTPUT_FILE

# 버전 정보 주석 제거
sed -i '' '/^-- Dumped from database version/d' $OUTPUT_FILE
sed -i '' '/^-- Dumped by pg_dump version/d' $OUTPUT_FILE

# 빈 줄 정리 (연속된 빈 줄을 하나로)
sed -i '' '/^$/N;/^\n$/d' $OUTPUT_FILE

# 파일 끝의 빈 줄들 제거
sed -i '' -e :a -e '/^\s*$/N;ba' -e 's/\n*$//' $OUTPUT_FILE

echo "✅ 정리 완료!"
echo "📊 정리된 파일 크기: $(wc -l < $OUTPUT_FILE) 줄"
echo "📄 정리된 파일 내용 미리보기:"
head -20 $OUTPUT_FILE

echo ""
echo "💾 원본 파일은 ${OUTPUT_FILE}.backup으로 백업되었습니다."
