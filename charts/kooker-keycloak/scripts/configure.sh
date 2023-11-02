#!/bin/sh

scriptPath=$(dirname "$0")
source "$scriptPath/functions.sh"

# ----------------
# ----- Main -----
# ----------------

# These are the main steps of the script :
# - Initialize the connection to the keycloak server
# - Import the punch-board client (if enabled)
# - Import the artifacts-server client (if enabled)
# - Import the basic users (if provided)
#   - Import the user
#   - Assign the roles to the user
# - Import the extra users (if provided)
#   - Import the user
#   - Assign the roles to the user

{{ with .Values.keycloak -}}
echo "---------- Initialize connection to {{ .server }} ---------------"

init_keycloak_connection {{ .server }} {{ .realm }} {{ .user }} {{ .password }}
realm={{ .realm }}
{{- end }}

{{ if .Values.punchBoardClient -}}
echo "---------- Import Punch-Board Client ---------------"

{{ with .Files.Get "files/punch-board.json" | fromJson -}}
import_client "$realm" "punch-board" '{{ .clients | first | toJson }}'
{{ range index .roles.client "punch-board" -}}
import_client_role "$realm" "punch-board" "{{ .name }}" '{{ . | toJson }}'
{{ end -}}
{{ end -}}
{{- end }}
{{ if .Values.artifactsServerClient -}}
echo "---------- Import Artifacts-Server Client ---------------"

{{ with .Files.Get "files/artifacts-server.json" | fromJson -}}
import_client "$realm" "artifacts-server" '{{ .clients | first | toJson }}'
{{ range index .roles.client "artifacts-server" -}}
import_client_role "$realm" "artifacts-server" "{{ .name }}" '{{ . | toJson }}'
{{ end -}}
{{ end -}}
{{- end }}
{{ if .Values.basicUsers -}}
echo "---------- Import Basic Users ---------------"

{{ $users := .Files.Get "files/basic-users.json" | fromJsonArray -}}
{{ range $users -}}
import_user "$realm" "{{ .username }}" '{{ . | toJson }}'
{{ if .clientRoles -}}
assign_user_role "$realm" "{{ .username }}"{{ range $client, $roles := .clientRoles }} "{{ $client }}" "{{ $roles | join " " }}"{{ end }}
{{- end }}

{{ end -}}
{{ end -}}
{{ if .Values.extraUsers -}}
echo "---------- Import Extra Users ---------------"

{{ range .Values.extraUsers -}}
import_user "$realm" "{{ .username }}" '{{ . | toJson }}'
{{ if .clientRoles -}}
assign_user_role "$realm" "{{ .username }}"{{ range $client, $roles := .clientRoles }} "{{ $client }}" "{{ $roles | join " " }}"{{ end }}
{{- end }}

{{ end -}}
{{ end -}}

{{ if .Values.clientsSecrets -}}
echo "---------- Import Clients Secrets ---------------"

{{ range $client, $secret := .Values.clientsSecrets -}}
import_client_secret "$realm" "{{ $client }}" "{{ $secret }}"
{{ end -}}
{{ end -}}

{{ if .Values.clientsRedirectUris -}}
echo "---------- Import Clients Redirect URIs ---------------"

{{ range $client, $redirectUris := .Values.clientsRedirectUris -}}
import_client_redirect_uris "$realm" "{{ $client }}" '{{ $redirectUris | toJson }}'
{{ end -}}
{{ end -}}
echo "---------- Keycloak configuration over  ---------------"
