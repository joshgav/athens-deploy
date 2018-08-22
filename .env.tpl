AZURE_BASE_NAME=go-proxy
AZURE_DEFAULT_LOCATION=westus2

# for worker queue
ATHENS_REDIS_QUEUE_PORT=

# for: memory, disk, mongo, minio, gcp
ATHENS_STORAGE_TYPE=mongo
ATHENS_MONGO_CONNECTION_STRING=

# for: postgres, sqlite, cockroach, mysql
# ATHENS_STORAGE_TYPE=postgres
# ATHENS_RDBMS_STORAGE_NAME=${ATHENS_STORAGE_TYPE}

# this defaults to http://localhost:3001
# OLYMPUS_GLOBAL_ENDPOINT=

# logging
BUFFALO_LOG_LEVEL=debug
ATHENS_LOG_LEVEL=debug

