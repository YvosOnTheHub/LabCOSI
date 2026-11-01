## Object storage with COSI

### What is COSI?

The Container Object Storage Interface (COSI) is a Kubernetes standard for provisioning and consuming object storage. It does for buckets what CSI does for volumes. A workload requests a bucket through Kubernetes resources, and a storage driver creates it on the backend. Applications don't need to know which object store sits behind it.

COSI defines these resources:

| Resource | Purpose |
|---|---|
| `BucketClass` | Defines how buckets are provisioned, including the deletion policy |
| `BucketClaim` | Requests a bucket |
| `BucketAccessClass` | Defines how access to buckets is provisioned |
| `BucketAccess` | Requests credentials for one or more buckets |

Trident adds one resource of its own, `TridentObjectStore`. It connects Trident to an object store and its credentials.

### A short history of COSI

- **November 2019:** The COSI proposal (KEP-1979, "Object Storage Support") is created in Kubernetes SIG Storage.
- **Kubernetes v1.25:** The `v1alpha1` API is approved.
- **Kubernetes v1.36 (targeted):** Approval of the `v1alpha2` API.

`v1alpha2` brings breaking changes. Among them:

- A `BucketAccess` can reference several buckets.
- Access can be set per bucket as read or write.
- Access credentials are stored as individual Secret fields instead of a JSON blob.
- `deletionPolicy` is now required.

`v1alpha1` and `v1alpha2` components are not compatible with each other, and there is no automated migration. COSI is still an alpha API, so it can change.

### COSI support in Trident 26.10

Trident 26.10 provisions S3 buckets for Kubernetes workloads through COSI. The integration is built on the **`objectstorage.k8s.io/v1alpha2`** API.

| Object store | Status in Trident 26.10 |
|---|---|
| StorageGRID | Generally available |
| ONTAP S3 | Technical preview, not for production use |

Things to know before you enable it:

- COSI is **off by default**. Set both `enableCOSI: true` and `enableConcurrency: true` in the `TridentOrchestrator` custom resource.
- Only the S3 protocol is supported, and only with path-style addressing.
- A StorageGRID `TridentObjectStore` connects to one tenant with long-lived tenant root credentials. Keep them in a Kubernetes Secret in the Trident namespace and protect them accordingly.
- A StorageGRID `BucketAccess` supports up to eight buckets.

### Controller and CRDs deployed by the Trident installer

The Trident installer deploys **its own forked version of the COSI Controller and the COSI CRDs**. You don't need to install them separately.

> **Do not run Trident COSI alongside the community COSI controller.** The two would conflict.

### Quick start

```yaml
apiVersion: trident.netapp.io/v1
kind: TridentOrchestrator
metadata:
  name: trident
spec:
  namespace: trident
  enableConcurrency: true
  enableCOSI: true
```

After you create a `TridentObjectStore`, request a bucket with a `BucketClass` and a `BucketClaim`. Then request credentials with a `BucketAccessClass` and a `BucketAccess`. Trident writes the S3 connection details (endpoint, region, bucket ID, access keys) to a Kubernetes Secret that your workload can consume. Treat that Secret as sensitive.

For the full procedure, see [Provision object storage with COSI](https://docs.netapp.com/us-en/trident/trident-use/cosi.html).

### Quick comparison of the CSI & COSI constructs

If you are familiar with CSI, you can conceptually compare some constructs with COSI, while others are peculiar to COSI:  
| CSI | COSI | Description |
|---|---|---|
| Trident Backend Config | Trident Object Store | Trident configuration of the underlying storage environment |
| Storage Class | Bucket Class | Kubernetes construct against which you request storage |
| - | Bucket Access Class | Contains information, such as keys, to connect to the bucket |
| Persistent Volume Claim | Bucket Claim | A namespace request for storage |
| Persistent Volume | Bucket | A cluster scope resource referencing the storage |

Note that there is a strict one-to-one relationship between a `bucket` and `bucketClaim`, as there is between a `PVC` and its corresponding `PV`.  

## Lab Guide

The NetApp LabOnDemand platform provides an environment with both StorageGRID and ONTAP: [Cloud Tiering with FabricPool for Cost-Efficient Storage v3.0](https://labondemand.netapp.com/node/1610).  
Once logged in, please use Putty to connect to the host *ubuntu*.  
Let's use it to configure and test COSI:  
- [0 - Setup](./0-setup/)
- [1 - StorageGRID](./1-storagegrid/)
- [2 - ONTAP](./2-ontap/) _WORK IN PROGRESS_
