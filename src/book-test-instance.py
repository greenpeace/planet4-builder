#!/usr/bin/env python3

import os
import json
import requests
from requests.auth import HTTPBasicAuth
from requests_oauthlib import OAuth1
from oauthlib.oauth1 import SIGNATURE_RSA
import sys
import re
import argparse
import tempfile
import hashlib


JIRA_API = 'https://jira.greenpeace.org/rest/api/2'
GITHUB_API = 'https://api.github.com'
SWARM_API = 'https://us-central1-planet-4-151612.cloudfunctions.net/p4-test-swarm'

INSTANCE_REPO_PREFIX = 'greenpeace/planet4-test-'
JIRA_INSTANCE_FIELD = 'customfield_13000'


def get_pull_request(pr_url):
    """
    Fetch PR details

    Extract data from PR url
    Request PR data
    """

    regex = re.compile('https://github.com/(.*)/pull/([0-9]{1,6})')
    matches = regex.match(pr_url)
    vprint('Parsing URL {0}'.format(matches.groups()))

    repository = matches.group(1) or None
    pr_number = matches.group(2) or None

    if not repository or not pr_number:
        raise Exception('PR id could not be parsed.')

    pr_endpoint = '{0}/repos/{1}/pulls/{2}'.format(
        GITHUB_API,
        repository,
        pr_number
    )

    return api_query(pr_endpoint, {'Accept': 'application/vnd.github.v3+json'})


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
        raise Exception('Jira issue key could not be found.')

    vprint('Jira key found: {0}'.format(jira_key))
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
        'test_instance': issue['fields'][JIRA_INSTANCE_FIELD][0]['value'] if issue['fields'][JIRA_INSTANCE_FIELD] else None,
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
        vprint('Issue is not in an editable status <{0}>, skipping transition.'.format(
            current_state
        ))

    # Fill <instance> field
    if not jira_issue['test_instance'] or jira_issue['test_instance'] != instance:
        edit_issue(jira_issue, instance)
    else:
        vprint('Issue is already configured for instance ({0}), skipping configuration.'.format(
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
    vprint(available_transitions)
    dev_transition = list(
        filter(lambda t: t['status'] == in_dev, available_transitions))[0]

    # Transition not available
    if not dev_transition:
        return True

    # Transition
    data = {'transition': {'id': dev_transition['id']}}

    vprint('POST {0}\n{1}'.format(transition_endpoint, json.dumps(data, indent=4)))

    if dryrun:
        return True

    response = requests.post(transition_endpoint,
                             auth=jira_auth['auth'],
                             data=json.dumps(data),
                             headers={
                                 'Content-type': 'application/json',
                                 'Accept': 'application/json'
                             })

    vprint('Transitioned issue, response: ');
    vprint(response, response.text, response.headers)

    failed = api_failed(response, transition_endpoint, exit_on_error=False)
    if failed:
        vprint('Status transition failed, please move the issue manually in Jira.')
        return False

    return True


def edit_issue(jira_issue, instance):
    if not jira_auth:
        raise Exception('Issue cannot be modified without Jira credentials.')

    endpoint = '{0}/issue/{1}'.format(JIRA_API, jira_issue['key'])
    data = {'fields': {JIRA_INSTANCE_FIELD: [{'value': instance}], }}

    if dryrun:
        vprint("PUT {0}\n{1}".format(endpoint, json.dumps(data, indent=4)))
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


def get_available_instance():
    """
    fetch instances from swarm | filter available
    fetch last commit date on each, reverse order for a steady rotation
    return oldest available instance
    """
    instances = get_instances()

    available_list = list(filter(lambda name: instances[name] == 1, instances))
    dated_list = list(
        map(lambda name: [name, get_instance_last_commit_date(name)], available_list))

    dated_list.sort(key=lambda i: i[1])

    if not dated_list[0][0]:
        raise Exception('No available instance could be found.')

    return dated_list[0][0]


def get_instances():
    """
    Uses cloud function also used on https://greenpeace.github.io/planet4-test-swarm/

    Return swarm instances
    """
    return api_query(SWARM_API)


def get_instance_last_commit_date(instance):
    """
    Return last commit date for an instance repo
    """
    commit = api_query(
        GITHUB_API + '/repos/' + INSTANCE_REPO_PREFIX + instance + '/commits/develop',
        {'Accept': 'application/vnd.github.v3+json'}
    )

    return commit['commit']['committer']['date']


"""

API stuff

"""


def api_query(url, headers={'Accept': 'application/json'}, auth=None):
    """
    Queries API
    - fails on error
    - return json
    - use cache if requested
    """

    vprint('GET {0}'.format(url))

    cache_file = '/tmp/{0}.cache'.format(hashlib.md5(url.encode()).hexdigest())
    if use_request_cache and os.path.isfile(cache_file):
        vprint('Using cache for ' + url)
        return json.load(open(cache_file))

    response = requests.get(url, headers=headers, auth=auth)
    api_failed(response, url)

    content = response.json()

    if use_request_cache:
        vprint(url, ' -> ', cache_file)

    json.dump(content, open(cache_file, "w"))  # write anyway
    return content


def api_failed(response, endpoint, exit_on_error=True):
    """
    Check if api request failed

    Can raise exception
    """

    if 200 <= response.status_code < 300:
        return False

    vprint('API call failed')
    vprint(response, response.text, response.headers)
    if exit_on_error:
        raise Exception("Status code {0} calling {1}".format(
            response.status_code, endpoint))
    return True


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
    parser.add_argument("-v", "--verbosity", action="count", default=0,
                        help="increase output verbosity")
    parser.add_argument("--no-cache", action="store_true",
                        help="Disable request cache use")
    parser.add_argument("--no-booking", action="store_true",
                        help="Disable instance booking action")
    parser.add_argument("--results", default="booking-results.json",
                        help="Save result in json to the specified file (default booking-results.json)")
    args = parser.parse_args()

    # Parsed options
    pr_url = args.pr_url if args.pr_url else os.getenv('CIRCLE_PULL_REQUEST')
    dryrun = args.dryrun
    verbose = args.verbosity
    use_request_cache = not args.no_cache
    results_file = args.results
    # Logs
    logs = []
    def vprint(*args):
        for msg in args:
            logs.append(msg)
            if verbose:
                print(msg)
    # Auth
    jira_auth = get_jira_auth()

    # Main program

    vprint('# Running for {0}'.format(pr_url))
    if dryrun:
        vprint('## Dry run, nothing will be commited.')

    # Fetch PR details
    pr = get_pull_request(pr_url=pr_url)
    if not pr:
        raise Exception('No pull request found, aborting.')

    # Fetch issue details from Github PR
    try:
        issue = get_jira_issue(pr=pr)
    except Exception as e:
        vprint(e)
        issue = None

    # Define instance
    if not issue:
        raise Exception('No corresponding issue found, booking will not be executed.')

    if issue['test_instance']:
        instance = issue['test_instance']
        vprint('Issue is already deployed on {0}, reusing.'.format(instance))
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
