# 09 - Monitoring & Logging

Comprehensive monitoring and logging are essential for maintaining healthy Kubernetes applications.

## 📊 Monitoring Stack

### Prometheus & Grafana
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alert routing and management
- **Node Exporter**: System metrics collection

### Google Cloud Operations Suite (formerly Stackdriver)
- **Cloud Monitoring**: GKE-integrated monitoring
- **Cloud Logging**: Centralized log management
- **Cloud Trace**: Distributed tracing
- **Cloud Profiler**: Performance profiling

## 📋 Logging Stack

### EFK/ELK Stack
- **Elasticsearch**: Log storage and search
- **Fluentd/Fluent Bit**: Log forwarding
- **Kibana**: Log visualization and analysis

### Cloud-Native Options
- **Loki**: Lightweight log aggregation
- **Jaeger**: Distributed tracing
- **OpenTelemetry**: Observability framework

## 🎯 Metrics Types

### System Metrics
- **CPU, Memory, Disk, Network usage**
- **Node resource utilization**
- **Container resource consumption**

### Application Metrics
- **Request rate, latency, error rate (RED)**
- **Utilization, saturation, errors (USE)**
- **Business metrics (custom)**

### Kubernetes Metrics
- **Pod status and restarts**
- **Service availability**
- **Resource quotas and limits**

## 🔔 Alerting

### Alert Types
- **Infrastructure alerts**: Node down, high CPU
- **Application alerts**: High error rate, slow response
- **Business alerts**: Transaction failures, SLA breaches

### Alert Channels
- **Email, Slack, PagerDuty**
- **Webhooks for custom integrations**
- **Mobile notifications**

## 📈 Dashboards

### Key Dashboards
- **Cluster overview**: Node status, resource usage
- **Application health**: Service status, performance
- **Resource utilization**: CPU, memory, storage
- **Network traffic**: Ingress/egress, service mesh

## 🔍 Log Management

### Log Levels
- **ERROR**: Application errors
- **WARN**: Warning conditions
- **INFO**: General information
- **DEBUG**: Detailed diagnostic info

### Log Formats
- **Structured logging**: JSON format
- **Contextual logging**: Request IDs, user context
- **Centralized logging**: Aggregated across services

## 🛡️ Security Monitoring

### Security Metrics
- **Failed authentication attempts**
- **Privilege escalations**
- **Network policy violations**
- **Resource access patterns**

## 📊 Performance Monitoring

### Application Performance Monitoring (APM)
- **Request tracing**
- **Database query performance**
- **External API latency**
- **Error tracking and analysis**

## 🎛️ Configuration

### Monitoring Configuration
```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: app-monitor
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
```

### Logging Configuration
```yaml
# FluentBit DaemonSet configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
data:
  fluent-bit.conf: |
    [INPUT]
        Name tail
        Path /var/log/containers/*.log
        Parser docker
        Tag kube.*
```

## 🔧 Best Practices

1. **Implement the 4 Golden Signals**: Latency, Traffic, Errors, Saturation
2. **Use structured logging** for better parsing
3. **Set up proper alerting** to avoid alert fatigue
4. **Monitor business metrics** alongside technical metrics
5. **Implement distributed tracing** for microservices
6. **Use resource requests and limits** for better monitoring
7. **Regular review and tuning** of alerts and dashboards
8. **Implement log retention policies**

## 🛠️ Tools and Commands

```bash
# View pod logs
kubectl logs <pod-name> -f
kubectl logs <pod-name> -c <container-name>

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Resource usage
kubectl top nodes
kubectl top pods

# Port forward to access monitoring UIs
kubectl port-forward svc/prometheus-server 9090:80
kubectl port-forward svc/grafana 3000:80
```
