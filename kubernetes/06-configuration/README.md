# 06 - Configuration

Configuration management in Kubernetes allows you to separate configuration data from application code.

## 🗂️ ConfigMaps

ConfigMaps store non-sensitive configuration data in key-value pairs.

### Use Cases:
- **Application configuration files**
- **Environment-specific settings**
- **Command line arguments**
- **Configuration templates**

### Creation Methods:
```bash
# From literals
kubectl create configmap app-config --from-literal=database.host=mysql-service

# From files
kubectl create configmap app-config --from-file=app.properties

# From directories
kubectl create configmap app-config --from-file=config/
```

### Usage Patterns:
- **Environment variables**: Inject as env vars
- **Volume mounts**: Mount as files
- **Command arguments**: Use in container args

## 🔒 Secrets

Secrets store sensitive data like passwords, tokens, and keys.

### Secret Types:
- **Opaque**: Arbitrary user data (default)
- **kubernetes.io/service-account-token**: Service account tokens
- **kubernetes.io/dockercfg**: Docker registry credentials
- **kubernetes.io/tls**: TLS certificates

### Creation Methods:
```bash
# Generic secret from literals
kubectl create secret generic db-secret --from-literal=username=admin

# TLS secret from files
kubectl create secret tls tls-secret --cert=path/to/cert --key=path/to/key

# Docker registry secret
kubectl create secret docker-registry regcred --docker-server=<server> --docker-username=<username>
```

### Best Practices:
- **Enable encryption at rest**
- **Use RBAC** to control access
- **Rotate secrets regularly**
- **Avoid logging secret values**

## 🌍 Environment Variables

### Sources:
- **Direct values**: Hardcoded in pod spec
- **ConfigMaps**: Non-sensitive configuration
- **Secrets**: Sensitive data
- **Field references**: Pod metadata
- **Resource references**: Container resource limits

### Patterns:
```yaml
env:
- name: DATABASE_HOST
  value: "mysql-service"
- name: DATABASE_USER
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: username
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
```

## 🚀 Init Containers

Init containers run before app containers and are useful for:
- **Setup tasks**: Database migrations, file downloads
- **Waiting for dependencies**: Services, databases
- **Configuration preparation**: Template rendering
- **Security setup**: Certificate generation

### Characteristics:
- **Run to completion** before app containers start
- **Run sequentially** if multiple init containers
- **Restart** if they fail (following restart policy)
- **Share volumes** with app containers

## 🔧 Container Lifecycle

### Lifecycle Hooks:
- **PostStart**: Runs immediately after container starts
- **PreStop**: Runs before container terminates

### Handler Types:
- **Exec**: Execute command in container
- **HTTP**: Send HTTP request to container

## 📋 Best Practices

1. **Separate configuration from code**
2. **Use ConfigMaps for non-sensitive data**
3. **Use Secrets for sensitive information**
4. **Implement proper RBAC for secrets**
5. **Use init containers for setup tasks**
6. **Validate configuration before deployment**
7. **Use immutable ConfigMaps/Secrets when possible**
8. **Monitor configuration changes**

## 🛠️ Management Commands

```bash
# ConfigMap operations
kubectl create configmap <name> --from-literal=key=value
kubectl get configmaps
kubectl describe configmap <name>
kubectl edit configmap <name>

# Secret operations
kubectl create secret generic <name> --from-literal=key=value
kubectl get secrets
kubectl describe secret <name>
kubectl get secret <name> -o yaml

# View decoded secret values
kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 -d
```
