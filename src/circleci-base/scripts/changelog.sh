#!/usr/bin/env bash
set -euo pipefail

if [ -z "$1" ]; then
  echo "Version tag is missing"
  exit 1
fi

VERSION="$1"

function receive() {
  type=$1

  JIRA_API_QUERY="https://jira.greenpeace.org/rest/api/latest/search?jql=project%20%3D%20PLANET%20AND%20fixVersion%20%3D%20${VERSION}%20AND%20type=${type}&fields=summary,issuetype,customfield_13100,assignee"

  jira_json=$(curl -s "$JIRA_API_QUERY")
  retval=$?
  if [ "$retval" -ne 0 ]; then
    echo "Failed to query JIRA for issue"
    exit 1
  fi

  echo "$jira_json" | jq --raw-output '.issues []  | .key ' > /tmp/$$.keys
  echo "$jira_json" | jq --raw-output '.issues []  | .fields .summary ' > /tmp/$$.summaries
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

  assignees=()
  i=0
  while read -r line
  do
    assignees[i]=$line
    i=$((i + 1))
  done < /tmp/$$.assignees

  total=${#keys[*]}

  if [ "$total" -ne 0 ]; then
    case $type in
      "Task")
        echo "<h3>🔧 Features</h3>"
        ;;
      "Bug")
        echo "<h3>🐞 Bug Fixes</h3>"
        ;;
    esac

    echo
    echo "<ul>"
    for (( i=0; i<=$(( total -1 )); i++ ))
    do
      key=$(echo "${keys[$i]}" | xargs )
      summary="${summaries[$i]}"
      assignee="${assignees[$i]}"
      volunteer_star=""
      if [ "$assignee" == "volunteer" ]; then
        volunteer_star=" ⭐"
        volunteer_memo="<font size='1'>⭐ Contributed by a volunteer</font><br>"
      fi
      echo "<li><a href='https://jira.greenpeace.org/browse/${key}'>${key}</a> - ${summary}${volunteer_star}</li>"
    done
    echo "</ul>"
    echo
  fi
}

now="$(date +'%Y-%m-%d')"
volunteer_memo=""

echo
echo "<h2>${VERSION} - ${now}</h2>"
echo

receive "Task"
receive "Bug"

echo "$volunteer_memo"
