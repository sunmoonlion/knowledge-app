apiVersion: apps/v1
kind: Deployment
metadata:
  name: __APP_NAME__
  namespace: ${NAMESPACE:-__NAMESPACE__}
  labels:
    app: __APP_NAME__
spec:
  replicas: 1
  selector:
    matchLabels:
      app: __APP_NAME__
  template:
    metadata:
      labels:
        app: __APP_NAME__
    spec:
      imagePullSecrets:
      - name: ${__APP_NAME_UPPER___IMAGE_PULL_SECRET_NAME:-harbor-registry-secret}
      containers:
      - name: __APP_NAME__
        image: ${__APP_NAME_UPPER___FULL_IMAGE_NAME}
        imagePullPolicy: ${IMAGE_PULL_POLICY:-Always}
        ports:
        - containerPort: __PORT__
        envFrom:
        - configMapRef:
            name: ${__APP_NAME_UPPER___CONFIGMAP_NAME:-__APP_NAME__-config}
        - secretRef:
            name: ${__APP_NAME_UPPER___SECRET_NAME:-__APP_NAME__-secret}
${__APP_NAME_UPPER___DATABASE_ENV_FROM}
${__APP_NAME_UPPER___OBJECT_STORAGE_ENV_FROM}
${__APP_NAME_UPPER___ELASTICSEARCH_ENV_FROM}
        resources:
          requests:
            memory: "__MEMORY_REQUEST__"
            cpu: "__CPU_REQUEST__"
          limits:
            memory: "__MEMORY_LIMIT__"
            cpu: "__CPU_LIMIT__"
        livenessProbe:
          tcpSocket:
            port: __PORT__
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          tcpSocket:
            port: __PORT__
          initialDelaySeconds: 15
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: data
          mountPath: ${PVC_MOUNT_PATH:-/app/data}
${__APP_NAME_UPPER___ELASTICSEARCH_VOLUME_MOUNT}
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: ${PVC_NAME:-__APP_NAME__-pvc}
${__APP_NAME_UPPER___ELASTICSEARCH_VOLUME}
---
apiVersion: v1
kind: Service
metadata:
  name: __APP_NAME__
  namespace: ${NAMESPACE:-__NAMESPACE__}
  labels:
    app: __APP_NAME__
spec:
  selector:
    app: __APP_NAME__
  ports:
  - port: __PORT__
    targetPort: __PORT__
    protocol: TCP
  type: ClusterIP
