# jenkins-k8s

This repository contains a [helm](https://docs.helm.sh) chart to deploy a Jenkins master and autoscaling build agents customized for Skookum.

## Requirements

  1. [Helm client](https://docs.helm.sh/using_helm/#installing-the-helm-client)
  1. Kubernetes cluster with [tiller](https://docs.helm.sh/using_helm/#installing-tiller) installed

## Installation

```bash
helm dependency build skookum-jenkins
helm install skookum-jenkins
```

You may also pass your own yaml file containing overrides of `skookum-jenkins/values.yaml`:

```bash
helm install skookum-jenkins -f overrides-example.yaml
```