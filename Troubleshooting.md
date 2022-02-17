# First-level Troubleshooting



In case something does not work after full deployment (see README.md `make start`)

## Prerequisites

* Ensure your kubectl configuration is available

		make start
		. activate.sh

* Have a grafana set up to watch for cluster metrics

	- connect to grafana	at `http://grafana.kooker:3000/` with your web browser (firefox advised)
	
	- Create  Prometheus datasource, providing url `http://prometheus.monitoring:9090`
	

## Top-down troubleshooting track



### Check your kube resources status

* List pods that are not starting or have failed :

	kubectl get pods -A -l '!job-name' | grep -v Running


### Check your artifacts service status
	
	kubectl get pod -A -l app=artifacts      # Should be running
	


## Useful debug commands


## 


### Viewing logs from punch operator service

	kubectl logs -f --tail=-1 -n punchoperator-system -l control-plane=controller-manager


### Viewing logs from artifacts service

	kubectl logs -f --tail=-1 -n punch-gateway-ns -l app=artifacts

### Reinstall artifact server

	helm uninstall artifacts -n punch-gateway-ns
	make PROFILE=bin/profiles/profile-8.0-DEV.sh deploy-punch

### Reinstall operator server


	helm uninstall -n punchoperator-system operator
	helm uninstall -n punchoperator-system operator-crds
	kubectl get crds -o name | grep -i punch | xargs -n 1 kubectl delete 
	make PROFILE=bin/profiles/profile-8.0-DEV.sh deploy-punch


### Viewing logs from the prometheus service

	kubectl logs -f --tail -1  -n monitoring  -l app=prometheus
	
### Kill/restart the prometheus service pods

	kubectl delete pods -A  -l app=prometheus




### View punchline logs

kubectl logs --tail -1 -f -l punchline-name=ltr-in

### View kafka topics

	. activate.sh
	kkafka ./kafka-topics.sh --list  --bootstrap-server localhost:9092

Get the earliest offset still in a topic
	
	kkafka ./kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic ref-test-01-ltr --time -2

Get the latest offset still in a topic
	
	kkafka ./kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic ref-test-01-ltr --time -1


### View kafka consumer group


	. activate.sh

	kkafka ./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group ltr_out



### Run curl commands from inside the kube (using kibana container)

	kubectl exec -n doc-store $(kubectl get pod -n doc-store -o name -l common.k8s.elastic.co/type=kibana)  -it -- /bin/bash
	curl punchplatform-es-http:9200 -u elastic:elastic



### List images version inside the kooker kube master repository

	docker exec -ti k3d-kooker-server-0 crictl images



### Running a local grafana :

	docker run -d -p 3000:3000 grafana/grafana-oss


### Metrics

app_name ne devrait pas etre positionné automatiquement (trop générique)
'created' acked



## END TO END

	make PROFILE=bin/profiles/profile-8.0-DEV.sh start
	. activate.sh
	kubectl apply -f examples/ltr_lmc
	kkafka ./kafka-topics.sh --list  --bootstrap-server localhost:9092


Needs standalone:

	punchplatform-log-injector.sh -c injector -n 1000000 -t 1000
