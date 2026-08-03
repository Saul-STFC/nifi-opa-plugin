# DESCRIPTION
# This file contains the permissions for the root components in your flow.
# A root component is every component on Level 1 (NiFi Flow it self) and
# Level 2 which are all components located directly in the NiFi Flow (those you see
# when you log into the Web-UI).
# [IMPORTANT] Those permissions are set using the future name of the component.
# Thus the permissions can be created before the components even exist.
#
# The available access policy discriptors can be found here:
# https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#access-policies

package nifi_root_policies

root_policies := {
    "/processors": {
    },

    "/process-groups": {
        "Projekt1":{
            "read": {
                "users": ["User1", "User2", "User3"],
                "groups": []
            },
            "write": {
                "users": ["User1", "User2", "User3"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        },

        "Peter":{
            "read": {
                "users": ["User1"],
                "groups": ["Group2","Group234"]
            },
            "write": {
                "users": ["User1"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": ["denyGroup"]
            }
        },

        "Otto":{
            "read": {
                "users": ["User2"],
                "groups": []
            },
            "write": {
                "users": ["User2"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        },

        "NiFi Flow":{
            "read": {
                "users": ["User1", "User2"],
                "groups": []
            },
            "write": {
                "users": ["User1", "User2"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        }
    },

    "/operation": {
        "Peter":{
            "read": {
                "users": ["User1"],
                "groups": []
            },
            "write": {
                "users": ["User1"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        },

        "Otto":{
            "read": {
                "users": ["User2"],
                "groups": []
            },
            "write": {
                "users": ["User2"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        }
    },

    "/provenance-data": {
        "Peter":{
            "read": {
                "users": ["User1"],
                "groups": []
            },
            "write": {
                "users": ["User1"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        },

        "Otto":{
            "read": {
                "users": ["User2"],
                "groups": []
            },
            "write": {
                "users": ["User2"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        }
    },

    "/data" : {
        "Peter":{
            "read": {
                "users": ["User1"],
                "groups": []
            },
            "write": {
                "users": ["User1"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        },

        "Otto":{
            "read": {
                "users": ["User2"],
                "groups": []
            },
            "write": {
                "users": ["User2"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        }
    },

    "/policies": {
        "Peter":{
            "read": {
                "users": ["User1"],
                "groups": []
            },
            "write": {
                "users": ["User1"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        },

        "Otto":{
            "read": {
                "users": ["User2"],
                "groups": []
            },
            "write": {
                "users": ["User2"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        }
    },

    "/data-transfer/input-ports": {
        "Peter":{
            "read": {
                "users": ["User1"],
                "groups": []
            },
            "write": {
                "users": ["User1"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        },

        "Otto":{
            "read": {
                "users": ["User2"],
                "groups": []
            },
            "write": {
                "users": ["User2"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        }
    },

    "/data-transfer/output-ports": {
        "Peter":{
            "read": {
                "users": ["User1"],
                "groups": []
            },
            "write": {
                "users": ["User1"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        },

        "Otto":{
            "read": {
                "users": ["User2"],
                "groups": []
            },
            "write": {
                "users": ["User2"],
                "groups": []
            },
            "deny": {
                "users": [],
                "groups": []
            }
        }
    }
}
