# Kooker

Kooker with a K is derived from the word Cooker. Like a cooker is used for making delicious recipes, kooker will try to cook a Punch recipe on K3D. 

kooker is container, a swiss knife army, built with tools required for an autonomous deployment. Delivering as a container makes it platform agnostic.

The tool was built to showcase the concept on how to facilitate local development with Punch services dependencies and how it can be seamlessly included in CI pipelines

## Requirements

- Docker engine installed
- curl 
- realpath 
- unzip

## Quick start 

!!! warn

    Sometimes, you may need to do a: `docker system prune && systemctl restart docker.service` before playing this guide.

To deploy a local Kubernetes cluster with basic COTS and Punch components simply run : 

```sh
make start
```

!!! info 

    You need to have internet access

This command will : 

- Create a k3d cluster
- Deploy basic COTS : Elasticsearch, Kibana, Kafka, Minio, Prometheus, Grafana, Kubernetes Dashboard and Clickhouse
- Deploy Punch components : Artefact Server & Punch Operator
- Load Elastisearch templates 

After a successful installation, you will be able to launch your first punchline, which generates arbitrary data on stdout:  

```sh
kubectl apply -f examples/stormline_example.yaml -n kast
```

We now want to run a example with an external resource. To achieve this, simply run : 

```sh
make credentials
```

Then, open you browser and go to the `ARTEFACT SERVER` url and import the provided example artifacts `examples/test-parsers-1.0.0-artefact.zip` thanks to the `Upload artifacts` button

Finally, execute your punchline using the command below: 

```sh
kubectl apply -f examples/stormline_with_resource_example.yaml -n kast
```

## Tooltips  

The PConsole provides many commands to interact with your cluster, the start command is a wrapper of some of them but you can use them independently if needed 

```sh
### prints helper 
make help

### switch or create a kubernetes context for your cluster 
make cluster 

### configure local /etc/hosts to have access to your components locally 
make network 

### prints all deployed endpoints and associated credentials
make credentials

### delete k3d cluster
make stop
```

## Going further 

### Offline mode 

Kooker can be also be used in offline mode, this guide will explain how. 

On a laptop with a online access, simply run : 

```sh
make download 
```

It will download all online resources locally in `download` folder 

Then, copy this folder to your offline platform at the root directory of your Kooker and run : 

```sh
make OFFLINE=true start
```

### Deploy only components 

If you already have a reachable Kubernetes cluster you can simply deploy components on top of it : 

```sh
make CLUSTER_NAME=mycluster start
```

### Update default configuration

Kooker provides a default configuration, you can update each values if needed by editing the file `bin/profiles/default_profile.sh`
and then run : 

```sh
make PROFILE=bin/profiles/default_profile.sh start
```

By this way, you can update a component version or a deployment mode 