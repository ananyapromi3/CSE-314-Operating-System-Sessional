#!/bin/bash

# Usage: ./send_email.sh <recipient> <sender> <body>
# Example: ./send_email.sh agent@example.com "enemy@dummy.com" "This is a secret mission"

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <recipient> <sender> <body>"
  exit 1
fi

RECIPIENT=$1
SENDER=$2
BODY=$3

# Get the current timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Log the email details to email.log
{
  echo "Timestamp: $TIMESTAMP"
  echo "From: $SENDER"
  echo "To: $RECIPIENT"
  echo "Body: $BODY"
  echo "---"
} >> email.log

echo "Email sent and logged."
