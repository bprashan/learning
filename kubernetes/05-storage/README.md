# 05 - Storage

Kubernetes provides several storage options for applications that need to persist data.

## 📦 Volume Types

### Ephemeral Volumes
- **emptyDir**: Temporary storage, deleted with pod
- **hostPath**: Mount host filesystem (use with caution)
- **configMap**: Configuration data as files
- **secret**: Sensitive data as files

### Persistent Volumes
- **Persistent Volume (PV)**: Cluster-wide storage resource
- **Persistent Volume Claim (PVC)**: Request for storage by pod
- **Storage Class**: Dynamic provisioning of storage

## 🔄 Storage Lifecycle

1. **Provisioning**: Storage is created (static or dynamic)
2. **Binding**: PVC binds to available PV
3. **Using**: Pod mounts the volume
4. **Reclaiming**: Storage is reclaimed when PVC is deleted

## 📊 Access Modes

- **ReadWriteOnce (RWO)**: Single node read-write
- **ReadOnlyMany (ROX)**: Multiple nodes read-only  
- **ReadWriteMany (RWX)**: Multiple nodes read-write
- **ReadWriteOncePod (RWOP)**: Single pod read-write

## 🏷️ Reclaim Policies

- **Retain**: Manual reclamation, data preserved
- **Delete**: Automatic deletion of storage and data
- **Recycle**: Deprecated, data scrubbed and PV reused

## ⚡ Storage Classes

Storage Classes enable dynamic provisioning of storage.

### GKE Storage Classes:
- **standard**: Standard persistent disk (HDD)
- **standard-rwo**: Balanced persistent disk (SSD)
- **premium-rwo**: SSD persistent disk (high IOPS)

### Parameters:
- **type**: Disk type (pd-standard, pd-ssd, pd-balanced)
- **replication-type**: Regional or zonal
- **zones**: Specific zones for disk creation

## 💾 StatefulSet Storage

StatefulSets provide:
- **Stable storage**: Each pod gets dedicated PVC
- **Ordered provisioning**: Storage created in sequence
- **Persistent identity**: Storage follows pod identity

## 🔍 Volume Snapshots

Volume Snapshots allow:
- **Point-in-time copies** of volumes
- **Backup and restore** operations
- **Clone volumes** from snapshots

## 📈 Best Practices

1. **Use appropriate storage class** for performance needs
2. **Set resource limits** on storage requests
3. **Implement backup strategies**
4. **Monitor storage usage**
5. **Use volume snapshots** for backups
6. **Consider regional storage** for HA
7. **Clean up unused PVCs**

## 🛠️ Troubleshooting

### Common Issues:
- **Pending PVC**: No suitable PV or storage class
- **Mount failures**: Permissions or node issues
- **Performance problems**: Wrong storage class or limits

### Debugging Commands:
```bash
# Check PV and PVC status
kubectl get pv,pvc

# Describe storage resources
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>

# Check storage classes
kubectl get storageclass

# View volume usage
kubectl exec -it <pod> -- df -h

# Check node storage
kubectl describe node <node-name>
```
