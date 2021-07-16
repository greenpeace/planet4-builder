import json
import os
import re
import requests

from p4.apis import api_query


GITHUB_API = 'https://api.github.com'


def get_pull_request(pr_url):
    """
    Creates API endpoint for a give PR url
    """

    regex = re.compile('https://github.com/(.*)/pull/([0-9]{1,6})')
    matches = regex.match(pr_url)

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


def get_last_commit_date(repo):
    """
    Return last commit date for a repo.
    """
    commit = api_query(
        GITHUB_API + '/repos/' + repo + '/commits/main',
        {'Accept': 'application/vnd.github.v3+json'}
    )

    return commit['commit']['committer']['date']


def post_pr_comment(pr_endpoint, comment_endpoint, comment_id, body):
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
        response = requests.patch(endpoint, headers=headers, data=json.dumps(data))
        return response.json()

    response = requests.post(pr_endpoint, headers=headers, data=json.dumps(data))
    return response.json()
