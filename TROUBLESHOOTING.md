# Troubleshooting

In case something does not work after a complete deployment (i.e. `make start`) follow the instructions below:

## Prerequisites

* Ensure your kubectl configuration is available

```sh
make start
source ./activate.sh
```

* Have a grafana set up to watch for cluster metrics

- connect to grafana at `http://grafana.kooker:3000/` with your browser (firefox advised)
	
- Create  the Prometheus datasource, providing the url `http://prometheus.monitoring:9090`


## Top-down troubleshooting track


### Check your kube resources status

* List pods that are not starting or have failed :

```sh
kubectl get pods -A -l '!job-name' | grep -v Running
```

### Check your artifacts service status
	
```sh
kubectl get pod -A -l app=artifacts      # Should be running
```	

### Check all pods status

```sh
kubectl get pods -A
```

### Detect all missing images blocking pods

```sh
kubectl get pods -A -o yaml | sed -n 's/.*Back-off pulling image "\(.*\)".*/\1/p'
```


## Useful debug commands


### Viewing logs from punch operator service

```sh
kubectl logs -f --tail=-1 -n punchoperator-system \
    -l control-plane=operator-controller-manager
```

### Viewing logs from artifacts service

```sh
kubectl logs -f --tail=-1 -n punch-artifacts -l app=artifacts
```

### Reinstall artifact server

```sh
helm uninstall artifacts -n punch-artifacts
make PROFILE=bin/profiles/profile-8.0-DEV.sh deploy-punch
```

### Reinstall operator server

```sh
helm uninstall -n punchoperator-system operator
helm uninstall -n punchoperator-system operator-crds
kubectl get crds -o name | grep -i punch | xargs -n 1 kubectl delete
make PROFILE=bin/profiles/profile-8.0-DEV.sh deploy-punch
```

### Viewing logs from the prometheus service

```sh
kubectl logs -f --tail -1  -n monitoring  -l app=prometheus
```

### Kill/restart the prometheus service pods

```sh
kubectl delete pods -A  -l app=prometheus
```


### View punchline logs

```sh
kubectl logs --tail -1 -f -l punchline-name=ltr-in
```

### View kafka topics

```sh
. activate.sh
kkafka ./kafka-topics.sh --list  --bootstrap-server localhost:9092
```

Get the earliest offset still in a topic
	
```sh	
kkafka ./kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic ref-test-01-ltr --time -2
```

Get the latest offset still in a topic

```sh	
kkafka ./kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic ref-test-01-ltr --time -1
```

### View kafka consumer group

```sh
. activate.sh
kkafka ./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group ltr_out
```

### Run curl commands from inside the kube (using kibana container)

```sh
kubectl exec -n doc-store $(kubectl get pod -n doc-store -o name -l common.k8s.elastic.co/type=kibana)  -it -- /bin/bash
curl punchplatform-es-http:9200 -u elastic:elastic
```

### List images version inside the kooker kube master repository

```sh
docker exec -ti k3d-kooker-server-0 crictl images
```

### Running a local grafana :

```sh
docker run -d -p 3000:3000 grafana/grafana-oss
```

### Restricting outbound trafic from k3d

To set a restriction rule:
```sh
# respect the order
sudo iptables -I DOCKER-USER --source 172.0.0.0/8 -m state --state NEW  -j DROP
sudo iptables -I DOCKER-USER --source 172.0.0.0/8 --dest 172.0.0.0/8 -j RETURN
```
To remove it:
```sh
sudo iptables -D DOCKER-USER --source 172.0.0.0/8 -m state --state NEW  -j DROP
sudo iptables -D DOCKER-USER --source 172.0.0.0/8 --dest 172.0.0.0/8 -j RETURN
```
