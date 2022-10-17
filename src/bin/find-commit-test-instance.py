#!/usr/bin/env python3
# For a given commit hash it tries to find which test instance
# was used in its PR.

import argparse
import os
from github import Github

from p4.github import get_pr_test_instance


if __name__ == '__main__':

    # Options
    parser = argparse.ArgumentParser()
    parser.add_argument("--commit_sha",
                        help="Commit SHA")
    parser.add_argument("--commit_repo",
                        help="Repository slug")
    args = parser.parse_args()

    # Parsed options
    commit_sha = args.commit_sha if args.commit_sha else os.getenv('CIRCLE_SHA1')
    commit_repo = args.commit_repo if args.commit_repo else os.getenv('CIRCLE_PROJECT_REPONAME')

    # Authentication
    oauth_key = os.getenv('GITHUB_OAUTH_TOKEN')
    g = Github(oauth_key)

    repo = g.get_repo(commit_repo)
    commit = repo.get_commit(sha=commit_sha)
    try:
        pr = commit.get_pulls()[0]
    except IndexError:
        raise Exception('No pull request found, aborting.')

    instance = get_pr_test_instance(pr.url)

    print(instance)
