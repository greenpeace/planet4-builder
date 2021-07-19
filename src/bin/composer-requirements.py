#!/usr/bin/env python3
import json
import os
import sys


def merge_requirements(env_data, local_data):
    try:
        env_require = env_data['require']
    except KeyError:
        print('No environment specific requirements')
        exit(0)

    local_data['require'].update(env_require)

    return local_data


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print('Argument are missing.\n Syntax: {0} <composer> <environment>'.format(sys.argv[0]))
        exit(1)

    composer = sys.argv[1]
    environment = sys.argv[2]
    directory = os.path.split(composer)[0]

    try:
        env_file = open('{0}/{1}.json'.format(directory, environment), 'r')
    except FileNotFoundError:
        print('No environment specific requirements')
        exit(0)

    try:
        local_file = open(composer, 'r')
    except FileNotFoundError:
        print('No local specific requirements')
        exit(0)

    env_data = json.loads(env_file.read())
    env_file.close()
    local_data = json.loads(local_file.read())
    local_file.close()

    merged_data = merge_requirements(env_data, local_data)
    composer_final = json.dumps(merged_data, indent=4)

    with open(composer, 'w') as f:
        f.write(composer_final)

    print(composer_final)

    exit(0)
