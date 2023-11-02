# Kooker Keycloak

This chart configure a Keycloak server with clients and users.

## Values

### Global

| Key                   | Type   | Default                                      | Description                                                      |
|-----------------------|--------|----------------------------------------------|------------------------------------------------------------------|
| keycloak.version      | string | `"20.0.3"`                                   | version of the keycloak image. Must be a valid docker image tag. |
| keycloak.server       | string | `"http://keycloakx-http.authentication:80/"` | server to use. Must be a valid URL.                              |
| keycloak.realm        | string | `"master"`                                   | realm to use                                                     |
| keycloak.user         | string | `"admin"`                                    | username to use                                                  |
| keycloak.password     | string | `"admin"`                                    | password to use                                                  |
| punchBoardClient      | bool   | `true`                                       | whether to create the punch-board client                         |
| artifactsServerClient | bool   | `true`                                       | whether to create the artifacts-server client                    |
| basicUsers            | bool   | `true`                                       | whether to create the basic users                                |
| extraUsers            | list   | `[]`                                         | extra users to create. See [below](#Users)                       |

### Clients

Currently, the only supported clients are `punch-board` and `artifacts-server`.

Clients configuration files are already in the helm chart, all you have to do is activate or deactivate them.

### Users

Users can be created according to the
UserRepresentation [(see keycloak documentation)](https://www.keycloak.org/docs-api/22.0.1/rest-api/index.html#UserRepresentation)

If the user exists, an update will be performed. If the user does not exist, it will be created.

Here is an example to create a punch admin user:

```yaml
users:
  - username: admin
    enabled: true
    credentials:
      - type: password
        value: admin
    clientRoles:
      - client: punch-board
        roles:
          - admin
      - client: artifacts-server
        roles:
          - admin
```

Basic users can be created by setting the `basicUsers` value to `true`. They are basically a user for each role, which
are "admin", "editor" and "viewer". Username and Password are the same as the role.

## Development

You can easily check template rendering by running:

```shell
./downloads/helm template charts/kooker-keycloak
```

And easily run and check the chart by running:

```shell
kooker start kooker-keycloak
```

You can check the logs by running:

```shell
# follow logs of pod with label job-name: keycloak-configuration-job
pod=$(./downloads/kubectl get pods -n authentication -l job-name=keycloak-configuration-job -o jsonpath='{.items[0].metadata.name}')
./downloads/kubectl logs -f $pod -n authentication
```