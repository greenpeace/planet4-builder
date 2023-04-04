#!/usr/bin/env python3

import os
import argparse
from pycircleci.api import Api

VCS = 'github'
USERNAME = 'greenpeace'

"""

Main

"""

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("--test-instance",
                        help="Test instance name")
    parser.add_argument("--create", action="store_true",
                        help="Create test user")
    parser.add_argument("--delete", action="store_true",
                        help="Delete test user")
    args = parser.parse_args()

    parameters = {
        "run_develop": False,
        "run_create_test_user": args.create,
        "run_delete_test_user": args.delete,
        "unhold": os.getenv('CIRCLE_WORKFLOW_ID', '')
    }
    print(parameters)

    circleci = Api(os.getenv('CIRCLE_TOKEN'))

    response = circleci.trigger_pipeline(
        vcs_type=VCS,
        username=USERNAME,
        project='planet4-test-' + args.test_instance,
        branch='main',
        params=parameters)
    print(response)
