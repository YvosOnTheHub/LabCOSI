#########################################################################################
# COSI and StorageGRID
#########################################################################################

You will learn here how to configure Trident and Kubernetes to interact with StorageGRID.

This chapter is split into two sub-scenarios:

| Sub-scenario | What you configure |
|---|---|
| [1. Keys without certificates](./1-keys/) | TridentObjectStore with `insecureSkipVerify: true`, S3 access keys, aws-cli and a Kubernetes pod |
| [2. Certificates](./2-certificates/) | Custom TLS certificate on StorageGRID, TridentObjectStore with `trustedCACertificate`, verified TLS from aws-cli and from a pod, plus a Kyverno policy that requires that certificate |

Start with **keys without certificates**, then optionally continue with **certificates**.
