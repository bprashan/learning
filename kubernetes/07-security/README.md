# 07 - Security

Kubernetes security involves multiple layers: cluster security, workload security, and data protection.

## 🔐 Authentication & Authorization

### Authentication Methods
- **Service Accounts**: For pods and applications
- **User Certificates**: X.509 client certificates
- **Bearer Tokens**: Static tokens or JWT
- **OIDC**: Integration with identity providers

### Authorization Models
- **RBAC**: Role-Based Access Control (recommended)
- **ABAC**: Attribute-Based Access Control
- **Node**: Node-specific authorization
- **Webhook**: External authorization services

## 👥 Role-Based Access Control (RBAC)

### Core Components
- **Role**: Permissions within a namespace
- **ClusterRole**: Cluster-wide permissions
- **RoleBinding**: Binds Role to subjects in namespace
- **ClusterRoleBinding**: Binds ClusterRole to subjects cluster-wide

### Subjects
- **User**: Individual users
- **Group**: User groups
- **ServiceAccount**: Pod service accounts

### Verbs (Actions)
- `get`, `list`, `watch`: Read operations
- `create`, `update`, `patch`: Write operations
- `delete`, `deletecollection`: Delete operations
- `*`: All verbs

## 🏃 Service Accounts

Service Accounts provide identity for pods to interact with the Kubernetes API.

### Default Behavior
- Every namespace has a `default` service account
- Pods automatically mount service account tokens
- Tokens are JWT with limited scope

### Token Management
- **Bound tokens**: Audience and time-bound
- **Legacy tokens**: Permanent (being deprecated)
- **Projected tokens**: More secure, audience-aware

## 🔒 Security Contexts

Security contexts define privilege and access control for pods and containers.

### Pod Security Context
- **runAsUser/runAsGroup**: User/group ID to run containers
- **fsGroup**: Group ID for volume ownership
- **seccompProfile**: Seccomp profile for syscall filtering
- **seLinuxOptions**: SELinux context

### Container Security Context
- **runAsUser**: Override pod's user setting
- **runAsNonRoot**: Ensure container runs as non-root
- **readOnlyRootFilesystem**: Make root filesystem read-only
- **allowPrivilegeEscalation**: Control privilege escalation
- **capabilities**: Add/drop Linux capabilities

## 🛡️ Pod Security Standards

Pod Security Standards define policies for pod security configurations.

### Security Levels
- **Privileged**: Unrestricted policy (no restrictions)
- **Baseline**: Minimally restrictive (common security measures)
- **Restricted**: Heavily restricted (security best practices)

### Enforcement Modes
- **Enforce**: Reject non-conforming pods
- **Audit**: Log violations but allow pods
- **Warn**: Show warnings but allow pods

## 🌐 Network Security

### Network Policies
- **Default deny**: Block all traffic by default
- **Ingress rules**: Control incoming traffic
- **Egress rules**: Control outgoing traffic
- **Namespace isolation**: Isolate workloads by namespace

### Policy Selectors
- **podSelector**: Target pods by labels
- **namespaceSelector**: Allow traffic from specific namespaces
- **ipBlock**: Allow traffic from IP ranges

## 🔑 Secrets Management

### Secret Types
- **Opaque**: Generic secrets (base64 encoded)
- **TLS**: TLS certificates and keys
- **Docker registry**: Container registry credentials
- **Service account token**: Kubernetes API tokens

### Best Practices
- **Encrypt at rest**: Enable etcd encryption
- **Least privilege**: Limit access to secrets
- **Rotation**: Regular secret rotation
- **External management**: Use external secret managers

## 🔍 Security Scanning

### Image Security
- **Vulnerability scanning**: Scan container images
- **Image signing**: Verify image authenticity
- **Admission controllers**: Block vulnerable images
- **Private registries**: Use trusted image sources

### Runtime Security
- **Runtime monitoring**: Detect malicious behavior
- **File integrity monitoring**: Monitor file changes
- **Process monitoring**: Track process execution
- **Network monitoring**: Monitor network connections

## 🚨 Security Monitoring

### Audit Logging
- **API server auditing**: Log all API requests
- **Event filtering**: Focus on security-relevant events
- **Log forwarding**: Send logs to SIEM systems
- **Anomaly detection**: Identify unusual patterns

### Security Metrics
- **Failed authentications**: Monitor auth failures
- **Privilege escalations**: Track privilege changes
- **Policy violations**: Network policy violations
- **Resource access**: Monitor resource access patterns

## 🛠️ Security Tools

### Open Source Tools
- **Falco**: Runtime security monitoring
- **OPA Gatekeeper**: Policy enforcement
- **Trivy**: Vulnerability scanner
- **Kube-bench**: CIS benchmark compliance

### Commercial Tools
- **Aqua Security**: Container security platform
- **Twistlock/Prisma Cloud**: Cloud security
- **StackRox**: Kubernetes security platform
- **Sysdig Secure**: Runtime security and compliance

## 📋 Security Best Practices

1. **Principle of Least Privilege**: Grant minimal necessary permissions
2. **Network Segmentation**: Use network policies for micro-segmentation
3. **Image Security**: Scan and sign container images
4. **Secret Management**: Use external secret management systems
5. **Regular Updates**: Keep Kubernetes and node OS updated
6. **Monitoring**: Implement comprehensive security monitoring
7. **Compliance**: Follow industry security standards
8. **Incident Response**: Have security incident response procedures

## 🔧 Security Commands

```bash
# RBAC operations
kubectl get roles,rolebindings
kubectl get clusterroles,clusterrolebindings
kubectl auth can-i create pods --as=user

# Service account operations
kubectl get serviceaccounts
kubectl describe serviceaccount default

# Security policy checks
kubectl get podsecuritypolicies
kubectl get networkpolicies

# Secret operations (be careful with output)
kubectl get secrets
kubectl describe secret <secret-name>
```
