# 03 - Workloads

Workloads are objects that set deployment and scaling policies for pods.

## 🔄 ReplicaSets

ReplicaSets ensure that a specified number of pod replicas are running at any time.

### Key Features:
- Maintains desired number of pods
- Replaces failed pods automatically
- Scaling up/down capability
- Usually managed by Deployments

### When to Use:
- Rarely used directly
- Managed by Deployments
- Custom controllers

## 🚀 Deployments

Deployments provide declarative updates for Pods and ReplicaSets.

### Key Features:
- Rolling updates and rollbacks
- Revision history
- Scaling capabilities
- Pause and resume functionality

### Deployment Strategies:
- **Recreate**: Kill all existing pods, then create new ones
- **RollingUpdate**: Gradually replace old pods with new ones

### Update Strategies:
```bash
# Update deployment image
kubectl set image deployment/my-deployment container-name=image:tag

# Rollback to previous version
kubectl rollout undo deployment/my-deployment

# Check rollout status
kubectl rollout status deployment/my-deployment

# View rollout history
kubectl rollout history deployment/my-deployment
```

## 📊 StatefulSets

StatefulSets manage stateful applications that require:
- Stable, unique network identifiers
- Stable, persistent storage
- Ordered, graceful deployment and scaling

### Key Features:
- Ordered deployment (0, 1, 2, ...)
- Stable network identity (pod-0, pod-1, ...)
- Persistent storage per pod
- Ordered termination

### Use Cases:
- Databases (MySQL, PostgreSQL, MongoDB)
- Distributed systems (Kafka, Elasticsearch)
- Applications requiring stable storage

## 🔧 DaemonSets

DaemonSets ensure that a copy of a Pod runs on all (or some) nodes.

### Key Features:
- One pod per node
- Automatically adds pods to new nodes
- Removes pods when nodes are deleted

### Use Cases:
- Log collection (Fluentd, Logstash)
- Node monitoring (Prometheus Node Exporter)
- Storage daemons (Ceph, GlusterFS)
- Network plugins

## ⏰ Jobs

Jobs create one or more pods and ensure they successfully terminate.

### Job Types:
- **Single Job**: Run once and complete
- **Parallel Jobs**: Run multiple pods in parallel
- **Work Queue**: Process items from a queue

### Key Features:
- Retry failed pods
- Parallelism control
- Completion tracking
- Cleanup policies

## 📅 CronJobs

CronJobs create Jobs on a time-based schedule.

### Key Features:
- Cron-style scheduling
- Job template management
- Concurrency policies
- History limits

### Use Cases:
- Backups
- Report generation
- Batch processing
- Maintenance tasks

### Cron Schedule Format:
```
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday)
# │ │ │ │ │
# │ │ │ │ │
# * * * * *
```

Examples:
- `0 2 * * *` - Every day at 2 AM
- `*/15 * * * *` - Every 15 minutes
- `0 0 1 * *` - First day of every month
- `0 9-17 * * 1-5` - Every hour from 9 AM to 5 PM, Monday to Friday
