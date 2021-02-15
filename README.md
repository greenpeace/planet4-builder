# Planet 4 Build Container

![Planet4](./planet4.png)

Responsible for building and deploying Planet 4 containers on our Kubernetes clusters.

## Development

Jusr run make, or if you prefer to run it step-by-step:

```
make init
make prepare
make lint
make build
```

### Requirements

1. Shellcheck
2. Docker
3. jq
4. yamllint
6. composer
7. shfmt
