#!/usr/bin/env python3

import argparse
from datetime import datetime
import os

from p4.github import get_pull_request, check_for_comment, post_pr_comment

TEST_INSTANCE_PREFIX = 'https://www-dev.greenpeace.org/test-'


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
    response = post_pr_comment(pr_endpoint, comments_endpoint, comment_id, body)
    print(response)

