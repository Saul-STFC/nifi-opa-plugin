# DESCRIPTION
# This file contains the permissions for the global policies
# that can be found in the NiFi Admin Guide:
# https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#access-policies

package nifi_global_policies

global_policies := {
    "/flow": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {
            "Group 1": "FULL",
            "Test123": "READ"
        }
    },
    "/controller": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/parameter-contexts": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/provenance": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/restricted-components": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/policies": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/tenants": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/site-to-site": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/system": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/proxy": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    },
    "/counters": {
        "users": {
            "User1": "FULL",
            "User2": "READ"
        },
        "groups": {}
    }
}
