# Planet 4 Build Container

![Planet4](./planet4.png)

Container for running our CI operations.
Responsible for building and deploying Planet 4 containers on our Kubernetes clusters.

---

The base image builds upon CircleCI's next image: `cimg/php-node` image and adds the packages
defined in `config.default`.

## Development

Jusr run make, or if you prefer to run it step-by-step:

```
make init
make prepare
make lint
make build
make test
```

### Requirements

1. Docker
2. Shellcheck
3. jq
4. yamllint
6. composer
7. shfmt
