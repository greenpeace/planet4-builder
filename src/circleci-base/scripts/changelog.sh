#!/usr/bin/env bash
set -euo pipefail

if [ -z "$1" ]; then
  echo "Version tag is missing"
  exit 1
fi

VERSION="$1"

now="$(date +'%Y-%m-%d')"
volunteer_memo=""

changelog="<h2>${VERSION} - ${now}</h2>"

JIRA_API_QUERY="https://jira.greenpeace.org/rest/api/latest/search?jql=project%20%3D%20PLANET%20AND%20fixVersion%20%3D%20${VERSION}&fields=summary,issuetype,customfield_13100,customfield_12100,issuetype,assignee"

jira_json=$(curl -s "$JIRA_API_QUERY")
retval=$?
if [ "$retval" -ne 0 ]; then
  echo "Failed to query JIRA for issue"
  exit 1
fi

echo "$jira_json" | jq --raw-output '.issues []  | .key ' > /tmp/$$.keys
echo "$jira_json" | jq --raw-output '.issues []  | .fields .summary ' > /tmp/$$.summaries
echo "$jira_json" | jq --raw-output '.issues []  | .fields .customfield_12100 .value ' > /tmp/$$.tracks
echo "$jira_json" | jq --raw-output '.issues []  | .fields .issuetype .name ' > /tmp/$$.issuetypes
echo "$jira_json" | jq --raw-output '.issues []  | .fields .assignee .name ' > /tmp/$$.assignees

keys=()
i=0
while read -r line
do
  keys[i]=$line
  i=$((i + 1))
done < /tmp/$$.keys

summaries=()
i=0
while read -r line
do
  summaries[i]=$line
  i=$((i + 1))
done < /tmp/$$.summaries

issuetypes=()
i=0
while read -r line
do
  issuetypes[i]=$line
  i=$((i + 1))
done < /tmp/$$.issuetypes

tracks=()
i=0
while read -r line
do
  tracks[i]=$line
  i=$((i + 1))
done < /tmp/$$.tracks

assignees=()
i=0
while read -r line
do
  assignees[i]=$line
  i=$((i + 1))
done < /tmp/$$.assignees

total=${#keys[*]}

if [ "$total" -ne 0 ]; then
  features="<h3>🔧 Features</h3><ul>"
  bugs="<h3>🐞 Bug Fixes</h3><ul>"
  infra="<h3>👷 Infrastructure</h3><ul>"

  for (( i=0; i<=$(( total -1 )); i++ ))
  do
    key=$(echo "${keys[$i]}" | xargs )
    summary="${summaries[$i]}"
    assignee="${assignees[$i]}"
    track="${tracks[$i]}"
    issuetype="${issuetypes[$i]}"


    volunteer_star=""
    if [ "$assignee" == "volunteer" ]; then
      volunteer_star=" <font size='1'>⭐</font>"
      volunteer_memo="<font size='1'>⭐ Contributed by a volunteer</font>"
    fi

    ticket="<li><a href='https://jira.greenpeace.org/browse/${key}'>${key}</a> - ${summary}${volunteer_star}</li>"

    if [ "$track" == "Infra" ]; then
      infra="$infra$ticket"
    elif [ "$issuetype" == "Task" ]; then
      features="$features$ticket"
    else
      bugs="$bugs$ticket"
    fi

  done

  features="$features</ul>"
  bugs="$bugs</ul>"
  infra="$infra</ul>"
fi

if [ ${#features} -gt 100 ]; then
  changelog="$changelog$features"
fi

if [ ${#bugs} -gt 100 ]; then
  changelog="$changelog$bugs"
fi

if [ ${#infra} -gt 100 ]; then
  changelog="$changelog$infra"
fi

changelog="$changelog$volunteer_memo"

# Send Changelog to email
MSG_SUBJECT="[Release] v$VERSION 🤖"
MSG_BODY="Hi everyone,<br><br> A new Planet 4 release is being deployed today. Below is the full list of changes.<br>$changelog<br><a href='https://support.greenpeace.org/planet4/tech/changelog'><font size='1'>Release History</font></a><br><br>The P4 Bot 🤖"
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
