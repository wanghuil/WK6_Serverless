pipeline {
    agent any

    environment {
        lambdaRole      = "GetStartedLambdaBasicExecutionRole"
        lambdaName      = "GetStartedLambdaProxyIntegration"
        lambdaFileName  = "*.js"
        lambdaRuntime   = "nodejs18.x"
        accountID       = "402117963536"
        dynamoTable     = "HelloWorldTable"
        AWS_Creds       = "aws_jr9"
    }

    parameters {
         booleanParam defaultValue:false,name:'blCreateIAMRole'
         booleanParam defaultValue:false,name:'blCreateLambda'
         booleanParam defaultValue:false,name:'blCreateDynamo'
         booleanParam defaultValue:false,name:'blUpdateLambdaCode'
         booleanParam defaultValue:false,name:'blUpdateLambdaConf'
         booleanParam defaultValue:false,name:'blTestLambda'
         booleanParam defaultValue:false,name:'blDeleteLambda'
         string defaultValue: 'index.handler', name: 'lambdaHandler', trim: true
    }

    stages {
        stage('Create Role') {
            when { expression{ return params.blCreateIAMRole } }
            steps {
                withAWS(credentials: 'AWS_Creds', region: 'ap-southeast-2') {
                    // Create Lambda role
                    sh '''
                        aws iam create-role \
                        --role-name $lambdaRole \
                        --assume-role-policy-document file://trust-policy.json
                    '''
                    //  Attach AWSLambdaBasicExecutionRole policy to role
                    sh """
                        aws iam attach-role-policy \
                        --role-name ${lambdaRole} \
                        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
                    """
                    //  Attach AmazonDynamoDBFullAccess policy to role
                    sh """
                        aws iam attach-role-policy \
                        --role-name ${lambdaRole} \
                        --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
                    """
                    sleep 15
                }
            }
        }
/*        stage('Wait Role Creation') {
            steps{
                echo "Waiting for ${lambdaRole} Creation"
                //The input can also be replaced by sleep
                script {
                    timeout(time: 20, unit: 'SECONDS') {
                            input "Should we continue to create lambda?"
                    }
                }
            }
        }
*/
        stage('Create Lambda') {
            when { expression{ return params.blCreateLambda } }
            steps{
                echo 'Create a deployment package && Create a Lambda function' 
                withAWS(credentials: 'AWS_Creds', region: 'ap-southeast-2') {
                    sh """
                       zip function.zip $lambdaFileName
                       
                       aws lambda create-function --function-name $lambdaName \
                        --zip-file fileb://function.zip --handler ${params.lambdaHandler} --runtime $lambdaRuntime \
                        --role arn:aws:iam::$accountID:role/$lambdaRole
                    """
                }
            }
        }
        stage('Update Lambda Code') {
            when { expression{ return params.blUpdateLambdaCode } }
            steps{
                echo 'Create a deployment package && Update the Lambda function'
                withAWS(credentials: 'AWS_Creds', region: 'ap-southeast-2') {
                    sh '''
                       zip function.zip $lambdaFileName
                       
                       aws lambda update-function-code --function-name $lambdaName \
                        --zip-file fileb://function.zip 
                    '''
                }
            }
        }

        stage('Update Lambda Configuration') {
            when { expression{ return params.blUpdateLambdaConf } }
            steps{
                echo 'Create a deployment package && Update the Lambda function'
                withAWS(credentials: 'AWS_Creds', region: 'ap-southeast-2') {
                    sh """
                       aws lambda update-function-configuration --function-name $lambdaName \
                        --handler ${params.lambdaHandler} 
                    """
                }
            }
        }
        stage('Test Lambda') {
            when { expression{ return params.blTestLambda } }
            steps{
                withAWS(credentials: 'AWS_Creds', region: 'ap-southeast-2') {
                    echo 'List lambda functions'
                    sh 'aws lambda list-functions --max-items 10'
                    sh 'aws lambda get-function --function-name $lambdaName'

                    echo 'Invoke test'
                    sh 'aws lambda invoke --function-name $lambdaName out --log-type Tail'
                    sh '''
                        aws lambda invoke --function-name $lambdaName out --log-type Tail \
                        --query 'LogResult' \
                        --payload '{ "queryStringParameters": {"name": "Will", "city": "Gold Coast", "time": "sunday"}}' \
                        --output text |  base64 -d
                    '''
                } 
            }
        }

        stage('Create DynamoDB') {
            when { expression{ return params.blCreateDynamo } }
            steps{
                echo 'Create a DynamoDB'
                withAWS(credentials: 'AWS_Creds', region: 'ap-southeast-2') {
                    sh '''
                       aws dynamodb create-table --table-name $dynamoTable \
                        --attribute-definitions AttributeName=id,AttributeType=N AttributeName=name,AttributeType=S \
                        --key-schema AttributeName=id,KeyType=HASH AttributeName=name,KeyType=RANGE \
                        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
                        --local-secondary-indexes \
                            "[
                                {                                                                                                
                                    \\"IndexName\\": \\"HelloIndex\\",                              
                                    \\"KeySchema\\": [                                                          
                                        {\\"AttributeName\\": \\"id\\",\\"KeyType\\":\\"HASH\\"},
                                        {\\"AttributeName\\": \\"name\\",\\"KeyType\\":\\"RANGE\\"}
                                    ],                                                                                      
                                    \\"Projection\\": {                                                        
                                        \\"ProjectionType\\": \\"ALL\\"                            
                                    }                                                                                        
                                }                                                                                                
                            ]"
                    '''
                }
            }
        }

        stage('Delete Resources'){
            when { expression{ return params.blDeleteLambda } }
            steps{
                withAWS(credentials: 'AWS_Creds', region: 'ap-southeast-2') {
                    echo "Deleting lambda $lambdaName and role $lambdaRole"
                    sh 'aws lambda delete-function --function-name $lambdaName'
                    sh """
                        aws iam detach-role-policy \
                            --role-name ${lambdaRole} \
                            --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
                        aws iam detach-role-policy \\
                            --role-name ${lambdaRole} \\
                            --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
                        aws iam delete-role --role-name ${lambdaRole}
                    """
                    echo "Deleting dynamoDB"
                    sh  'aws dynamodb delete-table --table-name $dynamoTable'
                }
            }
        }
    }

    post {
        always {
            // One or more steps need to be included within each condition's block.
            cleanWs()
        }
    }
}
