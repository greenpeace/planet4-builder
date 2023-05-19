#!/usr/bin/env bash
set -e

if [ "$APP_ENVIRONMENT" = 'production' ]; then
  echo "Production environment: skipping test user creation"
  exit 0
fi

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" \
  --sort-by=.metadata.creationTimestamp \
  --field-selector=status.phase=Running \
  -l "release=${HELM_RELEASE},component=php" \
  -o jsonpath="{.items[-1:].metadata.name}")

if [[ -z "$php" ]]; then
  echo >&2 "ERROR: php pod not found in release ${HELM_RELEASE}"
  exit 1
fi

# Set kubernetes command with namespace
kc="kubectl -n ${HELM_NAMESPACE}"

if ! $kc exec "$php" -- wp user create p4_test_user p4test+user@planet4.test --user_pass="${WP_TEST_USER}" --role=administrator; then
  echo "Test user already exists, updating..."
  $kc exec "$php" -- wp user update p4_test_user --user_email=p4test+user@planet4.test --user_pass="${WP_TEST_USER}" --role=administrator
fi
