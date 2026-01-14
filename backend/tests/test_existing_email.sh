#!/bin/bash

curl -s -X POST http://localhost:3000/api/v2/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "organizer@test.com",
    "password": "Test123!@#",
    "firstName": "John",
    "lastName": "Organizer",
    "nickname": "organizer1",
    "discipline": "aggressive"
  }'
