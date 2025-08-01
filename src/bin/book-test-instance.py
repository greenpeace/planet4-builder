#!/usr/bin/env python3

import argparse
from base64 import b64decode
from jira import JIRA
import json
import os
import re
import sys

from p4.apis import api_query
from p4.github import (get_last_commit_date, get_repo_endpoints,
                       get_pr_test_instance, has_open_pr_labeled_with_instance,
                       add_issue_label)

JIRA_SERVER = 'https://greenpeace-planet4.atlassian.net/'
JIRA_USER = os.getenv('JIRA_USER')
JIRA_TOKEN = os.getenv('JIRA_TOKEN')
GITHUB_API = 'https://api.github.com'
SWARM_API = 'https://us-central1-planet-4-151612.cloudfunctions.net/p4-test-swarm'
INSTANCE_REPO_PREFIX = 'greenpeace/planet4-test-'


def get_jira_issue(pr=None):
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

    token = b64decode(JIRA_TOKEN).decode('utf-8').replace('\n', '')
    jira = JIRA(server=JIRA_SERVER, basic_auth=(JIRA_USER, token))

    try:
        issue = jira.issue(jira_key)
    except:  # noqa: E722
        print('No such ticket')
        sys.exit(1)

    return issue


def book_instance(instance, issue):
    """
    Check jira issue status & assigned instance
    Move status if needed, book instance on issue

    @todo: make issue a list of issues,
    loop through it to be able to lock multiple issues to one instance & pr
    """

    current_state = issue.fields.status.name
    invalid_status = ['Closed', 'Open']

    if current_state in invalid_status:
        raise Exception(
            'Issue is in an invalid state <{0}>, stopping process.'.format(current_state))

    # Fill <instance> field
    if (not issue.fields.customfield_10201 or issue.fields.customfield_10201[0].value != instance):
        issue.update(fields={'customfield_10201': [{'value': instance}]})
    else:
        logs.append('Issue is already configured for instance ({0}),'
                    ' skipping configuration.'.format(instance))

    return True


def get_available_instance():
    """
    fetch instances from swarm | filter available
    fetch last commit date on each, reverse order for a steady rotation
    return oldest available instance
    """
    instances = get_instances()
    logs.append('Swarm response {0}'.format(json.dumps(instances, indent=4)))

    available_list = list(filter(lambda name: instances[name] == 1, instances))

    if not len(available_list):
        raise Exception('No available instance could be found.')

    not_used_with_label = list(
        filter(
            lambda name: not has_open_pr_labeled_with_instance(name, logs),
            available_list
        ))

    dated_list = list(
        map(lambda name: [name, get_last_commit_date(INSTANCE_REPO_PREFIX + name)],
            not_used_with_label))

    dated_list.sort(key=lambda i: i[1])

    if not len(dated_list):
        raise Exception('No available instance after checking Github labels.')

    return dated_list[0][0]


def get_instances():
    """
    Uses cloud function also used on https://greenpeace.github.io/planet4-test-swarm/

    Return swarm instances
    """
    return api_query(SWARM_API)


def save_results(results, filename='booking-results.json'):
    with open(filename, 'w') as results_file:
        json.dump(results, results_file, indent=2)


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

    # Main program

    logs.append('# Running for {0}'.format(pr_url))
    if dryrun:
        logs.append('## Dry run, nothing will be commited.')

    # Fetch PR details
    pr_endpoint, _ = get_repo_endpoints(pr_url=pr_url)
    if not pr_endpoint:
        raise Exception('No pull request found, aborting.')

    pr = api_query(pr_endpoint)

    # Fetch issue details from Github PR
    issue = get_jira_issue(pr=pr)

    # If not an issue PR just get an available instance
    # Reverse the order to avoid race condition
    instance = None
    if not issue:
        instance = get_pr_test_instance(pr_endpoint)
        issue_key = None
    else:
        # Use pre-booked instance or get a new one
        test_instance = None
        issue_key = issue.key
        if issue.fields.customfield_10201:
            test_instance = issue.fields.customfield_10201[0].value
        if test_instance:
            instance = test_instance
            logs.append('Issue is already deployed on {0}, reusing.'.format(instance))

    if not instance:
        instance = get_available_instance()
        label_name = '[Test Env] {0}'.format(instance)
        add_issue_label(pr_endpoint, label_name)
        if issue:
            book_instance(instance, issue)

    if results_file:
        save_results({
            'instance': instance,
            'issue': issue_key,
            'pr': pr,
            'logs': logs,
        }, results_file)

    print(instance)
