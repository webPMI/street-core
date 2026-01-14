#!/bin/bash

BASE_URL="http://localhost:3000/api/v2"

# Test registration
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
    "email": "test999@test.com",
    "password": "Test123!@#",
    "firstName": "Test",
    "lastName": "User",
    "nickname": "testuser999",
    "discipline": "aggressive"
}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Code: $HTTP_CODE"
echo "Body: $BODY"

get_json_value() {
    local JSON=$1
    local KEY=$2
    echo "$JSON" | grep -o "\"$KEY\":\"[^\"]*\"" | head -1 | sed "s/\"$KEY\":\"\(.*\)\"/\1/"
}

ACCESS_TOKEN=$(get_json_value "$BODY" "access_token")
USER_ID=$(get_json_value "$BODY" "id")

echo "Access token extracted: ${ACCESS_TOKEN:0:20}..."
echo "User ID extracted: $USER_ID"
