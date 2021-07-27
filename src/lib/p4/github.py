import json
import os
import re
import requests

from p4.apis import api_query


GITHUB_API = 'https://api.github.com'

def get_headers():
    oauth_key = os.getenv('GITHUB_OAUTH_TOKEN')

    return {
        'Authorization': 'token {0}'.format(oauth_key),
        'Accept': 'application/vnd.github.v3+json'
    }


def get_repo_endpoints(pr_url):
    """
    Creates API endpoint for a give PR url
    """

    regex = re.compile('https://github.com/(.*)/pull/([0-9]{1,6})')
    matches = regex.match(pr_url)

    repository = matches.group(1) or None
    pr_number = matches.group(2) or None

    if not repository or not pr_number:
        raise Exception('PR id could not be parsed.')

    pr_endpoint = '{0}/repos/{1}/issues/{2}'.format(
        GITHUB_API,
        repository,
        pr_number
    )

    comment_endpoint = '{0}/repos/{1}/issues/comments/'.format(
        GITHUB_API,
        repository
    )

    return pr_endpoint, comment_endpoint


def check_for_comment(pr_endpoint, title):
    comments_endpoint = '{0}/comments'.format(pr_endpoint)

    response = requests.get(comments_endpoint, headers=get_headers())

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


def post_issue_comment(pr_endpoint, comment_endpoint, comment_id, body):
    data = {
        'body': body
    }
    comments_endpoint = '{0}/comments'.format(pr_endpoint)

    if comment_id:
        endpoint = '{0}{1}'.format(comment_endpoint, comment_id)
        response = requests.patch(endpoint, headers=get_headers(), data=json.dumps(data))
        return response.json()

    response = requests.post(comments_endpoint, headers=get_headers(), data=json.dumps(data))
    return response.json()


def add_issue_label(pr_endpoint, label_name):
    data = {
        'labels': [label_name]
    }
    labels_endpoint = '{0}/labels'.format(pr_endpoint)

    response = requests.post(labels_endpoint, headers=get_headers(), data=json.dumps(data))
    return response.json()


def get_pr_test_instance(pr_endpoint, prefix='[Test Env] '):
    response = requests.get(pr_endpoint, headers=get_headers())

    labels = response.json()['labels']

    for label in labels:
        if label['name'].startswith(prefix):
            return label['name'][len(prefix):]

    return False

def has_open_pr_labeled_with_instance(name):
    BLOCKS_ENDPOINT = 'https://api.github.com/repos/greenpeace/planet4-plugin-gutenberg-blocks/issues?state=open&labels=[Test Env] {0}'
    THEME_ENDPOINT = 'https://api.github.com/repos/greenpeace/planet4-master-theme/issues?state=open&labels=[Test Env] {0}'

    blocks_prs = api_query(BLOCKS_ENDPOINT.format(name), get_headers())
    if len(blocks_prs) > 0:
        return True

    theme_prs = api_query(THEME_ENDPOINT.format(name), get_headers())

    return len(theme_prs) > 0
