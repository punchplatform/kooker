# Kooker

Kooker with a K is derived from the word Cooker. Like a cooker is used for making delicious recipes, kooker will try to cook a Punch recipe on K3D. 

kooker is container, a swiss knife army, built with tools required for an autonomous deployment. Delivering as a container makes it platform agnostic.

The tool was built to showcase the concept on how to facilitate local development with Punch services dependencies and how it can be seamlessly included in CI pipelines


# High-level Deployment Schema 

```plantuml
top to bottom direction

!theme spacelab
node "Kubernetes" as  n1
note bottom of n1
  AKS
  K3S
  K3D
  ..
end note


node "COTS" as n2
note bottom of n2
  Elasticsearch
  Kafka
  Monitoring
  S3
  Clickhouse
  ..
end note

node "Punch Services\nPunchline1\nPunchline2..." as n3

n1 -> n2
n2 -> n3
```
