import hashlib
import json
import os
import requests


def api_query(url, headers={'Accept': 'application/json'}, auth=None, use_request_cache=True):
    """
    Queries API
    - fails on error
    - return json
    - use cache if requested
    """

    cache_file = '/tmp/{0}.cache'.format(hashlib.md5(url.encode()).hexdigest())
    if use_request_cache and os.path.isfile(cache_file):
        return json.load(open(cache_file))

    response = requests.get(url, headers=headers, auth=auth)
    api_failed(response, url)

    content = response.json()

    json.dump(content, open(cache_file, "w"))  # write anyway
    return content


def api_failed(response, endpoint, exit_on_error=True):
    """
    Check if api request failed

    Can raise exception
    """

    if 200 <= response.status_code < 300:
        return False

    if exit_on_error:
        raise Exception("Status code {0} calling {1}".format(
            response.status_code, endpoint))
    return True
