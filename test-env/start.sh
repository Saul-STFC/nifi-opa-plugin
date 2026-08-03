#!/usr/bin/env bash
echo "### Starting test environment..."
docker compose up -d
sleep 5s
echo "### Inserting authorizers.xml into Apache NiFi Container..."
docker cp ./authorizers-opa.xml test-env-nifi-1:/opt/nifi/nifi-current/conf/authorizers.xml
