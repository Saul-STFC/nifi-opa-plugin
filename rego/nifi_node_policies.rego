# DESCRIPTION
# This file contains the permissions for the node components in your flow.
# A node component is every component on Level 3 or higher. So every component
# that is contained in the components on the canvas you see after the login.
# [IMPORTANT] Those permissions are set using the UUID of the component.
# Thus the permissions can only be created if the component is already existing.
#
# The available access policy discriptors can be found here:
# https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#access-policies

package nifi_node_policies

node_policies := {
    "/processors": {
        "88bfd170-0193-1000-f96d-e7b2d9491f59":{
            "read": {
                "users": [],
                "groups": []
            },
            "write": {
                "users": [],
                "groups": []
            },
            "deny": {
                "users": ["User1"],
                "groups": []
            }
        }
    },

    "/process-groups": {
        "917f4d3b-0193-1000-15cd-ede4486f3677":{
            "read": {
                "users": [],
                "groups": []
            },
            "write": {
                "users": [],
                "groups": []
            },
            "deny": {
                "users": ["User1"],
                "groups": []
            }
        },

        "91b2a4e0-0193-1000-e4e4-8a807d160662":{ #User1Private
            "read": {
                "users": [],
                "groups": []
            },
            "write": {
                "users": [],
                "groups": []
            },
            "deny": {
                "users": ["User2"],
                "groups": []
            }
        }
    },

    "/operation": {
    },

    "/provenance-data": {

    },

    "/data" : {

    },

    "/policies": {

    },

    "/data-transfer/input-ports": {

    },

    "/data-transfer/output-ports": {

    }
}
