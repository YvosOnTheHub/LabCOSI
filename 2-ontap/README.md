cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ontap-s3-credentials
  namespace: trident
type: Opaque
stringData:
  username: vsadmin
  password: Netapp1!
---
apiVersion: trident.netapp.io/v1
kind: TridentObjectStore
metadata:
  name: cosi-ontap-s3                   # must match storeName (DNS-safe form)
  namespace: trident
spec:
  objectStoreDriver: ontap-s3
  objectStoreName: ontap-s3
  managementEndpoint: 192.168.0.230
  svmName: ontapcosi
  #storagePrefix: example             # optional; prepended to names Trident creates (default: trident)
  credentials:
    secretName: ontap-s3-credentials
EOF



cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ontap-s3-credentials
  namespace: trident
type: Opaque
stringData:
  username: vsadmin
  password: Netapp1!
---
apiVersion: trident.netapp.io/v1
kind: TridentObjectStore
metadata:
  name: cosi-ontap-s3                   # must match storeName (DNS-safe form)
  namespace: trident
spec:
  objectStoreDriver: ontap-s3
  objectStoreName: ontap-s3
  managementEndpoint: 192.168.0.156
  svmName: svm3
  #storagePrefix: example             # optional; prepended to names Trident creates (default: trident)
  credentials:
    secretName: ontap-s3-credentials
EOF

kdel -n trident tos cosi-ontap-s3
kdel -n trident secret ontap-s3-credentials



cat << EOF | kubectl apply -f -
apiVersion: objectstorage.k8s.io/v1alpha2
kind: BucketClaim
metadata:
  name: ontap-bucket-claim
spec:
  bucketClassName: ontap-bucket-class
  protocols: ["S3"]
---
apiVersion: objectstorage.k8s.io/v1alpha2
kind: BucketAccess
metadata:
  name: ontap-bucket-access
spec:
  bucketAccessClassName: trident-s3-key
  protocol: S3
  bucketClaims:
    - bucketClaimName: ontap-bucket-claim
      accessMode: ReadWrite
      accessSecretName: ontap-bucket-creds
EOF

kdel bucketclaim ontap-bucket-claim
kdel bucketaccess ontap-bucket-access