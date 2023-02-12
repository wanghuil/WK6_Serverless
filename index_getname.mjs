'use strict';
// Load the AWS SDK for Node.js
var AWS = require('aws-sdk');
AWS.config.update({region: 'ap-southeast-2'})

// Create the DynamoDB service object
var ddb = new AWS.DynamoDB({apiVersion: '2012-08-10'});

exports.handler = async (event) => {
    let name=''
    let responseCode = 200;
    let response = {
        statusCode: responseCode,
        body: undefined,
        headers: {
            "Content-Type": "application/json",
        },
    }

    if (event.body) {
        let body = JSON.parse(event.body)
        if (body.name)
            name = body.name;
        else {
            response.statusCode = 400
            response.body = "Missing name"
            return response
        }
    }
    else {
        response.statusCode = 400
        response.body = "Must have body"
        return response
    }

    var params = {
        ExpressionAttributeNames: {
            "#NM": "name"
        },
        ExpressionAttributeValues: {
            ":a": {
                S: name
            }
        },
        FilterExpression: "#NM = :a",
        ProjectionExpression: "#NM,city",
        TableName: "HelloWorldTable"
    };
    let ddbResponse = await ddb.scan(params, function(err, data) {
        if (err) console.log(err, err.stack); // an error occurred
        else console.log(data);
    }).promise();

    response.body = JSON.stringify(ddbResponse)
    return response;
}