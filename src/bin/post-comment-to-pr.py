#!/usr/bin/env python3

import argparse
import json
import os
import re
import requests

GITHUB_API = 'https://api.github.com'
TEST_INSTANCE_PREFIX = 'https://www-dev.greenpeace.org/test-'


def get_pull_request(pr_url):
    """
    Creates API endpoint for a give PR url
    """

    regex = re.compile('https://github.com/(.*)/pull/([0-9]{1,6})')
    matches = regex.match(pr_url)
    print('Parsing URL {0}'.format(matches.groups()))

    repository = matches.group(1) or None
    pr_number = matches.group(2) or None

    if not repository or not pr_number:
        raise Exception('PR id could not be parsed.')

    pr_endpoint = '{0}/repos/{1}/issues/{2}/comments'.format(
        GITHUB_API,
        repository,
        pr_number
    )

    return pr_endpoint


def post_comment(pr_endpoint, test_instance):
    oauth_key = os.getenv('GITHUB_OAUTH_TOKEN')

    data = {
        'body': '[{0}]({1}{0}) test instance is ready :rocket:'.format(test_instance, TEST_INSTANCE_PREFIX)
    }
    headers = {
        'Authorization': 'token {0}'.format(oauth_key),
        'Accept': 'application/vnd.github.v3+json'
    }

    response = requests.post(pr_endpoint, headers=headers, data=json.dumps(data))

    print(response.json())


if __name__ == '__main__':

    # Options
    parser = argparse.ArgumentParser()
    parser.add_argument("--pr-url",
                        help="pull request URL")
    parser.add_argument("--test-instance",
                        help="test instance used")
    args = parser.parse_args()

    # Parsed options
    pr_url = args.pr_url if args.pr_url else os.getenv('CIRCLE_PULL_REQUEST')
    test_instance = args.test_instance

    # Fetch PR details
    pr_endpoint = get_pull_request(pr_url=pr_url)

    # Post comment
    post_comment(pr_endpoint, test_instance)
