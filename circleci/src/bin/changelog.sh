#!/usr/bin/env bash
set -eo pipefail

if [ -z "$1" ]; then
  echo "Version tag is missing"
  exit 1
fi

# Assign version and strip "v" prefix
VERSION="${1#v}"

now="$(date +'%Y-%m-%d')"
contributor_memo=""
feature_flags=""

changelog="<h2>${VERSION} - ${now}</h2>"

JIRA_API_QUERY="https://jira.greenpeace.org/rest/api/latest/search?jql=project%20%3D%20PLANET%20AND%20fixVersion%20%3D%20${VERSION}&fields=summary,issuetype,customfield_13100,issuetype,assignee,labels"

jira_json=$(curl -s "$JIRA_API_QUERY")
retval=$?
if [ "$retval" -ne 0 ]; then
  echo "Failed to query JIRA for issue"
  exit 1
fi

echo "$jira_json" | jq --raw-output '.issues []  | .key ' >/tmp/$$.keys
echo "$jira_json" | jq --raw-output '.issues []  | .fields .summary ' >/tmp/$$.summaries
echo "$jira_json" | jq --raw-output '.issues []  | .fields .issuetype .name ' >/tmp/$$.issuetypes
echo "$jira_json" | jq --raw-output '.issues []  | .fields .assignee .name ' >/tmp/$$.assignees
echo "$jira_json" | jq --raw-output '.issues []  | .fields .labels [] // 0 ' >/tmp/$$.labels

keys=()
i=0
while read -r line; do
  keys[i]=$line
  i=$((i + 1))
done </tmp/$$.keys

summaries=()
i=0
while read -r line; do
  summaries[i]=$line
  i=$((i + 1))
done </tmp/$$.summaries

issuetypes=()
i=0
while read -r line; do
  issuetypes[i]=$line
  i=$((i + 1))
done </tmp/$$.issuetypes

assignees=()
i=0
while read -r line; do
  assignees[i]=$line
  i=$((i + 1))
done </tmp/$$.assignees

labels=()
i=0
while read -r line; do
  labels[i]=$line
  i=$((i + 1))
done </tmp/$$.labels

total=${#keys[*]}

if [ "$total" -ne 0 ]; then
  features="<h3>🔧 Features</h3><ul>"
  bugs="<h3>🐞 Bug Fixes</h3><ul>"
  infra="<h3>👷 Infrastructure</h3><ul>"
  features_md="### Features\n\n"
  bugs_md="\n### Bug Fixes\n\n"
  infra_md="\n### Infrastructure\n\n"

  for ((i = 0; i <= $((total - 1)); i++)); do
    key=$(echo "${keys[$i]}" | xargs)
    summary="${summaries[$i]}"
    assignee="${assignees[$i]}"
    issuetype="${issuetypes[$i]}"
    label="${labels[$i]}"

    contributor_star=""
    if [ "$assignee" == "contributor" ]; then
      contributor_star=" <font size='1'>⭐</font>"
      contributor_memo="<font size='1'>⭐ Community contributed</font>"
    fi

    feature_icon=""
    if [[ "$label" == *"featureflag"* ]]; then
      feature_icon=" <font size='1'>🔑</font>"
      feature_flags="<font size='1'>🔑 [Feature Flag] Not enabled by default</font>"
    fi

    ticket="<li><a href='https://jira.greenpeace.org/browse/${key}'>${key}</a> - ${summary}${contributor_star}${feature_icon}</li>"
    ticket_md="- [${key}](https://jira.greenpeace.org/browse/${key}) - ${summary}\n"

    if [ "$issuetype" == "Infra Task" ]; then
      infra="$infra$ticket"
      infra_md="$infra_md$ticket_md"
    elif [ "$issuetype" == "Bug" ]; then
      bugs="$bugs$ticket"
      bugs_md="$bugs_md$ticket_md"
    else
      features="$features$ticket"
      features_md="$features_md$ticket_md"
    fi

  done

  features="$features</ul>"
  bugs="$bugs</ul>"
  infra="$infra</ul>"
fi

md="## ${VERSION} - ${now}\n\n"

if [ ${#features} -gt 100 ]; then
  changelog="$changelog$features"
  md="$md$features_md"
fi

if [ ${#bugs} -gt 100 ]; then
  changelog="$changelog$bugs"
  md="$md$bugs_md"
fi

if [ ${#infra} -gt 100 ]; then
  changelog="$changelog$infra"
  md="$md$infra_md"
fi

changelog="$changelog$contributor_memo$feature_flags"
md="\n$md"

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

# Commit Chagelog to Gitbook
git clone -b master git@github.com:greenpeace/planet4-docs.git
cd planet4-docs/docs/platform/changelog/
git config user.email "${GIT_USER_EMAIL}"
git config user.name "CircleCI Bot"
git config push.default simple
commit_message=":robot: Changelog $VERSION"
first=$(head -n 8 README.md)
last=$(tail -n +9 README.md)
echo "$first" >README.md
echo -e "$md" >>README.md
echo "$last" >>README.md
git add README.md
git commit -m "$commit_message"
git push origin master
