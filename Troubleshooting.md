# First-level Troubleshooting



In case something does not work after full deployment (see README.md `make start`)

## Prerequisites

* Ensure your kubectl configuration is available

		make network
		. activate.sh

* Have a grafana set up to watch for cluster metrics

	- connect to grafana	at `http://grafana.kooker:3000/` with your web browser (firefox advised)
	
	- Create  Prometheus datasource, providing url `http://prometheus.monitoring:9090`
	

## Top-down troubleshooting track



### Check your kube resources status

* List pods that are not starting or have failed :

	kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded




## Useful debug commands

### Viewing logs from punch operator service

	kubectl logs -f --tail=-1 -n punchoperator-system -l control-plane=controller-manager


### Viewing logs from artifacts service

	kubectl logs -f --tail=-1 -n punch-gateway-ns -l app=artifacts

### Reinstall artifact server

	helm uninstall artifacts -n punch-gateway-ns
	make PROFILE=bin/profiles/profile-8.0-DEV.sh deploy-punch
