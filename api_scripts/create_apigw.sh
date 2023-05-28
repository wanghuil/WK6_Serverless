#!/bin/sh
API_NAME=LambdaSimpleProxy
FUNCTION_NAME=GetStartedLambdaProxyIntegration
AWS_ACCOUNT_ID=026559016816
AWS_REGION=ap-southeast-2
STATEMENT1_ID=hello-apigateway-invoke-permissions
STATEMENT2_ID=lookup-apigateway-invoke-permissions
STATEMENT3_ID=register-apigateway-invoke-permissions
RESOURCE1_PATH=helloworld
RESOURCE2_PATH=lookup
RESOURCE3_PATH=register
echo 1. Creating REST API
aws apigateway create-rest-api --name $API_NAME --endpoint-configuration types=REGIONAL --region $AWS_REGION

echo 2. Creating /helloworld AND /lookup resource
API_ID=$(aws apigateway get-rest-apis --region $AWS_REGION --query 'items[?name==`'"$API_NAME"'`]' | jq --raw-output '.[0] .id')
#echo $API_ID
ROOT_ID=$(aws apigateway get-resources --region $AWS_REGION --rest-api-id $API_ID | jq --raw-output '.items[0] .id')
aws apigateway create-resource --rest-api-id  $API_ID --parent-id $ROOT_ID --path-part $RESOURCE1_PATH --region $AWS_REGION
aws apigateway create-resource --rest-api-id  $API_ID --parent-id $ROOT_ID --path-part $RESOURCE2_PATH --region $AWS_REGION

echo 3. Grant invoke permission to lambda
aws lambda remove-permission --function-name $FUNCTION_NAME --statement-id $STATEMENT1_ID --region $AWS_REGION
aws lambda remove-permission --function-name $FUNCTION_NAME --statement-id $STATEMENT2_ID --region $AWS_REGION
aws lambda remove-permission --function-name $FUNCTION_NAME --statement-id $STATEMENT3_ID --region $AWS_REGION
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id $STATEMENT1_ID \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$AWS_REGION:$AWS_ACCOUNT_ID:$API_ID/*/*/$RESOURCE1_PATH" \
    --region $AWS_REGION
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id $STATEMENT2_ID \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$AWS_REGION:$AWS_ACCOUNT_ID:$API_ID/*/*/$RESOURCE2_PATH" \
    --region $AWS_REGION
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id $STATEMENT3_ID \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$AWS_REGION:$AWS_ACCOUNT_ID:$API_ID/*/*/$RESOURCE3_PATH" \
    --region $AWS_REGION

echo 4. Create ANY method to /helloworld and GET to /lookup
HELLO_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $AWS_REGION --query 'items[?pathPart==`'"$RESOURCE1_PATH"'`]' | jq --raw-output '.[0] .id')
aws apigateway put-method --rest-api-id  $API_ID --resource-id  $HELLO_ID --http-method  ANY --authorization-type "NONE" --region $AWS_REGION
LOOKUP_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $AWS_REGION --query 'items[?pathPart==`'"$RESOURCE2_PATH"'`]' | jq --raw-output '.[0] .id')
aws apigateway put-method --rest-api-id  $API_ID --resource-id  $LOOKUP_ID --http-method  GET --authorization-type "NONE" --region $AWS_REGION


echo 5. Add method response to /helloworld ANY method AND  /lookup GET
aws apigateway put-method-response  --rest-api-id  $API_ID --resource-id  $HELLO_ID --http-method  ANY \
        --response-models application/json=Empty \
        --status-code 200 --region $AWS_REGION
aws apigateway put-method-response  --rest-api-id  $API_ID --resource-id  $LOOKUP_ID --http-method  GET \
        --response-models application/json=Empty \
        --status-code 200 --region $AWS_REGION

echo 6. Put integration for Lambda
aws apigateway put-integration --rest-api-id  $API_ID --resource-id  $HELLO_ID --http-method  ANY \
        --type AWS_PROXY --integration-http-method POST  --region $AWS_REGION \
        --uri "arn:aws:apigateway:$AWS_REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$AWS_REGION:$AWS_ACCOUNT_ID:function:$FUNCTION_NAME/invocations"
aws apigateway put-integration --rest-api-id  $API_ID --resource-id  $LOOKUP_ID --http-method  GET \
        --type AWS_PROXY --integration-http-method POST  --region $AWS_REGION \
        --uri "arn:aws:apigateway:$AWS_REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$AWS_REGION:$AWS_ACCOUNT_ID:function:$FUNCTION_NAME/invocations"

echo 7. Put integration response for /helloworld AND /lookup
aws apigateway put-integration-response --rest-api-id  $API_ID --resource-id  $HELLO_ID --http-method  ANY --status-code 200 --region $AWS_REGION
aws apigateway put-integration-response --rest-api-id  $API_ID --resource-id  $LOOKUP_ID --http-method GET --status-code 200 --region $AWS_REGION

echo 8. Deploy API Gateway
aws apigateway create-deployment --rest-api-id $API_ID --stage-name test --region $AWS_REGION
