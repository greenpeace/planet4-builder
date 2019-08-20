#!/usr/bin/env bash
set -eu
P4_SITE=${APP_HOSTNAME}/${APP_HOSTPATH}
MSG_SUBJECT="Planet4 notification: In Two days a sync of production->staging and production->develop will happen"
MSG_BODY="Hi there, <br> You receive this email because you are an administrator of the Planet4 website ${P4_SITE} . <br> As it is planned, every month on the 1st, an automatic sync will happen where the content of your production site will be copied to the staging and develop sites. <br> The content of the staging and develop sites will be overwritten. <br> Please keep somewhere else anything from your release or develop sites thaty ou would not like to be deleted. <br> You can read more at: https://planet4.greenpeace.org/handbook/dev-sync-your-production-environment-into-your-staging-and-develop-environments/"
GCLOUD_ZONE=us-central1-a


gcloud container clusters get-credentials "${GCLOUD_CLUSTER}" \
--zone "${GCLOUD_ZONE}" \
--project "${GOOGLE_PROJECT_ID}"


php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
    --sort-by=.metadata.creationTimestamp \
    --field-selector=status.phase=Running \
    -l "release=${HELM_RELEASE},component=php" \
    -o jsonpath="{.items[-1:].metadata.name}")

if [[ -z "$php" ]]
then
  echo "ERROR: PHP pod not found!"
  exit 1
fi

EMAIL_ADDRESS=$(kubectl --namespace "${HELM_NAMESPACE}" exec "$php" wp option get admin_email)




json=$(jq -n \
  --arg EMAIL_ADDRESS "$EMAIL_ADDRESS" \
  --arg MSG_SUBJECT "$MSG_SUBJECT" \
  --arg MSG_BODY "$MSG_BODY" \
'{
  "personalizations": [
    {
      "to": [
        {
          "email": $EMAIL_ADDRESS
        }
      ]
    }
  ],
  "from": {"email": "planet4-pm-group@greenpeace.org"},
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
