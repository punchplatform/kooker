# Kooker

**K**ooker with a **K** is derived from the word *Cooker*. Like a cooker is used for 
making delicious recipes, kooker cooks a (hopefully tasty) Punch recipe on top of K3D.

In short: kooker deploys a kubernetes cluster together with punch services such as Minio,
Clickhouse, Elastic, etc .. so that you can start punch applications in minutes.  

## Requirements

- Docker engine installed
- curl 
- realpath 
- unzip
- bash

## Quick start

> :warning: you may need to do a: `docker system prune && systemctl restart docker.service` before playing this guide

!!! warn

    Sometimes, you may need to do a: `docker system prune && systemctl restart docker.service` before playing this guide.

To deploy a local Kubernetes cluster with basic COTS and Punch components simply run : 

```sh
make start
```

!!! info 

    You need to have internet access

This command will : 

- Create a k3d cluster named 'kooker'
- Deploy basic COTS : Elasticsearch, Kibana, Kafka, Minio, Prometheus, Grafana, Kubernetes Dashboard and Clickhouse
- Deploy Punch components : Artifacts Server & Punch Operator
- Load Elasticsearch templates 
- configure your /etc/hosts to allow direct access to the deployed services (this step will ask you your sudoer password)

After a successful installation, you will be able to launch your first punchline, which generates arbitrary data on stdout:  

```sh
kubectl apply -f examples/punchline_java_example.yaml -n kast
```

To run the same manifest with external resources dependencies, run: 

```sh
# at least (once - requires sudo)
make network
# or 
make credentials
```

Then, open your navigator and browse to the `ARTIFACTS SERVER` url and import the provided example artifacts `examples/test-parsers-1.0.0-artifact.zip` by clicking on the `Upload artifacts` button

Finally, execute your punchline using the command below: 

```sh
kubectl apply -f examples/punchline_java_resource_example.yaml -n kast
```

## Tooltips

The PConsole provides a set of commands to interact with your deployed kubernetes cluster. The `start` command is a wrapper of some of them, but you can use them independently if necessary. 

```sh
### prints helper 
make help

### create a kubernetes context for your cluster and switch default context to the newly created one
make cluster 

### configure local /etc/hosts to have access to your components locally (requires sudo)
make network 

### prints all deployed endpoints and associated credentials
make credentials

### delete k3d cluster
make stop
```

## Going further

### Offline mode

Kooker can be also be used without internet access. 

On a machine with internet access, run : 

```sh
make download 
```

It will download all online resources locally in `download` directory

Then, copy the `download` directory to your offline platform at the root directory of your Kooker installation directory and run : 

```sh
make OFFLINE=true start
```

### Deploy only components

If your `KUBECONFIG` is already configured to access a kubernetes cluster with proper **RBAC**, you can deploy our prerequisites by using the command:

```sh
make CLUSTER_NAME=mycluster start
```

### Update default configuration

Kooker comes with a default configuration.
To override any of them, update the file `bin/profiles/profile-defaults.sh`, by setting your desired value or extends this profile and specify it like this when running make: 

```sh
make PROFILE=bin/profiles/profile-8.0-DEV.sh start
```
