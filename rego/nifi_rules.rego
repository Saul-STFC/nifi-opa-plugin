# DESCRIPTION
# This file is the ENTRYPOINT of the rego rules.
#
# In general "implicit" means something is done without being set by the administrator
# like automatic inheritance or a value not set at all
#
# In general "explicit" means something is explicitly set by the administrator
# like an overwriten inheritance or set permissions in general

package nifi

import rego.v1

import data.nifi_inp
import data.nifi_glob
import data.nifi_comp

# default return values
default allow = {
    "resourceNotFound": true,
    "dumpCache": true
}

### GLOBAL POLICIES

# check for reading permission
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_glob.res_is_global_type
    nifi_inp.action == "read"
    nifi_glob.global_policy_read
}

# check for writing permission
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_glob.res_is_global_type
    nifi_inp.action == "write"
    nifi_glob.global_policy_write
}

# check for full permission when action is read
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_glob.res_is_global_type
    nifi_inp.action == "read"
    nifi_glob.global_policy_full
}

# check for full permission when action is write
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_glob.res_is_global_type
    nifi_inp.action == "write"
    nifi_glob.global_policy_full
}

# check for denied permission
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on global resource %s denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_glob.res_is_global_type
    nifi_glob.global_policy_denied
}


### ROOT COMPONENT POLICIES


## check for flow permission

# explicit allowed
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_comp.comp_is_root_type
    nifi_inp.resource_name == "NiFi Flow"
    nifi_inp.inherit_resource_name == "NiFi Flow"
    nifi_comp.flow_allowed
}

# implicit denied
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on component %s is implicity denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_root_type
    nifi_inp.resource_name == "NiFi Flow"
    nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_comp.flow_allowed
}


## check for root component permission

# explicit root-inherit allowed
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_comp.comp_is_root_type
    nifi_inp.inherit_resource_name == "NiFi Flow"
    nifi_comp.comp_exists_as_root
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.root_comp_allowed
}

# implicit root-inherit denied
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on component %s is implicity denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_root_type
    nifi_inp.inherit_resource_name == "NiFi Flow"
    nifi_comp.comp_exists_as_root
    not nifi_inp.resource_name == "NiFi Flow"
    not nifi_comp.root_comp_allowed
}

# explicit root-inherit denied
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on component %s is explicitly denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_root_type
    nifi_inp.inherit_resource_name == "NiFi Flow"
    nifi_comp.comp_exists_as_root
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.root_comp_denied
}


## check for non-root component permission

# explicit root component allowed
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_comp.comp_is_root_type
    not nifi_inp.inherit_resource_id == nifi_inp.resource_id
    not nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.inherit_comp_exists_as_root
    not nifi_comp.comp_exists_as_root
    nifi_comp.root_inherit_comp_allowed
}

# implicit denied
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on component %s is implicity denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_root_type
    not nifi_inp.inherit_resource_id == nifi_inp.resource_id
    not nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.inherit_comp_exists_as_root
    not nifi_comp.root_inherit_comp_allowed
}


## check for illegal 'non-root equals root name' component name
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Multiple use of root component name %s detected.", [nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_root_type
    not nifi_inp.inherit_resource_id == nifi_inp.resource_id
    nifi_inp.inherit_resource_name == nifi_inp.resource_name
    nifi_comp.inherit_comp_exists_as_root
    nifi_comp.root_inherit_comp_denied
}


### node COMPONENT POLICIES

# explicit node component allowed
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_comp.comp_is_node_type
    not nifi_comp.comp_is_root_type
    not nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.comp_exists_as_node
    nifi_comp.node_comp_allowed
}

# explicit node component permission changed
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on component %s is implicitly denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_node_type
    not nifi_comp.comp_is_root_type
    not nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.comp_exists_as_node

    not nifi_comp.node_comp_denied
    not nifi_comp.node_comp_allowed
}

# explicit node denied
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on component %s is explicity denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_node_type
    not nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.comp_exists_as_node
    nifi_comp.node_comp_denied
}


### INHERIT node COMPONENT POLICIES

# explicit node component allowed
allow := {
    "allowed": true,
    "dumpCache": true
} if {
    nifi_comp.comp_is_node_type
    not nifi_comp.comp_exists_as_root
    not nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.inherit_comp_exists_as_node
    nifi_comp.node_inherit_comp_allowed
}

# implicit node component permission changed
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on component %s is implicitly denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_node_type
    not nifi_comp.comp_exists_as_root
    not nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.inherit_comp_exists_as_node
    not nifi_comp.node_inherit_comp_allowed
    not nifi_comp.node_inherit_comp_denied
}

# explicit node denied
allow := {
    "allowed": false,
    "dumpCache": true,
    "message": sprintf("Action %s on component %s is explicity denied.", [nifi_inp.action, nifi_inp.resource_name])
} if {
    nifi_comp.comp_is_node_type
    not nifi_comp.comp_exists_as_root
    not nifi_inp.inherit_resource_name == "NiFi Flow"
    not nifi_inp.resource_name == "NiFi Flow"
    nifi_comp.inherit_comp_exists_as_node
    nifi_comp.node_inherit_comp_denied
}
