#!/bin/bash

BASE_URL="http://localhost:3000/api/v2"

get_json_value() {
    local JSON=$1
    local KEY=$2
    echo "$JSON" | grep -o "\"$KEY\":\"[^\"]*\"" | head -1 | sed "s/\"$KEY\":\"\(.*\)\"/\1/"
}

make_request() {
    local METHOD=$1
    local ENDPOINT=$2
    local DATA=$3
    local AUTH_TOKEN=$4
    local EXPECTED_STATUS=$5
    local TEST_NAME=$6

    if [ -n "$AUTH_TOKEN" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X "$METHOD" "$BASE_URL$ENDPOINT" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -d "$DATA")
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X "$METHOD" "$BASE_URL$ENDPOINT" \
            -H "Content-Type: application/json" \
            -d "$DATA")
    fi

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "DEBUG: HTTP_CODE=$HTTP_CODE" >&2
    echo "DEBUG: BODY=$BODY" >&2

    if [ "$HTTP_CODE" == "$EXPECTED_STATUS" ]; then
        echo "$BODY"
        return 0
    else
        echo "$BODY"
        return 1
    fi
}

# Test registration
ORGANIZER_DATA='{
    "email": "test-organizer-999@test.com",
    "password": "Test123!@#",
    "firstName": "John",
    "lastName": "Organizer",
    "nickname": "organizer999",
    "discipline": "aggressive"
}'

echo "Calling make_request..."
ORGANIZER_RESPONSE=$(make_request "POST" "/auth/register" "$ORGANIZER_DATA" "" "201" "Register organizer")
RESULT=$?

echo "Result code: $RESULT"
echo "Response length: ${#ORGANIZER_RESPONSE}"
echo "First 100 chars of response: ${ORGANIZER_RESPONSE:0:100}"

ORGANIZER_TOKEN=$(get_json_value "$ORGANIZER_RESPONSE" "access_token")
ORGANIZER_ID=$(get_json_value "$ORGANIZER_RESPONSE" "id")

echo "Organizer ID: $ORGANIZER_ID"
echo "Organizer Token: ${ORGANIZER_TOKEN:0:20}..."
