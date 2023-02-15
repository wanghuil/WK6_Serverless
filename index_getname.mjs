// Load the AWS SDK for Node.js
import { DynamoDBClient, ScanCommand  } from "@aws-sdk/client-dynamodb";
// Create the DynamoDB service object
const client = new DynamoDBClient({
  region: "ap-southeast-2"
});
'use strict';

export const handler = async (event) => {
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

    let params = {
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
    console.log("params: ", params)
    const ScanNameCommand = new ScanCommand(params);

    try {
        const data = await client.send(ScanNameCommand);
        console.log("Item fetched successfully:", JSON.stringify(data, null, 2));
        response.body = JSON.stringify(data);
      } catch (err) {
        console.error("Error getting item:", err);
    };

    return response;
}