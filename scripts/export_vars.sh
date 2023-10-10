#!/bin/sh

mongo_credentials=`gcloud secrets versions access latest --secret=newyeti_mongo_credentials`
bq_credentials=`gcloud secrets versions access latest --secret=newyeti_bq_credentials`
infra_credentials=`gcloud secrets versions access latest --secret=upstash_infra_credentials`
rapid_api_keys=`gcloud secrets versions access latest --secret=rapid-api-keys`

get_credentials() {
    type=$1
    json_key=$2

    if [[ ${type} == "mongo" ]]; then
        echo $( jq -r  $json_key <<< "${mongo_credentials}" )
    elif [[ ${type} == "infra" ]]; then
        echo $( jq -r  $json_key <<< "${infra_credentials}" )
    fi
}


environment=$(echo $APP_ENV)

if [[ -z "${environment}" ]]; then
    environment="dev"
fi

echo "Setting '${environment}' envrionment variables"

env_infra="dev"
env_mongo="dev"

if [[ ${environment} == "prod" ]]; then
    env_infra="control_cluster"
    env_mongo="prod"
fi

#Mongo DB
MONGO_HOSTNAME=$(get_credentials "mongo" ".${env_mongo}.hostname")
MONGO_USERNAME=$(get_credentials "mongo" ".${env_mongo}.username")
MONGO_PASSWORD=$(get_credentials "mongo" ".${env_mongo}.password")
MONGO_JSON_FMT='{"HOSTNAME": "%s", "USERNAME": "%s", "PASSWORD": "%s"}'
export MONGO=$(printf "${MONGO_JSON_FMT}" "${MONGO_HOSTNAME}" "${MONGO_USERNAME}" "${MONGO_PASSWORD}")

#BigQuery
BIGQUERY_CREDENTIAL_JSON_FMT='{"CREDENTIAL": "%s"}'
export BIGQUERY=$(printf "${BIGQUERY_CREDENTIAL_JSON_FMT}" "${bq_credentials}" )

#Redis
REDIS_HOSTNAME=$(get_credentials "infra" ".${env_infra}.redis.hostname")
REDIS_PORT=$(get_credentials "infra" ".${env_infra}.redis.port")
REDIS_PASSWORD=$(get_credentials "infra" ".${env_infra}.redis.password")
REDIS_SSL_ENABLED=True
REDIS_JSON_FMT='{"HOSTNAME": "%s", "PORT": "%s", "USERNAME": "%s", "PASSWORD": "%s", "SSL_ENABLED": "%s"}'

export REDIS=$(printf "${REDIS_JSON_FMT}" "${REDIS_HOSTNAME}" "${REDIS_PORT}" "${REDIS_USERNAME}" "${REDIS_PASSWORD}" "${REDIS_SSL_ENABLED}")

#Kafka
KAFKA_BOOTSTRAP_SERVERS=$(get_credentials "infra" ".${env_infra}.kafka.bootstrap_servers")
KAFKA_USERNAME=$(get_credentials "infra" ".${env_infra}.kafka.username")
KAFKA_PASSWORD=$(get_credentials "infra" ".${env_infra}.kafka.password")
KAFKA_JSON_FMT='{"BOOTSTRAP_SERVERS": "%s","USERNAME": "%s", "PASSWORD": "%s"}'
export KAFKA=$(printf "${KAFKA_JSON_FMT}" "${KAFKA_BOOTSTRAP_SERVERS}" "${KAFKA_USERNAME}" "${KAFKA_PASSWORD}")

#Rapid API Keys (comma separated list)
API_KEYS_JSON_FMT='{"API_KEYS": "%s"}'
export RAPID_API=$(printf "${API_KEYS_JSON_FMT}" "${rapid_api_keys}" )

echo "Setting environment variables completed."