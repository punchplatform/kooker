#!/bin/sh

kcadm="/opt/keycloak/bin/kcadm.sh"

# ---------------------------
# ----- Utils functions -----
# ---------------------------

# These functions are used to interact with the keycloak server
# It uses the kcadm command, which is a command line tool to interact with the keycloak server
# See https://www.keycloak.org/docs/latest/server_admin/index.html#admin-cli
# To sum up, each command is equivalent to a REST API call :
# - create : POST
# - update : PUT
# - get : GET
# - delete : DELETE
# And each resource is identified by a path, for example :
# - users : /auth/admin/realms/{realm}/users
# - clients : /auth/admin/realms/{realm}/clients
# - roles : /auth/admin/realms/{realm}/roles
# - role-mappings : /auth/admin/realms/{realm}/users/{id}/role-mappings/clients/{client}
# For example, this command :
# kcadm get users -r <realm>
# is equivalent to this REST API call :
# GET /auth/admin/realms/{realm}/users
# More info on keycloak endpoints : https://www.keycloak.org/docs-api/21.0.2/rest-api/index.html

# Initialize the connection to the keycloak server
# This function must be called before any other function
init_keycloak_connection() {
  server=$1
  realm=$2
  user=$3
  password=$4
  $kcadm config credentials --server "$server" --realm "$realm" --user "$user" --password "$password"
}

# Get the id of an object from its name
# Useful to get the id of a client or a user, which is needed to interact with it
get_object_id() {
  realm=$1
  object=$2
  nameField=$3
  name=$4
  id=$($kcadm get "$object" -r "$realm" -q "$nameField=$name" --fields id |
    sed -n 's/\s*"id" : "\([a-zA-Z0-9\-]*\)"/\1/p')
  echo "$id"
}

# Import a user in the realm
# If the user already exists, it will be updated, otherwise it will be created
import_user() {
  realm=$1
  user=$2
  content=$3
  userId=$(get_object_id "$realm" users username "$user")
  if [ -z "$userId" ]; then
    echo "Create user $user"
    $kcadm create users -r "$realm" -f - <<EOF
$content
EOF
  else
    echo "Update user $user"
    $kcadm update users/"$userId" -r "$realm" -f - <<EOF
$content
EOF
  fi
}

# Import a client in the realm
# If the client already exists, it will be updated, otherwise it will be created
import_client() {
  realm=$1
  client=$2
  content=$3
  clientId=$(get_object_id "$realm" clients clientId "$client")
  if [ -z "$clientId" ]; then
    echo "Create client $client"
    $kcadm create clients -r "$realm" -f - <<EOF
$content
EOF
  else
    echo "Update client $client"
    $kcadm update clients/"$clientId" -r "$realm" -f - <<EOF
$content
EOF
  fi
}

# Import a role in the realm
# If the role already exists, it will be updated, otherwise it will be created
import_client_role() {
  realm=$1
  client=$2
  role=$3
  content=$4
  clientId=$(get_object_id "$realm" clients clientId "$client")
  roleExists=$($kcadm get clients/"$clientId"/roles/"$role" -r "$realm" --fields id 2>/dev/null)
  if [ -z "$roleExists" ]; then
    echo "Create role $role for client $client"
    $kcadm create clients/"$clientId"/roles -r "$realm" -f - <<EOF
$content
EOF
  else
    echo "Update role $role for client $client"
    $kcadm update clients/"$clientId"/roles/"$role" -r "$realm" -f - <<EOF
$content
EOF
  fi
}

# Import a client secret.
# Update existing client with the new secret.
import_client_secret() {
  realm=$1
  client=$2
  secret=$3
  clientId=$(get_object_id "$realm" clients clientId "$client")
  echo "Update client $client with provided secret"
  $kcadm update clients/"$clientId" -r "$realm" -f - <<EOF
{"secret": "$secret"}
EOF
}

# Import client redirect URIs.
# Update existing client with the new redirect URIs.
import_client_redirect_uris() {
  realm=$1
  client=$2
  redirectUris=$3
  clientId=$(get_object_id "$realm" clients clientId "$client")
  echo "Update client $client with provided redirect URIs"
  $kcadm update clients/"$clientId" -r "$realm" -f - <<EOF
{"redirectUris": [ $redirectUris ] }
EOF
}

# Assign roles to a user for a client
# The clientRoles parameter is a list of client/role pairs
# The role can be a list of roles separated by a space
# For example :
# assign_user_role "$realm" "$user" "punch-board" "admin editor" "artifacts-server" "admin"
assign_user_role() {
  realm=$1
  user=$2
  shift 2
  userId=$(get_object_id "$realm" users username "$user")
  while [ $# -gt 0 ]; do
    client=$1
    roles=$2
    clientId=$(get_object_id "$realm" clients clientId "$client")
    for role in $roles; do
      echo "Assign role '$role' to user '$user' for client '$client'"
      role_json="[$($kcadm get "clients/$clientId/roles/$role" -r "$realm" --fields id,name)]"
      $kcadm create "users/$userId/role-mappings/clients/$clientId" -r "$realm" -x -f - <<EOF
$role_json
EOF
      echo
    done
    shift 2
  done
}
