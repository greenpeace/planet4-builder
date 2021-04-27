#!/usr/bin/env python3

import argparse
from datetime import datetime
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

    comments_endpoint = '{0}/repos/{1}/issues/comments/'.format(
        GITHUB_API,
        repository
    )

    return pr_endpoint, comments_endpoint


def check_for_comment(pr_endpoint, title):
    oauth_key = os.getenv('GITHUB_OAUTH_TOKEN')

    headers = {
        'Authorization': 'token {0}'.format(oauth_key),
        'Accept': 'application/vnd.github.v3+json'
    }

    response = requests.get(pr_endpoint, headers=headers)

    for comment in response.json():
        if comment['body'].splitlines()[0] == title:
            return comment['id']

    return False


def post_comment(pr_endpoint, comment_endpoint, comment_id, body):
    oauth_key = os.getenv('GITHUB_OAUTH_TOKEN')

    data = {
        'body': body
    }
    headers = {
        'Authorization': 'token {0}'.format(oauth_key),
        'Accept': 'application/vnd.github.v3+json'
    }

    if comment_id:
        endpoint = '{0}{1}'.format(comment_endpoint, comment_id)
        print(endpoint)
        response = requests.patch(endpoint, headers=headers, data=json.dumps(data))
        return response.json()

    response = requests.post(pr_endpoint, headers=headers, data=json.dumps(data))
    return response.json()


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
    pr_endpoint, comments_endpoint = get_pull_request(pr_url=pr_url)

    # Construct comment body
    now = datetime.now().strftime('%Y.%m.%d %H:%M:%S')
    title = '### Test instance is ready :rocket:'
    msg = (':new_moon: [{0}]({1}{0})\n\n'
           ':watch: {2}').format(
            test_instance, TEST_INSTANCE_PREFIX, now)
    body = '{0}\n\n{1}'.format(title, msg)

    # Post comment, but only once
    comment_id = check_for_comment(pr_endpoint, title)
    # if not exists:
    response = post_comment(pr_endpoint, comments_endpoint, comment_id, body)
    print(response)
