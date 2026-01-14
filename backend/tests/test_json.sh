#!/bin/bash

TEST_JSON='{"status":"success","message":"register.successful","data":{"access_token":"abc123","user":{"id":"xyz789"}}}'

get_json_value() {
    local JSON=$1
    local KEY=$2
    echo "$JSON" | grep -o "\"$KEY\":\"[^\"]*\"" | head -1 | sed "s/\"$KEY\":\"\(.*\)\"/\1/"
}

echo "Testing get_json_value function:"
echo "Access token: $(get_json_value "$TEST_JSON" "access_token")"
echo "ID: $(get_json_value "$TEST_JSON" "id")"
