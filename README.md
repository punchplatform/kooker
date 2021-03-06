# Kooker

**K**ooker with a **K** is derived from the word *Cooker*. Like a cooker is used for making delicious recipes, kooker
cooks a (hopefully tasty) Punch recipe on top of K3D.

In short: kooker deploys a kubernetes cluster together with punch services such as Minio, Clickhouse, Elastic, etc .. so
that you can start punch applications in minutes.

## Requirements

- Docker engine installed
> :information_source: Ubuntu => sudo apt install docker.io

> :information_source: Rocky => sudo yum install epel-release.noarch ; sudo yum update ;  
- curl
- realpath
- unzip
- bash
- jq

## Quick start

> :information_source: This guide assumes you have internet access.

To deploy a local Kubernetes cluster with the several COTS and Punch services up and ready simply execute:

```sh
make start
```

This command will :

- Create a k3d cluster named 'kooker'
- Deploy Elasticsearch, Kibana, Kafka, Minio, Prometheus, Grafana, Kubernetes Dashboard and Clickhouse.
- Deploy the Punch components : the Artifacts Server & Punch Operator
- Load the required Elasticsearch templates
- Optionally configure your /etc/hosts to allow direct access to the deployed services. This step will prompt you to
  provide your sudoer password.

> :warning: In case of docker issue on linux try running: `docker system prune && systemctl restart docker.service`
> then replay the make start command.

If you have issues, refer to the [troubleshooting](TROUBLESHOOTING.md).

## Launch A Punchline

You can now launch a punchline. Try one of the sample ones, that you can find in
the [starters' repository](https://github.com/punchplatform/starters). It that generates arbitrary data on stdout, then
stays idle.

```sh
kubectl apply -f punchlines/java/punchline_java.yaml
```

> :information_source: this command submit a kubernetes Custom Resource Definition file to the punch operator.
> In turn the punch operator starts a pod using a particular strategy. In this simple example, the punchline is
> an ever-running streaming application and the operator will automatically execute it as part of a kubernetes
> deployment. If you try to kill the corresponding pod, it will automatically be restarted by kubernetes.

You can check it is running as follows:
```sh
$ kubectl get pods
NAME                                                     READY   STATUS    RESTARTS   AGE
streampl-java-example-17fa0b3476d7945b-fd5fbdc8d-mhdzp   1/1     Running   0          7s
```

To stop it:
```sh
kubectl delete -f punchlines/java/punchline_java.yaml
```

> :information_source: the default namespace is used to run the example.

## Check the UIs

Kooker comes with various UIs: grafana, Kibana, the kubernetes dashboard, and the punch artifact server. To easily
access them from your local browser; execute:

```sh
make network
```

> :warning: this prompts you to provide you sudoer password. Your /etc/host file will be patched so that the standard
> kubernetes service name are exposed to your local host.

To see the list of the exposed services:
```sh
make credentials
```

## Try the artifact server

The punch artifact server is a high-level service that makes it easy and robust to execute parsers, java or python
functions in the punchline processing functions. In this example we will start the example punchline that loads a parser
and some grok patterns from the artifact server.

First open your navigator and browse to the `ARTIFACTS SERVER` url and import the provided example
artifacts `examples/test-parsers-1.0.0-artifact.zip` by clicking on the `Upload artifacts` button.

You can check it is correctly loaded using the artifact UI.

You can now execute the examples/punchline_java_resource_example.yaml example that requires that artifacts:

```sh
kubectl apply -f examples/punchline_java_resource_example.yaml
```
Check it is running:

```sh
$ kubectl get pods
NAME                                                              READY   STATUS    RESTARTS   AGE
punchline-with-resource-example-17fa0f2c968f88fe-6d5ccd67cb695z   1/1     Running   0          2m37s
```

> :information_source: try without the artifact loaded into the artifact server, you will notice your punchline stays
> in error condition.

## Tooltips

The Makefile provides a set of commands to interact with your deployed kubernetes cluster. The `start` command is a
wrapper of some of them, but you can use them independently if necessary.

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

### Accessing Services

If you do not allow your /etc/host file to be patched; you can access the inner services from your host browser as
follows. First get the list of deployed services:

```sh
kubectl get svc -A
```

Then use port forwarding to expose the service you need.

### Offline mode

Kooker can be also be used without internet access. On a machine with internet access, execute :

```sh
make download 
```

It will download all the online resources locally in the `download` directory. Copy that `download` directory to your
offline platform at the root directory of your Kooker installation directory and run :

```sh
make OFFLINE=true start
```

### Development version

Kooker can be launched with Punch development version, execute :

```sh
make PUNCH_VERSION=8.0-dev start
```

### Deploy only components

If your `KUBECONFIG` is already configured to access a kubernetes cluster with proper *RBAC*, you can deploy only the
punch adds-on by using the command:

```sh
make CLUSTER_NAME=mycluster start
```

### Update default configuration

Kooker comes with a default configuration. To override any of them, update the file `bin/profiles/profile-defaults.sh`,
by setting your desired value or extends this profile and specify it like this when running make:

```sh
make PROFILE=bin/profiles/profile-8.0-DEV.sh start
```

### Offline setup of Docker on Rocky 8.6


#### First on an online machine

  > :information_source: This follows https://www.linuxtechi.com/install-docker-and-docker-compose-rocky-linux/

```sh
  sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
  sudo dnf install docker-ce --allowerasing -y
 ``` 

  > :information_source: https://github.com/taw00/howto/blob/master/howto-setup-a-local-yum-dnf-repository.md


```sh
  sudo dnf install createrepo_c
  cd kooker/offline_kooker
  createrepo_c .
  sudo yum install -y yum-utils
  repotrack docker-ce   # This downloads everything
  repotrack docker-ce-cli 

  cat <<- EOF > ~/kooker/off/local-docker.repo
    [local-docker] 
    name=Local docker
    baseurl=file://~/kooker/off
    enabled=1
    gpgcheck=0
  EOF
```

#### Then on offline machine

```sh
  sudo cp ~/kooker/off/local-docker.repo /etc/yum.repos.d/
  sudo yum install docker-ce --allowerasing --nobest --disablerepo="*" --enablerepo="local-docker"
```