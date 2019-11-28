#!/bin/bash

# This tests that removing the leader from a functioning 2 node leader topology
# service group will continue to perform a succesful roaming update after a new
# member is added to the group and quorum is reestablished.
#
# We will load services on two nodes and perform a rolling update. Next we stop
# the supervisor on the leader node and then load an older version of the service
# on a new node reestablishing quorum. Next we perform an update and expect all
# nodes to update. Prior to https://github.com/habitat-sh/habitat/pull/7167, if
# the newly added node is elected the leader, the follower which has a newer
# version of the service will end up in a state where it is continually updating
# to the older version of the leader, restarting the service and loading the newer
# service, then updating to the older leader version and so on until the end of
# its precious life. Now followers should never consider an older version a
# candidate for updating.

set -xeuo pipefail

hab pkg install core/jq-static -b

test_channel=rolling-$(date '+%s%3N')
test_ident=habitat-testing/nginx/1.17.4/20191115184838

hab pkg promote ${test_ident} ${test_channel}

for server in alpha beta; do
    hab svc load habitat-testing/nginx --topology leader --strategy rolling --channel ${test_channel} --remote-sup=${server}.habitat.dev
done

cleanup () {
    hab bldr channel destroy ${test_channel} --origin habitat-testing
}

sleep 15

for server in alpha beta; do
    current_ident=$(curl -s "${server}.habitat.dev:9631/services/nginx/default" | jq -r '.pkg.ident')
    if [[ "${current_ident}" != "${test_ident}" ]]; then
        echo "Expected nginx ident ${test_ident} on ${server}; got ${current_ident} instead!"
        cleanup
        exit 1
    fi
done

test_ident=habitat-testing/nginx/1.17.4/20191115185517
hab pkg promote ${test_ident} ${test_channel}
sleep 15

for server in alpha beta; do
    current_ident=$(curl -s ${server}.habitat.dev:9631/services/nginx/default | jq -r '.pkg.ident')
    if [[ "${current_ident}" != "${test_ident}" ]]; then
        echo "Expected nginx ident ${test_ident} on ${server}; got ${current_ident} instead!"
        cleanup
        exit 1
    fi
done

body=$(curl -s "bastion.habitat.dev:9631/census")
leader_id=$(echo ${body} | jq -r ".census_groups.\"nginx.default\".leader_id")
leader_name=$(echo ${body} | jq -r ".census_groups.\"nginx.default\".population.\"${leader_id}\".sys.hostname")
docker exec "${COMPOSE_PROJECT_NAME}_${leader_name}_1" hab sup term
docker exec "${COMPOSE_PROJECT_NAME}_gamma_1" hab pkg install habitat-testing/nginx/1.17.4/20191115184838
sleep 10
hab svc load habitat-testing/nginx --topology leader --strategy rolling --channel ${test_channel} --remote-sup=gamma.habitat.dev
sleep 15

test_ident=habitat-testing/nginx/1.17.4/20191115185900
hab pkg promote ${test_ident} ${test_channel}
sleep 15

for server in alpha beta gamma; do
    if [[ "${server}" != "${leader_name}" ]]; then
        current_ident=$(curl -s ${server}.habitat.dev:9631/services/nginx/default | jq -r '.pkg.ident')
        if [[ "${current_ident}" != "${test_ident}" ]]; then
            echo "Expected nginx ident ${test_ident} on ${server}; got ${current_ident} instead!"
            cleanup
            exit 1
        fi
    fi
done

cleanup
