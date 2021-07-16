#!/usr/bin/env python3
# Moved from builder repo. Latest commit there:
# https://github.com/greenpeace/planet4-builder/commit/d6640747ad20ed54b7e8d40b0920af106880e17f

import argparse
import hashlib
import json
from oauthlib.oauth1 import SIGNATURE_RSA
import os
import random
import re
import requests
from requests.auth import HTTPBasicAuth
from requests_oauthlib import OAuth1

from p4.apis import api_failed, api_query
from p4.github import get_last_commit_date, get_pull_request

JIRA_API = 'https://jira.greenpeace.org/rest/api/2'
GITHUB_API = 'https://api.github.com'
SWARM_API = 'https://us-central1-planet-4-151612.cloudfunctions.net/p4-test-swarm'

INSTANCE_REPO_PREFIX = 'greenpeace/planet4-test-'
JIRA_INSTANCE_FIELD = 'customfield_13000'


def get_jira_issue(pr=None, jira_key=None):
    """
    Fetch Jira ticket

    Return important informations
    """

    if pr:
        # From title
        title = pr['title']
        title_re = re.compile('^(PLANET-[0-9]{3,6})')
        matches = title_re.match(title)

        jira_key = matches.group(1) if matches else None

        # @todo: from commits

    if not jira_key:
        return None

    logs.append('Jira key found: {0}'.format(jira_key))
    search_result = api_query(
        JIRA_API + '/search?jql=key={0}'.format(jira_key))
    if not search_result['issues']:
        raise Exception(
            'Issue could not be found with key {0}'.format(jira_key))

    issue = search_result['issues'][0]
    return {
        'key': issue['key'],
        'title': issue['fields']['summary'],
        'state': issue['fields']['status']['name'],
        'assignee': issue['fields']['assignee']['name'] if issue['fields']['assignee'] else None,
        'test_instance': (issue['fields'][JIRA_INSTANCE_FIELD][0]['value']
                          if issue['fields'][JIRA_INSTANCE_FIELD] else None),
    }


def book_instance(instance, jira_issue):
    """
    Check jira ticket status & assigned instance
    Move status if needed, book instance on ticket

    @todo: make jira_issue a list of issues,
    loop through it to be able to lock multiple issues to one instance & pr
    """

    current_state = jira_issue['state']
    editable_status = ['Open', 'Validated']
    invalid_status = ['Closed']

    if current_state in invalid_status:
        raise Exception(
            'Issue is in an invalid state <{0}>, stopping process.'.format(current_state))

    # Transition issue to valid status
    if current_state in editable_status:
        transition_issue(jira_issue)
    else:
        logs.append('Issue is not in an editable status <{0}>, skipping transition.'.format(
            current_state
        ))

    # Fill <instance> field
    if not jira_issue['test_instance'] or jira_issue['test_instance'] != instance:
        edit_issue(jira_issue, instance)
    else:
        logs.append('Issue is already configured for instance ({0}), skipping configuration.'.format(
            instance))

    return True


def transition_issue(jira_issue):
    if not jira_auth:
        raise Exception('Issue cannot be modified without Jira credentials.')

    in_dev = 'IN DEVELOPMENT'
    transition_endpoint = '{0}/issue/{1}/transitions'.format(
        JIRA_API, jira_issue['key'])
    response = api_query(transition_endpoint, auth=jira_auth['auth'])

    available_transitions = list(map(
        lambda s: {'id': s['id'], 'status': s['to']
                   ['name'], 'name': s['name']},
        response['transitions']
    ))
    logs.append(available_transitions)
    dev_transition = list(
        filter(lambda t: t['status'] == in_dev, available_transitions))[0]

    # Transition not available
    if not dev_transition:
        return True

    # Transition
    data = {'transition': {'id': dev_transition['id']}}

    logs.append('POST {0}\n{1}'.format(transition_endpoint, json.dumps(data, indent=4)))

    if dryrun:
        return True

    response = requests.post(transition_endpoint,
                             auth=jira_auth['auth'],
                             data=json.dumps(data),
                             headers={
                                 'Content-type': 'application/json',
                                 'Accept': 'application/json'
                             })

    logs.append('Transitioned issue, response: ')
    logs.append(response.status_code, response.headers, response.text)

    failed = api_failed(response, transition_endpoint, exit_on_error=False)
    if failed:
        logs.append('Status transition failed, please move the issue manually in Jira.')
        return False

    return True


def edit_issue(jira_issue, instance):
    if not jira_auth:
        raise Exception('Issue cannot be modified without Jira credentials.')

    endpoint = '{0}/issue/{1}'.format(JIRA_API, jira_issue['key'])
    data = {'fields': {JIRA_INSTANCE_FIELD: [{'value': instance}], }}

    if dryrun:
        logs.append("PUT {0}\n{1}".format(endpoint, json.dumps(data, indent=4)))
        return True

    response = requests.put(endpoint,
                            auth=jira_auth['auth'],
                            data=json.dumps(data),
                            headers={'Content-type': 'application/json'})
    failed = api_failed(response, endpoint, exit_on_error=False)
    if failed:
        raise Exception(
            'Issue could not be edited, instance booking process has failed.')

    return True


"""

Instances

"""


def get_available_instance(randomize=False):
    """
    fetch instances from swarm | filter available
    fetch last commit date on each, reverse order for a steady rotation
    return oldest available instance
    """
    instances = get_instances()

    available_list = list(filter(lambda name: instances[name] == 1, instances))

    if not len(available_list):
        raise Exception('No available instance could be found.')

    if randomize:
        random.shuffle(available_list)
        return available_list[0]

    dated_list = list(
        map(lambda name: [name, get_last_commit_date(INSTANCE_REPO_PREFIX + name)], available_list))

    dated_list.sort(key=lambda i: i[1])

    return dated_list[0][0]


def get_instances():
    """
    Uses cloud function also used on https://greenpeace.github.io/planet4-test-swarm/

    Return swarm instances
    """
    return api_query(SWARM_API)


"""

API stuff

"""


def get_jira_auth():
    """
    Based on env variables

    https://developer.atlassian.com/server/jira/platform/oauth/
    """

    if os.getenv('JIRA_CLIENT_KEY'):
        if os.getenv('JIRA_PRIVATE_KEY'):
            key = os.getenv('JIRA_PRIVATE_KEY')
        else:
            key = None

        return {
            'type': 'oauth',
            'auth': OAuth1(
                os.getenv('JIRA_CLIENT_KEY'),
                resource_owner_key=os.getenv('JIRA_OAUTH_TOKEN'),
                resource_owner_secret=os.getenv('JIRA_OAUTH_SECRET'),
                rsa_key=key,
                signature_method=SIGNATURE_RSA,
            )
        }

    return {
        'type': 'basic',
        'auth': HTTPBasicAuth(os.getenv('JIRA_USERNAME'), os.getenv('JIRA_PASSWORD'))
    } if os.getenv('JIRA_USERNAME') else {}


def save_results(results, filename='booking-results.json'):
    with open(filename, 'w') as results_file:
        json.dump(results, results_file, indent=2)


"""

Main

"""

if __name__ == '__main__':

    # Options
    parser = argparse.ArgumentParser()
    parser.add_argument("--pr-url",
                        help="pull request URL")
    parser.add_argument("-n", "--dryrun", action="store_true",
                        help="gives a course of action but doesn't execute")
    parser.add_argument("--no-cache", action="store_true",
                        help="Disable request cache use")
    parser.add_argument("--no-booking", action="store_true",
                        help="Disable instance booking action")
    parser.add_argument("--results", default="booking-results.json",
                        help=("Save result in json to the specified file "
                              "(default booking-results.json)"))
    args = parser.parse_args()

    # Parsed options
    pr_url = args.pr_url if args.pr_url else os.getenv('CIRCLE_PULL_REQUEST')
    dryrun = args.dryrun
    results_file = args.results

    # Logs
    logs = []

    # Auth
    jira_auth = get_jira_auth()

    # Main program

    logs.append('# Running for {0}'.format(pr_url))
    if dryrun:
        logs.append('## Dry run, nothing will be commited.')

    # Fetch PR details
    pr_endpoint, _ = get_pull_request(pr_url=pr_url)
    if not pr_endpoint:
        raise Exception('No pull request found, aborting.')

    pr = api_query(pr_endpoint)

    # Fetch issue details from Github PR
    issue = get_jira_issue(pr=pr)

    # If not a ticket PR just get an available instance
    # Reverse the order to avoid race condition
    if not issue:
        instance = get_available_instance(randomize=True)
    else:
        # Use pre-booked instance or get a new one
        if issue['test_instance']:
            instance = issue['test_instance']
            logs.append('Issue is already deployed on {0}, reusing.'.format(instance))
        else:
            instance = get_available_instance()

        book_instance(instance, issue)

    if results_file:
        save_results({
            'instance': instance,
            'issue': issue,
            'pr': pr,
            'logs': logs,
        }, results_file)

    print(instance)
