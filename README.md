# Dynatrace Live Debugger OpenTelemetry + OpenPipeline Demo

The Demo environment will showcase the following:

- Setup of the **Dynatrace OneAgent** within a local Kuberentes cluster
- Deployment of the OpenTelemetry Demo App with the High CPU Feature Flag Bug enabled
- OpenPipeline to create problems based on incoming logs identifying high CPU
- Collecting debug data from the application with the **Dynatrace Live Debugger**
- Using distributed traces to discovery more information about the issue using the TraceID collected from the Live Debugger

## Architecture

The OpenTelemetry Demo app and source code can be found here: https://github.com/open-telemetry/opentelemetry-demo. The source code will be needed for Live Debugger excercises.

## Quickstart

1. Start a codespaces workspace by going to Codespaces and then selecting 'New with options' or by [clicking here](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=865083078&skip_quickstart=true). You will need the following:

    a) Dynatrace tenant endpoint which should look something like 'https://abcd1234.live.dynatrace.com' 
    b) Dynatrace Operator Token
    c) Dynatrace Ingest Access Token with the following permissions:
        - metrics.ingest
        - logs.ingest
        - openTelemetryTrace.ingest

2. The codespace will automatically create a [Kind](https://kind.sigs.k8s.io/) Kubernetes cluster and deploy the OpenTelemetry application. Once the codespaces is started the following services should be running in the Kind cluster:

   ```sh
   kubectl get pods
   ```

   After a few minutes, you should see the Pods in a `Running` state: