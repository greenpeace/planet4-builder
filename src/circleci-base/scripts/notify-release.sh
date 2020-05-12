#!/usr/bin/env bash
set -eu

if [ -z "$VERSION" ]; then
  echo "VERSION tag is missing"
  exit 1
fi

if [ -z "$CHANGELOG" ]; then
  echo "CHANGELOG text is missing"
  exit 1
fi

MSG_SUBJECT="[Release] v$VERSION 🤖"
MSG_BODY="Hi everyone,<br><br> A new Planet 4 release is being deployed today. Below is the full list of changes.<br>$CHANGELOG<br><a href='https://support.greenpeace.org/planet4/tech/changelog'><font size='1'>Release History</font></a><br><br>The P4 Bot 🤖"
EMAIL_TO="$RELEASE_EMAIL_TO"
EMAIL_FROM="$RELEASE_EMAIL_FROM"


json=$(jq -n \
  --arg EMAIL_TO "$EMAIL_TO" \
  --arg EMAIL_FROM "$EMAIL_FROM" \
  --arg MSG_SUBJECT "$MSG_SUBJECT" \
  --arg MSG_BODY "$MSG_BODY" \
'{
  "personalizations": [
    {
      "to": [
        {
          "email": $EMAIL_TO
        }
      ]
    }
  ],
  "from": {"email": $EMAIL_FROM},
  "subject": $MSG_SUBJECT,
  "content": [
    {
      "type": "text/html",
      "value": $MSG_BODY
    }
  ]
}')


curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header "Authorization: Bearer $SENDGRID_API_KEY" \
  --header 'Content-Type: application/json' \
  --data "${json}"
