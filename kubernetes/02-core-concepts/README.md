# 02 - Core Concepts

## 🎯 Pods

Pods are the smallest deployable units in Kubernetes. They represent a single instance of a running process.

### Key Pod Characteristics:
- Contains one or more containers
- Containers share network (IP address and port space)
- Containers share storage volumes
- Ephemeral by nature

### Pod Lifecycle:
- **Pending**: Pod accepted but containers not yet created
- **Running**: Pod bound to node and containers created
- **Succeeded**: All containers terminated successfully
- **Failed**: At least one container failed
- **Unknown**: Pod state cannot be determined

## 🏷️ Namespaces

Namespaces provide a way to organize and isolate resources within a cluster.

### Default Namespaces:
- **default**: Default namespace for objects with no other namespace
- **kube-system**: For objects created by Kubernetes system
- **kube-public**: Readable by all users
- **kube-node-lease**: For node heartbeat data

### Benefits:
- Resource isolation
- Access control
- Resource quotas
- Naming scope

## 🏷️ Labels and Selectors

Labels are key-value pairs attached to objects for identification and organization.

### Label Guidelines:
- Use meaningful names
- Follow consistent naming conventions
- Include environment, version, component info

### Selector Types:
- **Equality-based**: `=`, `==`, `!=`
- **Set-based**: `in`, `notin`, `exists`

## 📝 Annotations

Annotations are key-value pairs used to attach arbitrary metadata to objects.

### Differences from Labels:
- Not used for selection
- Can contain larger values
- Used for tools and libraries
- Build info, contact details, etc.

## 🔍 Resource Management

### Resource Requests and Limits:
- **Requests**: Minimum resources guaranteed
- **Limits**: Maximum resources allowed

### Quality of Service (QoS):
- **Guaranteed**: Requests = Limits
- **Burstable**: Requests < Limits
- **BestEffort**: No requests or limits

## 📊 Monitoring and Health Checks

### Probes:
- **Liveness**: Is container running?
- **Readiness**: Is container ready to serve traffic?
- **Startup**: Has container started?

### Probe Types:
- HTTP GET requests
- TCP Socket checks
- Command execution
