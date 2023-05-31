#!/bin/sh
while getopts a:r:v: flag
do
    case "${flag}" in
        a) api_id=${OPTARG};;
        r) resource_id=${OPTARG};;
        v) value=${OPTARG};;
    esac
done

if [ $api_id ]
then
        echo "REST_API_ID: $api_id";
else
        echo "Usage: sh $0 -a rest-api-id -r resource-id -v newvalue"
        exit
fi

if [ $resource_id ]
then
        echo "Resource_id: $resource_id";
else
        echo "Usage: sh $0 -a rest-api-id -r resource-id -v newvalue"
        exit
fi

if [ $value ]
then
        echo "Resource change to: $value";
else
        echo "Usage: sh $0 -a rest-api-id -r resource-id -v newvalue"
        exit
fi

echo Updating resource...
aws apigateway update-resource --rest-api-id $api_id --resource-id $resource_id \
        --patch-operations op=replace,path=/pathPart,value=$value --region ap-southeast-2
aws apigateway create-deployment --rest-api-id $api_id --stage-name test --region  ap-southeast-2