#!/usr/bin/env python3
import json
from os import path
import sys


COMPOSER_LOCAL = 'composer-local.json'


def merge_requirements(env_data, local_data):
    env_require = env_data['require']

    for package in env_require:
        if package in local_data['require'].keys():
            local_data['require'][package]=env_require[package]
            print('Found {0}: Replacing with {1}'.format(package, env_require[package]))

    return local_data

if __name__== "__main__":
    if len(sys.argv) < 3:
        print('Argument are missing.\n Syntax: {0} <directory> <environment>'.format(sys.argv[0]))
        exit(1)

    directory = sys.argv[1]
    environment = sys.argv[2]

    try:
        env_file = open('{0}{1}.json'.format(directory, environment), 'r')
    except FileNotFoundError:
        print('No environment specific requirements')
        exit(0)

    try:
        local_file = open('{0}{1}'.format(directory, COMPOSER_LOCAL), 'r')
    except FileNotFoundError:
        print('No local specific requirements')
        exit(0)

    env_data = json.loads(env_file.read())
    env_file.close()
    local_data = json.loads(local_file.read())
    local_file.close()

    merged_data = merge_requirements(env_data, local_data)

    with open('{0}{1}'.format(directory, COMPOSER_LOCAL), 'w') as f:
        f.write(json.dumps(merged_data, indent=4))

    exit(0)
