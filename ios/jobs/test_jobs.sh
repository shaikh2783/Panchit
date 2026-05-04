#!/bin/bash
set -e

cd "$(dirname "$0")"
source ./quick_copy.sh

echo "\n==> GET categories"
api_get "/data/jobs/categories" ""

echo "\n==> GET jobs list"
api_get "/data/jobs" "offset=0&limit=10"

echo "\n==> CREATE job"
api_post "/data/jobs" '{
  "title": "Backend PHP Developer",
  "category": 1,
  "message": "We are hiring a senior PHP developer",
  "location": "Dubai, UAE",
  "type": "full_time"
}'

echo "\n==> GET jobs list again"
api_get "/data/jobs" "offset=0&limit=10"

echo "\nDone."
