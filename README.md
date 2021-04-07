
# Planet 4 CircleCI container

Container for running our CI operations.

---

The base image builds upon CircleCI's next image: `cimg/php-node` image and adds:
-   [ag](https://github.com/ggreer/the_silver_searcher)
-   [bats](https://www.npmjs.com/package/bats)
-   [gcloud](https://cloud.google.com/sdk/docs/#install_the_latest_cloud_tools_version_cloudsdk_current_version)
-   [git-flow](https://github.com/petervanderdoes/gitflow-avh)
-   [hadolint](https://github.com/hadolint/hadolint)
-   [helm2](https://github.com/kubernetes/helm)
-   [helm3](https://github.com/kubernetes/helm)
-   [junit-merge](https://www.npmjs.com/package/junit-merge)
-   [shellcheck](https://github.com/koalaman/shellcheck)
-   [shfmt](https://github.com/mvdan/sh)
-   [tap-xunit](https://github.com/aghassemi/tap-xunit)
-   [trivy](https://github.com/aquasecurity/trivy)
-   [yamllint](https://pypi.org/project/yamllint)
-   [yq](https://pypi.org/project/yq)

## Development

Jusr run `make`, or if you prefer to run it step-by-step:

```
make init
make prepare
make lint
make build
make test
```

### Requirements

1.  Docker
2.  yamllint
