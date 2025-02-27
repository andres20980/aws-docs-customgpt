#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
cd function
GOOS=linux go build -tags lambda.norpc -o bootstrap main.go
cd ../
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name blank-go --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# Blank function (Go)

![Architecture](/sample-apps/blank-go/images/sample-blank-go.png)

The project source includes function code and supporting resources:

- `function` - A Golang function.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- [Go executable](https://golang.org/dl/).
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/blank-go

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    blank-go$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

# Deploy

To deploy the application, run `2-deploy.sh`.

    blank-go$ ./2-deploy.sh
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Successfully created/updated stack - blank-go

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

# Test
To invoke the function, run `3-invoke.sh`.

    blank-go$ ./3-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    "{\"FunctionCount\":42,\"TotalCodeSize\":361861771}"

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map.

![Service Map](/sample-apps/blank-go/images/blank-go-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/blank-go/images/blank-go-trace.png)

# Cleanup
To delete the application, run `4-cleanup.sh`.

    blank$ ./4-cleanup.sh



package main

import (
	"os"
	"encoding/json"
	"time"
	"context"
	"testing"
	"strings"
	"io/ioutil"
	"github.com/aws/aws-lambda-go/lambdacontext"
	"github.com/aws/aws-lambda-go/events"
)

func TestMain(t *testing.T) {
	d := time.Now().Add(50 * time.Millisecond)
	os.Setenv("AWS_LAMBDA_FUNCTION_NAME","blank-go")
	ctx, _ := context.WithDeadline(context.Background(), d)
	ctx = lambdacontext.NewContext(ctx, &lambdacontext.LambdaContext{
		AwsRequestID:       "495b12a8-xmpl-4eca-8168-160484189f99",
		InvokedFunctionArn: "arn:aws:lambda:us-east-2:123456789012:function:blank-go",
	})
	inputJson := ReadJSONFromFile(t, "../event.json")
	var event events.SQSEvent
	err := json.Unmarshal(inputJson, &event)
	if err != nil {
		t.Errorf("could not unmarshal event. details: %v", err)
	}
	//var inputEvent SQSEvent
	result, err := handleRequest(ctx, event)
	if err != nil  {
	t.Log(err)
	}
	t.Log(result)
	if !strings.Contains(result, "FunctionCount") {
		t.Errorf("Output does not contain FunctionCount.")
	}
}
func ReadJSONFromFile(t *testing.T, inputFile string) []byte {
	inputJSON, err := ioutil.ReadFile(inputFile)
	if err != nil {
		t.Errorf("could not open test file. details: %v", err)
	}

	return inputJSON
}



github.com/aws/aws-lambda-go v1.43.0 h1:Tdu7SnMB5bD+CbdnSq1Dg4sM68vEuGIDcQFZ+IjUfx0=
github.com/aws/aws-lambda-go v1.43.0/go.mod h1:dpMpZgvWx5vuQJfBt0zqBha60q7Dd7RfgJv23DymV8A=
github.com/aws/aws-sdk-go v1.49.12 h1:SbGHDdMjtuTL8zpRXKjvIvQHLt9cCqcxcHoJps23WxI=
github.com/aws/aws-sdk-go v1.49.12/go.mod h1:LF8svs817+Nz+DmiMQKTO3ubZ/6IaTpq3TjupRn3Eqk=
github.com/davecgh/go-spew v1.1.0/go.mod h1:J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=
github.com/davecgh/go-spew v1.1.1 h1:vj9j/u1bqnvCEfJOwUhtlOARqs3+rkHYY13jYWTU97c=
github.com/jmespath/go-jmespath v0.4.0 h1:BEgLn5cpjn8UN1mAw4NjwDrS35OdebyEtFe+9YPoQUg=
github.com/jmespath/go-jmespath v0.4.0/go.mod h1:T8mJZnbsbmF+m6zOOFylbeCJqk5+pHWvzYPziyZiYoo=
github.com/jmespath/go-jmespath/internal/testify v1.5.1 h1:shLQSRRSCCPj3f2gpwzGwWFoC7ycTf1rcQZHOlsJ6N8=
github.com/jmespath/go-jmespath/internal/testify v1.5.1/go.mod h1:L3OGu8Wl2/fWfCI6z80xFu9LTZmf1ZRjMHUOPmWr69U=
github.com/pmezard/go-difflib v1.0.0 h1:4DBwDE0NGyQoBHbLQYPwSUPoCMWR5BEzIk/f1lZbAQM=
github.com/pmezard/go-difflib v1.0.0/go.mod h1:iKH77koFhYxTK1pcRnkKkqfTogsbg7gZNVY4sRDYZ/4=
github.com/stretchr/objx v0.1.0/go.mod h1:HFkY916IF+rwdDfMAkV7OtwuqBVzrE8GR6GFx+wExME=
github.com/stretchr/testify v1.7.2 h1:4jaiDzPyXQvSd7D0EjG45355tLlV3VOECpq10pLC+8s=
golang.org/x/net v0.17.0 h1:pVaXccu2ozPjCXewfr1S7xza/zcXTity9cCdXQYSjIM=
golang.org/x/text v0.13.0 h1:ablQoSUd0tRdKxZewP80B+BaqeKJuVhuRxj/dkrun3k=
gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405/go.mod h1:Co6ibVJAznAaIkqp8huTwlJQCZ016jof/cbN4VW5Yz0=
gopkg.in/yaml.v2 v2.2.8 h1:obN1ZagJSUGI0Ek/LBmuj4SNLPfIny3KsKFopxRdj10=
gopkg.in/yaml.v2 v2.2.8/go.mod h1:hI93XBmqTisBFMUTm0b8Fm+jr3Dg1NNxqwp+5A1VGuI=
gopkg.in/yaml.v3 v3.0.1 h1:fxVm/GzAzEWqLHuvctI91KS9hhNmmWOoWu0XTYJS7CA=


package main

import (
	"context"
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	runtime "github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-lambda-go/lambdacontext"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
	"log"
	"os"
)

var client = lambda.New(session.New())

func callLambda() (string, error) {
	input := &lambda.GetAccountSettingsInput{}
	req, resp := client.GetAccountSettingsRequest(input)
	err := req.Send()
	output, _ := json.Marshal(resp.AccountUsage)
	return string(output), err
}

func handleRequest(ctx context.Context, event events.SQSEvent) (string, error) {
	// event
	eventJson, _ := json.MarshalIndent(event, "", "  ")
	log.Printf("EVENT: %s", eventJson)
	// environment variables
	log.Printf("REGION: %s", os.Getenv("AWS_REGION"))
	log.Println("ALL ENV VARS:")
	for _, element := range os.Environ() {
		log.Println(element)
	}
	// request context
	lc, _ := lambdacontext.FromContext(ctx)
	log.Printf("REQUEST ID: %s", lc.AwsRequestID)
	// global variable
	log.Printf("FUNCTION NAME: %s", lambdacontext.FunctionName)
	// context method
	deadline, _ := ctx.Deadline()
	log.Printf("DEADLINE: %s", deadline)
	// AWS SDK call
	usage, err := callLambda()
	if err != nil {
		return "ERROR", err
	}
	return usage, nil
}

func main() {
	runtime.Start(handleRequest)
}



module github.com/awsdocs/aws-lambda-developer-guide/sample-apps/blank-go

go 1.20

require (
github.com/aws/aws-lambda-go v1.43.0
github.com/aws/aws-sdk-go v1.49.12
)

require github.com/jmespath/go-jmespath v0.4.0 // indirect


#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name blank-go --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



#!/bin/bash
set -eo pipefail
REGION=$(aws configure get region)
cd function
AWS_REGION=$REGION go test


AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Metadata:
      BuildMethod: go1.x
    Properties:
      CodeUri: function/ # folder where your main program resides
      Handler: bootstrap
      Runtime: provided.al2023
      Timeout: 5
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
      Tracing: Active


{
  "Records": [
    {
      "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
      "receiptHandle": "MessageReceiptHandle",
      "body": "Hello from SQS!",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
      "awsRegion": "us-west-2"
    }
  ]
}



#!/bin/bash
set -eo pipefail
STACK=blank-go
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json function/main



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
cd function
pwsh package.ps1
cd ../
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name blank-powershell --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# Blank function (PowerShell)

![Architecture](/sample-apps/blank-powershell/images/sample-blank-powershell.png)

The project source includes function code and supporting resources:

- `function` - A PowerShell function.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- [PowerShell 7.0](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell#powershell-core)
- [.NET Core 3.1](https://www.microsoft.com/net/download)
- [AWSLambdaPSCore module 2.0](https://www.powershellgallery.com/packages/AWSLambdaPSCore/2.0.0.0)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/blank-powershell

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    blank-powershell$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

# Deploy
To deploy the application, run `2-deploy.sh`.

    blank-powershell$ ./2-deploy.sh
    Restoring .NET Lambda deployment tool
    Initiate packaging
    Uploading to e678bc216e6a0d510d661ca9ae2fd941  28800329 / 28800329.0  (100.00%)
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Waiting for stack create/update to complete
    Successfully created/updated stack - blank-powershell

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

# Test
To invoke the function, run `3-invoke.sh`.

    blank-powershell$ ./3-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    {
      "AccountUsage": {
        "FunctionCount": 44,
        "TotalCodeSize": 391675850
      }
    }

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map. The following service map shows the function calling Amazon S3.

![Service Map](/sample-apps/blank-powershell/images/blank-powershell-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/blank-powershell/images/blank-powershell-trace.png)

# Cleanup
To delete the application, run `4-cleanup.sh`.

    blank-powershell$ ./4-cleanup.sh



New-AWSPowerShellLambdaPackage -ScriptPath ./Handler.ps1 -OutputPackage function.zip


#Requires -Modules @{ModuleName='AWSPowerShell.NetCore';ModuleVersion='3.3.618.0'}
Write-Host `## Environment variables
Write-Host AWS_LAMBDA_FUNCTION_VERSION=$Env:AWS_LAMBDA_FUNCTION_VERSION
Write-Host AWS_LAMBDA_LOG_GROUP_NAME=$Env:AWS_LAMBDA_LOG_GROUP_NAME
Write-Host AWS_LAMBDA_LOG_STREAM_NAME=$Env:AWS_LAMBDA_LOG_STREAM_NAME
Write-Host AWS_EXECUTION_ENV=$Env:AWS_EXECUTION_ENV
Write-Host AWS_LAMBDA_FUNCTION_NAME=$Env:AWS_LAMBDA_FUNCTION_NAME
Write-Host PATH=$Env:PATH
Write-Host `## Event
Write-Host (ConvertTo-Json -InputObject $LambdaInput -Compress -Depth 3)
Write-Host `## Context
Write-Host (ConvertTo-Json -InputObject $LambdaContext -Compress -Depth 3)
# Process event
foreach ($message in $LambdaInput.Records)
{
    Write-Host $message.body
}
# Call Lambda API
Get-LMAccountSetting | Select-Object -Property AccountUsage


#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name blank-powershell --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      Handler: Handler::Handler.Bootstrap::ExecuteFunction
      Runtime: dotnetcore3.1
      CodeUri: function/function.zip
      Description: Call the AWS Lambda API
      Timeout: 30
      MemorySize: 512
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
      Tracing: Active



{
  "Records": [
    {
      "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
      "receiptHandle": "MessageReceiptHandle",
      "body": "Hello from SQS!",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
      "awsRegion": "us-west-2"
    }
  ]
}



#!/bin/bash
set -eo pipefail
STACK=blank-powershell
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf function/function.zip



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name nodejs-apig --capabilities CAPABILITY_NAMED_IAM



{
    "version": "2.0",
    "routeKey": "ANY /nodejs-apig-function-1G3XMPLZXVXYI",
    "rawPath": "/default/nodejs-apig-function-1G3XMPLZXVXYI",
    "rawQueryString": "",
    "cookies": [
        "s_fid=7AABXMPL1AFD9BBF-0643XMPL09956DE2",
        "regStatus=pre-register"
    ],
    "headers": {
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "accept-encoding": "gzip, deflate, br",
        "accept-language": "en-US,en;q=0.9",
        "content-length": "0",
        "host": "r3pmxmplak.execute-api.us-east-2.amazonaws.com",
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "cross-site",
        "sec-fetch-user": "?1",
        "upgrade-insecure-requests": "1",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
        "x-amzn-trace-id": "Root=1-5e6722a7-cc56xmpl46db7ae02d4da47e",
        "x-forwarded-for": "205.255.255.176",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https"
    },
    "requestContext": {
        "accountId": "123456789012",
        "apiId": "r3pmxmplak",
        "domainName": "r3pmxmplak.execute-api.us-east-2.amazonaws.com",
        "domainPrefix": "r3pmxmplak",
        "http": {
            "method": "GET",
            "path": "/default/nodejs-apig-function-1G3XMPLZXVXYI",
            "protocol": "HTTP/1.1",
            "sourceIp": "205.255.255.176",
            "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
        },
        "requestId": "JKJaXmPLvHcESHA=",
        "routeKey": "ANY /nodejs-apig-function-1G3XMPLZXVXYI",
        "stage": "default",
        "time": "10/Mar/2020:05:16:23 +0000",
        "timeEpoch": 1583817383220
    },
    "isBase64Encoded": true
}


#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# API Gateway proxy integration with Node.js

This sample application is a Lambda function that processes events from an API Gateway REST API. The API provides a public endpoint that you can access with a web browser or other HTTP client. When you send a request to the endpoint, the API serializes the request and sends it to the function. The function calls the Lambda API to get utilization data and returns it to the API in the required format.

:warning: The application creates a public API endpoint that is accessible over the internet. When you're done testing, run the cleanup script to delete it.

![Architecture](/sample-apps/nodejs-apig/images/sample-nodejs-apig.png)

The project source includes function code and supporting resources:

- `function` - A Node.js function.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- [Node.js 18 with npm](https://nodejs.org/en/download/releases/)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/nodejs-apig

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    nodejs-apig$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

# Deploy
To deploy the application, run `2-deploy.sh`.

    nodejs-apig$ ./2-deploy.sh
    added 16 packages from 18 contributors and audited 18 packages in 0.926s
    added 17 packages from 19 contributors and audited 19 packages in 0.916s
    Uploading to e678bc216e6a0d510d661ca9ae2fd941  2737254 / 2737254.0  (100.00%)
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Waiting for stack create/update to complete
    Successfully created/updated stack - nodejs-apig

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

# Test
To invoke the function directly with a test event (`event.json`), run `3-invoke.sh`.

    nodejs-apig$ ./3-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }

Let the script invoke the function a few times and then press `CRTL+C` to exit.

To invoke the function with the REST API, run the `4-get.sh` script. This script uses cURL to send a GET request to the API endpoint.

    nodejs-apig$ ./4-get.sh
    > GET /api/ HTTP/1.1
    > Host: mf2fxmplbj.execute-api.us-east-2.amazonaws.com
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Content-Type: application/json
    < Content-Length: 55
    < Connection: keep-alive
    < x-amzn-RequestId: cb863771-xmpl-47cb-869e-3433209223a8
    < X-Custom-Header: My value
    < X-Custom-Header: My other value
    < X-Amzn-Trace-Id: Root=1-5e67ea83-4826xmpl9be7bf422bf70049
    ...
    {
      "TotalCodeSize": 184440616,
      "FunctionCount": 39
    }

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map. The following service map shows the function invoked in two ways.

![Service Map](/sample-apps/nodejs-apig/images/nodejs-apig-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/nodejs-apig/images/nodejs-apig-trace.png)

Finally, view the application in the Lambda console.

*To view the application*
1. Open the [applications page](https://console.aws.amazon.com/lambda/home#/applications) in the Lambda console.
2. Choose **nodejs-apig**.

  ![Application](/sample-apps/nodejs-apig/images/nodejs-apig-application.png)

# Cleanup
To delete the application, run `5-cleanup.sh`.

    nodejs-apig$ ./5-cleanup.sh



{
  "name": "nodejs-apig",
  "version": "1.0.0",
  "private": true,
  "devDependencies": {
    "aws-sdk": "2.814.0"
  }
}



#!/bin/bash
set -eo pipefail
STACK=nodejs-apig
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf function/node_modules function/package-lock.json



import {LambdaClient, GetAccountSettingsCommand} from '@aws-sdk/client-lambda';
// Create client outside of handler to reuse
const lambda = new LambdaClient()

// Handler
export const handler = async (event, context) => {
  console.log('## ENVIRONMENT VARIABLES: ' + serialize(process.env))
  console.log('## CONTEXT: ' + serialize(context))
  console.log('## EVENT: ' + serialize(event))
  try {
    let accountSettings = await lambda.send(new GetAccountSettingsCommand())
    return formatResponse(serialize(accountSettings.AccountUsage))
  } catch(error) {
    return formatError(error)
  }
}

var formatResponse = function(body){
  var response = {
    "statusCode": 200,
    "headers": {
      "Content-Type": "application/json"
    },
    "isBase64Encoded": false,
    "multiValueHeaders": { 
      "X-Custom-Header": ["My value", "My other value"],
    },
    "body": body
  }
  return response
}

var formatError = function(error){
  var response = {
    "statusCode": error.statusCode,
    "headers": {
      "Content-Type": "text/plain",
      "x-amzn-ErrorType": error.code
    },
    "isBase64Encoded": false,
    "body": error.code + ": " + error.message
  }
  return response
}
// Use SDK client
var getAccountSettings = function(){
  return lambda.getAccountSettings().promise()
}

var serialize = function(object) {
  return JSON.stringify(object, null, 2)
}


#!/bin/bash
set -eo pipefail
APIID=$(aws cloudformation describe-stack-resource --stack-name nodejs-apig --logical-resource-id api --query 'StackResourceDetail.PhysicalResourceId' --output text)
REGION=$(aws configure get region)

curl https://$APIID.execute-api.$REGION.amazonaws.com/api/ -v


#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name nodejs-apig --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  api:
    Type: AWS::Serverless::Api
    Properties:
      StageName: api
      TracingEnabled: true
      OpenApiVersion: 3.0.2
  function:
    Type: AWS::Serverless::Function
    Properties:
      Handler: index.handler
      Runtime: nodejs18.x
      CodeUri: function/.
      Description: Call the AWS Lambda API
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
      Tracing: Active
      Events:
        getEndpoint:
          Type: Api
          Properties:
            RestApiId: !Ref api
            Path: /
            Method: GET



{
    "resource": "/",
    "path": "/",
    "httpMethod": "GET",
    "headers": {
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "accept-encoding": "gzip, deflate, br",
        "accept-language": "en-US,en;q=0.9",
        "cookie": "s_fid=7AAB6XMPLAFD9BBF-0643XMPL09956DE2; regStatus=pre-register",
        "Host": "70ixmpl4fl.execute-api.us-east-2.amazonaws.com",
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "none",
        "upgrade-insecure-requests": "1",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
        "X-Amzn-Trace-Id": "Root=1-5e66d96f-7491f09xmpl79d18acf3d050",
        "X-Forwarded-For": "52.255.255.12",
        "X-Forwarded-Port": "443",
        "X-Forwarded-Proto": "https"
    },
    "multiValueHeaders": {
        "accept": [
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
        ],
        "accept-encoding": [
            "gzip, deflate, br"
        ],
        "accept-language": [
            "en-US,en;q=0.9"
        ],
        "cookie": [
            "s_fid=7AABXMPL1AFD9BBF-0643XMPL09956DE2; regStatus=pre-register;"
        ],
        "Host": [
            "70ixmpl4fl.execute-api.ca-central-1.amazonaws.com"
        ],
        "sec-fetch-dest": [
            "document"
        ],
        "sec-fetch-mode": [
            "navigate"
        ],
        "sec-fetch-site": [
            "none"
        ],
        "upgrade-insecure-requests": [
            "1"
        ],
        "User-Agent": [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
        ],
        "X-Amzn-Trace-Id": [
            "Root=1-5e66d96f-7491f09xmpl79d18acf3d050"
        ],
        "X-Forwarded-For": [
            "52.255.255.12"
        ],
        "X-Forwarded-Port": [
            "443"
        ],
        "X-Forwarded-Proto": [
            "https"
        ]
    },
    "queryStringParameters": null,
    "multiValueQueryStringParameters": null,
    "pathParameters": null,
    "stageVariables": null,
    "requestContext": {
        "resourceId": "2gxmpl",
        "resourcePath": "/",
        "httpMethod": "GET",
        "extendedRequestId": "JJbxmplHYosFVYQ=",
        "requestTime": "10/Mar/2020:00:03:59 +0000",
        "path": "/Prod/",
        "accountId": "123456789012",
        "protocol": "HTTP/1.1",
        "stage": "Prod",
        "domainPrefix": "70ixmpl4fl",
        "requestTimeEpoch": 1583798639428,
        "requestId": "77375676-xmpl-4b79-853a-f982474efe18",
        "identity": {
            "cognitoIdentityPoolId": null,
            "accountId": null,
            "cognitoIdentityId": null,
            "caller": null,
            "sourceIp": "52.255.255.12",
            "principalOrgId": null,
            "accessKey": null,
            "cognitoAuthenticationType": null,
            "cognitoAuthenticationProvider": null,
            "userArn": null,
            "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
            "user": null
        },
        "domainName": "70ixmpl4fl.execute-api.us-east-2.amazonaws.com",
        "apiId": "70ixmpl4fl"
    },
    "body": null,
    "isBase64Encoded": false
}


#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# Blank function (Ruby)

![Architecture](/sample-apps/blank-ruby/images/sample-blank-ruby.png)

The project source includes function code and supporting resources:

- `function` - A Ruby function.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `1-create-bucket.sh`, `2-build-layer.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- [Ruby 2.5](https://www.ruby-lang.org/en/downloads/)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/blank-ruby

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    blank-ruby$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

To build a Lambda layer that contains the function's runtime dependencies, run `2-build-layer.sh`. The script installs Bundler and uses it to install the application's libraries in a folder named `lib`.

    blank-ruby$ ./2-build-layer.sh

The `lib` folder is used to create a Lambda layer during deployment. Packaging dependencies in a layer reduces the size of the deployment package that you upload when you modify your code.

# Deploy
To deploy the application, run `3-deploy.sh`.

    blank-ruby$ ./3-deploy.sh
    Uploading to e678bc216e6a0d510d661ca9ae2fd941  2737254 / 2737254.0  (100.00%)
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Waiting for stack create/update to complete
    Successfully created/updated stack - blank-ruby

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

# Test
To invoke the function, run `4-invoke.sh`.

    blank-ruby$ ./4-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map. The following service map shows the function calling Amazon S3.

![Service Map](/sample-apps/blank-ruby/images/blank-ruby-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/blank-ruby/images/blank-ruby-trace.png)

# Cleanup
To delete the application, run `5-cleanup.sh`.

    blank-ruby$ ./5-cleanup.sh



#!/bin/bash
set -eo pipefail
STACK=blank-ruby
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf lib



# Gemfile
source 'https://rubygems.org'

gem 'aws-xray-sdk', '0.11.4'
gem 'aws-sdk-lambda', '1.39.0'
gem 'test-unit', '3.3.5'


require_relative 'lambda_function'
require 'test/unit'
require 'json'
require 'logger'
require 'aws-xray-sdk/lambda'

XRay.recorder.configure({ context_missing: 'LOG_ERROR' })

class TestFunction < Test::Unit::TestCase
  logger = Logger.new($stdout)

  def test_invoke
    file = File.read('event.json')
    event = JSON.parse(file)
    context = Hash.new
    result = lambda_handler(event: event, context: context)
    assert_match('function_count', result.to_s, 'Should match')
  end

end


# lambda_function.rb
require 'logger'
require 'json'
require 'aws-sdk-lambda'
$client = Aws::Lambda::Client.new()
$client.get_account_settings()

require 'aws-xray-sdk/lambda'

def lambda_handler(event:, context:)
  logger = Logger.new($stdout)
  logger.info('## ENVIRONMENT VARIABLES')
  vars = Hash.new
  ENV.each do |variable|
    vars[variable[0]] = variable[1]
  end
  logger.info(vars.to_json)
  logger.info('## EVENT')
  logger.info(event.to_json)
  logger.info('## CONTEXT')
  logger.info(context)
  $client.get_account_settings().account_usage.to_h
end


AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      Handler: lambda_function.lambda_handler
      Runtime: ruby2.7
      CodeUri: function/.
      Description: Call the AWS Lambda API
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
      Tracing: Active
      Environment:
          Variables:
            GEM_PATH: /opt/ruby/2.7.0
      Layers:
        - !Ref libs
  libs:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: blank-ruby-lib
      Description: Dependencies for the blank-ruby sample app.
      ContentUri: lib/.
      CompatibleRuntimes:
        - ruby2.7




#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name blank-ruby --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name blank-ruby --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
set -eo pipefail
if [ ! -d lib ]; then
  echo "Installing libraries..."
  ./2-build-layer.sh
fi
GEM_PATH=lib/ruby/2.5.0
ruby function/lambda_function.test.rb



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      Handler: lambda_function.lambda_handler
      Runtime: ruby2.5
      CodeUri: function/.
      Description: Call the AWS Lambda API
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
      Tracing: Active
      Environment:
          Variables:
            GEM_PATH: /opt/ruby/2.5.0
      Layers:
        - !Ref libs
  libs:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: blank-ruby-lib
      Description: Dependencies for the blank-ruby sample app.
      ContentUri: lib/.
      CompatibleRuntimes:
        - ruby2.5




{
  "Records": [
    {
      "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
      "receiptHandle": "MessageReceiptHandle",
      "body": "Hello from SQS!",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
      "awsRegion": "us-west-2"
    }
  ]
}



#!/bin/bash
set -eo pipefail
gem install bundler
rm -rf lib
cd function
rm -f Gemfile.lock
bundle config set path '../lib'
bundle install


github.com/aws/aws-lambda-go v1.47.0 h1:0H8s0vumYx/YKs4sE7YM0ktwL2eWse+kfopsRI1sXVI=
github.com/aws/aws-lambda-go v1.47.0/go.mod h1:dpMpZgvWx5vuQJfBt0zqBha60q7Dd7RfgJv23DymV8A=
github.com/aws/aws-sdk-go-v2 v1.30.3 h1:jUeBtG0Ih+ZIFH0F4UkmL9w3cSpaMv9tYYDbzILP8dY=
github.com/aws/aws-sdk-go-v2 v1.30.3/go.mod h1:nIQjQVp5sfpQcTc9mPSr1B0PaWK5ByX9MOoDadSN4lc=
github.com/aws/aws-sdk-go-v2/aws/protocol/eventstream v1.6.3 h1:tW1/Rkad38LA15X4UQtjXZXNKsCgkshC3EbmcUmghTg=
github.com/aws/aws-sdk-go-v2/aws/protocol/eventstream v1.6.3/go.mod h1:UbnqO+zjqk3uIt9yCACHJ9IVNhyhOCnYk8yA19SAWrM=
github.com/aws/aws-sdk-go-v2/config v1.27.27 h1:HdqgGt1OAP0HkEDDShEl0oSYa9ZZBSOmKpdpsDMdO90=
github.com/aws/aws-sdk-go-v2/config v1.27.27/go.mod h1:MVYamCg76dFNINkZFu4n4RjDixhVr51HLj4ErWzrVwg=
github.com/aws/aws-sdk-go-v2/credentials v1.17.27 h1:2raNba6gr2IfA0eqqiP2XiQ0UVOpGPgDSi0I9iAP+UI=
github.com/aws/aws-sdk-go-v2/credentials v1.17.27/go.mod h1:gniiwbGahQByxan6YjQUMcW4Aov6bLC3m+evgcoN4r4=
github.com/aws/aws-sdk-go-v2/feature/ec2/imds v1.16.11 h1:KreluoV8FZDEtI6Co2xuNk/UqI9iwMrOx/87PBNIKqw=
github.com/aws/aws-sdk-go-v2/feature/ec2/imds v1.16.11/go.mod h1:SeSUYBLsMYFoRvHE0Tjvn7kbxaUhl75CJi1sbfhMxkU=
github.com/aws/aws-sdk-go-v2/internal/configsources v1.3.15 h1:SoNJ4RlFEQEbtDcCEt+QG56MY4fm4W8rYirAmq+/DdU=
github.com/aws/aws-sdk-go-v2/internal/configsources v1.3.15/go.mod h1:U9ke74k1n2bf+RIgoX1SXFed1HLs51OgUSs+Ph0KJP8=
github.com/aws/aws-sdk-go-v2/internal/endpoints/v2 v2.6.15 h1:C6WHdGnTDIYETAm5iErQUiVNsclNx9qbJVPIt03B6bI=
github.com/aws/aws-sdk-go-v2/internal/endpoints/v2 v2.6.15/go.mod h1:ZQLZqhcu+JhSrA9/NXRm8SkDvsycE+JkV3WGY41e+IM=
github.com/aws/aws-sdk-go-v2/internal/ini v1.8.0 h1:hT8rVHwugYE2lEfdFE0QWVo81lF7jMrYJVDWI+f+VxU=
github.com/aws/aws-sdk-go-v2/internal/ini v1.8.0/go.mod h1:8tu/lYfQfFe6IGnaOdrpVgEL2IrrDOf6/m9RQum4NkY=
github.com/aws/aws-sdk-go-v2/internal/v4a v1.3.15 h1:Z5r7SycxmSllHYmaAZPpmN8GviDrSGhMS6bldqtXZPw=
github.com/aws/aws-sdk-go-v2/internal/v4a v1.3.15/go.mod h1:CetW7bDE00QoGEmPUoZuRog07SGVAUVW6LFpNP0YfIg=
github.com/aws/aws-sdk-go-v2/service/internal/accept-encoding v1.11.3 h1:dT3MqvGhSoaIhRseqw2I0yH81l7wiR2vjs57O51EAm8=
github.com/aws/aws-sdk-go-v2/service/internal/accept-encoding v1.11.3/go.mod h1:GlAeCkHwugxdHaueRr4nhPuY+WW+gR8UjlcqzPr1SPI=
github.com/aws/aws-sdk-go-v2/service/internal/checksum v1.3.17 h1:YPYe6ZmvUfDDDELqEKtAd6bo8zxhkm+XEFEzQisqUIE=
github.com/aws/aws-sdk-go-v2/service/internal/checksum v1.3.17/go.mod h1:oBtcnYua/CgzCWYN7NZ5j7PotFDaFSUjCYVTtfyn7vw=
github.com/aws/aws-sdk-go-v2/service/internal/presigned-url v1.11.17 h1:HGErhhrxZlQ044RiM+WdoZxp0p+EGM62y3L6pwA4olE=
github.com/aws/aws-sdk-go-v2/service/internal/presigned-url v1.11.17/go.mod h1:RkZEx4l0EHYDJpWppMJ3nD9wZJAa8/0lq9aVC+r2UII=
github.com/aws/aws-sdk-go-v2/service/internal/s3shared v1.17.15 h1:246A4lSTXWJw/rmlQI+TT2OcqeDMKBdyjEQrafMaQdA=
github.com/aws/aws-sdk-go-v2/service/internal/s3shared v1.17.15/go.mod h1:haVfg3761/WF7YPuJOER2MP0k4UAXyHaLclKXB6usDg=
github.com/aws/aws-sdk-go-v2/service/s3 v1.58.3 h1:hT8ZAZRIfqBqHbzKTII+CIiY8G2oC9OpLedkZ51DWl8=
github.com/aws/aws-sdk-go-v2/service/s3 v1.58.3/go.mod h1:Lcxzg5rojyVPU/0eFwLtcyTaek/6Mtic5B1gJo7e/zE=
github.com/aws/aws-sdk-go-v2/service/sso v1.22.4 h1:BXx0ZIxvrJdSgSvKTZ+yRBeSqqgPM89VPlulEcl37tM=
github.com/aws/aws-sdk-go-v2/service/sso v1.22.4/go.mod h1:ooyCOXjvJEsUw7x+ZDHeISPMhtwI3ZCB7ggFMcFfWLU=
github.com/aws/aws-sdk-go-v2/service/ssooidc v1.26.4 h1:yiwVzJW2ZxZTurVbYWA7QOrAaCYQR72t0wrSBfoesUE=
github.com/aws/aws-sdk-go-v2/service/ssooidc v1.26.4/go.mod h1:0oxfLkpz3rQ/CHlx5hB7H69YUpFiI1tql6Q6Ne+1bCw=
github.com/aws/aws-sdk-go-v2/service/sts v1.30.3 h1:ZsDKRLXGWHk8WdtyYMoGNO7bTudrvuKpDKgMVRlepGE=
github.com/aws/aws-sdk-go-v2/service/sts v1.30.3/go.mod h1:zwySh8fpFyXp9yOr/KVzxOl8SRqgf/IDw5aUt9UKFcQ=
github.com/aws/smithy-go v1.20.3 h1:ryHwveWzPV5BIof6fyDvor6V3iUL7nTfiTKXHiW05nE=
github.com/aws/smithy-go v1.20.3/go.mod h1:krry+ya/rV9RDcV/Q16kpu6ypI4K2czasz0NC3qS14E=
github.com/davecgh/go-spew v1.1.1 h1:vj9j/u1bqnvCEfJOwUhtlOARqs3+rkHYY13jYWTU97c=
github.com/davecgh/go-spew v1.1.1/go.mod h1:J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=
github.com/pmezard/go-difflib v1.0.0 h1:4DBwDE0NGyQoBHbLQYPwSUPoCMWR5BEzIk/f1lZbAQM=
github.com/pmezard/go-difflib v1.0.0/go.mod h1:iKH77koFhYxTK1pcRnkKkqfTogsbg7gZNVY4sRDYZ/4=
github.com/stretchr/testify v1.7.2 h1:4jaiDzPyXQvSd7D0EjG45355tLlV3VOECpq10pLC+8s=
github.com/stretchr/testify v1.7.2/go.mod h1:R6va5+xMeoiuVRoj+gSkQ7d3FALtqAAGI1FQKckRals=
gopkg.in/yaml.v3 v3.0.1 h1:fxVm/GzAzEWqLHuvctI91KS9hhNmmWOoWu0XTYJS7CA=
gopkg.in/yaml.v3 v3.0.1/go.mod h1:K4uyk7z7BCEPqu6E+C64Yfv1cQ7kz7rIZviUmN+EgEM=



package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type Order struct {
	OrderID string  `json:"order_id"`
	Amount  float64 `json:"amount"`
	Item    string  `json:"item"`
}

var (
	s3Client *s3.Client
)

func init() {
	// Initialize the S3 client outside of the handler, during the init phase
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	s3Client = s3.NewFromConfig(cfg)
}

func uploadReceiptToS3(ctx context.Context, bucketName, key, receiptContent string) error {
	_, err := s3Client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: &bucketName,
		Key:    &key,
		Body:   strings.NewReader(receiptContent),
	})
	if err != nil {
		log.Printf("Failed to upload receipt to S3: %v", err)
		return err
	}
	return nil
}

func handleRequest(ctx context.Context, event json.RawMessage) error {
	// Parse the input event
	var order Order
	if err := json.Unmarshal(event, &order); err != nil {
		log.Printf("Failed to unmarshal event: %v", err)
		return err
	}

	// Access environment variables
	bucketName := os.Getenv("RECEIPT_BUCKET")
	if bucketName == "" {
		log.Printf("RECEIPT_BUCKET environment variable is not set")
		return fmt.Errorf("missing required environment variable RECEIPT_BUCKET")
	}

	// Create the receipt content and key destination
	receiptContent := fmt.Sprintf("OrderID: %s\nAmount: $%.2f\nItem: %s",
		order.OrderID, order.Amount, order.Item)
	key := "receipts/" + order.OrderID + ".txt"

	// Upload the receipt to S3 using the helper method
	if err := uploadReceiptToS3(ctx, bucketName, key, receiptContent); err != nil {
		return err
	}

	log.Printf("Successfully processed order %s and stored receipt in S3 bucket %s", order.OrderID, bucketName)
	return nil
}

func main() {
	lambda.Start(handleRequest)
}



{
  "order_id": "12345",
  "amount": 199.99,
  "item": "Wireless Headphones"
}



module example-go

go 1.22.6

require (
	github.com/aws/aws-lambda-go v1.47.0
	github.com/aws/aws-sdk-go-v2/config v1.27.27
	github.com/aws/aws-sdk-go-v2/service/s3 v1.58.3
)

require (
	github.com/aws/aws-sdk-go-v2 v1.30.3 // indirect
	github.com/aws/aws-sdk-go-v2/aws/protocol/eventstream v1.6.3 // indirect
	github.com/aws/aws-sdk-go-v2/credentials v1.17.27 // indirect
	github.com/aws/aws-sdk-go-v2/feature/ec2/imds v1.16.11 // indirect
	github.com/aws/aws-sdk-go-v2/internal/configsources v1.3.15 // indirect
	github.com/aws/aws-sdk-go-v2/internal/endpoints/v2 v2.6.15 // indirect
	github.com/aws/aws-sdk-go-v2/internal/ini v1.8.0 // indirect
	github.com/aws/aws-sdk-go-v2/internal/v4a v1.3.15 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/accept-encoding v1.11.3 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/checksum v1.3.17 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/presigned-url v1.11.17 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/s3shared v1.17.15 // indirect
	github.com/aws/aws-sdk-go-v2/service/sso v1.22.4 // indirect
	github.com/aws/aws-sdk-go-v2/service/ssooidc v1.26.4 // indirect
	github.com/aws/aws-sdk-go-v2/service/sts v1.30.3 // indirect
	github.com/aws/smithy-go v1.20.3 // indirect
)



[pytest]
markers =
    order: specify test execution order


AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  EncryptPDFFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: EncryptPDF
      Architectures: [x86_64]
      CodeUri: ./
      Handler: lambda_function.lambda_handler
      Runtime: python3.12
      Timeout: 15
      MemorySize: 256
      LoggingConfig:
        LogFormat: JSON
      Policies:
        - AmazonS3FullAccess
      Events:
        S3Event:
          Type: S3
          Properties:
            Bucket: !Ref PDFSourceBucket
            Events: s3:ObjectCreated:*

  PDFSourceBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: EXAMPLE-BUCKET

  EncryptedPDFBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: EXAMPLE-BUCKET-encrypted


from pypdf import PdfReader, PdfWriter
import uuid
import os
from urllib.parse import unquote_plus
import boto3

# Create the S3 client to download and upload objects from S3
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Iterate over the S3 event object and get the key for all uploaded files
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key']) # Decode the S3 object key to remove any URL-encoded characters
        download_path = f'/tmp/{uuid.uuid4()}.pdf' # Create a path in the Lambda tmp directory to save the file to 
        upload_path = f'/tmp/converted-{uuid.uuid4()}.pdf' # Create another path to save the encrypted file to
        
        # If the file is a PDF, encrypt it and upload it to the destination S3 bucket
        if key.lower().endswith('.pdf'):
            s3_client.download_file(bucket, key, download_path)
            encrypt_pdf(download_path, upload_path)
            encrypted_key = add_encrypted_suffix(key)
            s3_client.upload_file(upload_path, f'{bucket}-encrypted', encrypted_key)

# Define the function to encrypt the PDF file with a password
def encrypt_pdf(file_path, encrypted_file_path):
    reader = PdfReader(file_path)
    writer = PdfWriter()
    
    for page in reader.pages:
        writer.add_page(page)

    # Add a password to the new PDF
    # In this example, the password is hardcoded.
    # In a production application, don't hardcode passwords or other sensitive information.
    # We recommend you use AWS Secrets Manager to securely store passwords.
    writer.encrypt("my-secret-password")

    # Save the new PDF to a file
    with open(encrypted_file_path, "wb") as file:
        writer.write(file)

# Define a function to add a suffix to the original filename after encryption
def add_encrypted_suffix(original_key):
    filename, extension = original_key.rsplit('.', 1)
    return f'{filename}_encrypted.{extension}'


boto3
pypdf


import boto3
import json
import pytest
import time
import os

@pytest.fixture
def lambda_client():
    return boto3.client('lambda')
    
@pytest.fixture
def s3_client():
    return boto3.client('s3')

@pytest.fixture
def logs_client():
    return boto3.client('logs')

@pytest.fixture(scope='session')
def cleanup():
    # Create a new S3 client for cleanup
    s3_client = boto3.client('s3')

    yield
    # Cleanup code will be executed after all tests have finished

    # Delete test.pdf from the source bucket
    source_bucket = 'EXAMPLE-BUCKET'
    source_file_key = 'test.pdf'
    s3_client.delete_object(Bucket=source_bucket, Key=source_file_key)
    print(f"\nDeleted {source_file_key} from {source_bucket}")

    # Delete test_encrypted.pdf from the destination bucket
    destination_bucket = 'EXAMPLE-BUCKET-encrypted'
    destination_file_key = 'test_encrypted.pdf'
    s3_client.delete_object(Bucket=destination_bucket, Key=destination_file_key)
    print(f"Deleted {destination_file_key} from {destination_bucket}")
        

@pytest.mark.order(1)
def test_source_bucket_available(s3_client):
    s3_bucket_name = 'EXAMPLE-BUCKET'
    file_name = 'test.pdf'
    file_path = os.path.join(os.path.dirname(__file__), file_name)

    file_uploaded = False
    try:
        s3_client.upload_file(file_path, s3_bucket_name, file_name)
        file_uploaded = True
    except:
        print("Error: couldn't upload file")

    assert file_uploaded, "Could not upload file to S3 bucket"

    

@pytest.mark.order(2)
def test_lambda_invoked(logs_client):

    # Wait for a few seconds to make sure the logs are available
    time.sleep(5)

    # Get the latest log stream for the specified log group
    log_streams = logs_client.describe_log_streams(
        logGroupName='/aws/lambda/EncryptPDF',
        orderBy='LastEventTime',
        descending=True,
        limit=1
    )

    latest_log_stream_name = log_streams['logStreams'][0]['logStreamName']

    # Retrieve the log events from the latest log stream
    log_events = logs_client.get_log_events(
        logGroupName='/aws/lambda/EncryptPDF',
        logStreamName=latest_log_stream_name
    )

    success_found = False
    for event in log_events['events']:
        message = json.loads(event['message'])
        status = message.get('record', {}).get('status')
        if status == 'success':
            success_found = True
            break

    assert success_found, "Lambda function execution did not report 'success' status in logs."

@pytest.mark.order(3)
def test_encrypted_file_in_bucket(s3_client):
    # Specify the destination S3 bucket and the expected converted file key
    destination_bucket = 'EXAMPLE-BUCKET-encrypted'
    converted_file_key = 'test_encrypted.pdf'

    try:
        # Attempt to retrieve the metadata of the converted file from the destination S3 bucket
        s3_client.head_object(Bucket=destination_bucket, Key=converted_file_key)
    except s3_client.exceptions.ClientError as e:
        # If the file is not found, the test will fail
        pytest.fail(f"Converted file '{converted_file_key}' not found in the destination bucket: {str(e)}")

def test_cleanup(cleanup):
    # This test uses the cleanup fixture and will be executed last
    pass


#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="accountSettings">
    <option name="activeProfile" value="profile:default" />
    <option name="activeRegion" value="eu-central-1" />
    <option name="recentlyUsedProfiles">
      <list>
        <option value="profile:default" />
      </list>
    </option>
    <option name="recentlyUsedRegions">
      <list>
        <option value="eu-central-1" />
      </list>
    </option>
  </component>
</project>


<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectRootManager" version="2" project-jdk-name="Python 3.8" project-jdk-type="Python SDK" />
</project>


<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectModuleManager">
    <modules>
      <module fileurl="file://$PROJECT_DIR$/.idea/blank-python.iml" filepath="$PROJECT_DIR$/.idea/blank-python.iml" />
    </modules>
  </component>
</project>


<component name="InspectionProjectProfileManager">
  <settings>
    <option name="USE_PROJECT_PROFILE" value="false" />
    <version value="1.0" />
  </settings>
</component>


# Default ignored files
/shelf/
/workspace.xml
# Editor-based HTTP Client requests
/httpRequests/
# Datasource local storage ignored files
/dataSources/
/dataSources.local.xml



<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="VcsDirectoryMappings">
    <mapping directory="$PROJECT_DIR$/../.." vcs="Git" />
  </component>
</project>


<?xml version="1.0" encoding="UTF-8"?>
<module type="PYTHON_MODULE" version="4">
  <component name="NewModuleRootManager">
    <content url="file://$MODULE_DIR$" />
    <orderEntry type="jdk" jdkName="Python 3.8" jdkType="Python SDK" />
    <orderEntry type="sourceFolder" forTests="false" />
  </component>
</module>


# Blank function (Python)

![Architecture](/sample-apps/blank-python/images/sample-blank-python.png)

The project source includes function code and supporting resources:

- `function` - A Python function.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `1-create-bucket.sh`, `2-build-layer.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- [Python 3.11](https://www.python.org/downloads/). Sample also works with Python 3.9.
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    cd aws-lambda-developer-guide/sample-apps/blank-python

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    ./1-create-bucket.sh

Example output:

    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

To build a Lambda layer that contains the function's runtime dependencies, run `2-build-layer.sh`. Packaging dependencies in a layer reduces the size of the deployment package that you upload when you modify your code.

    ./2-build-layer.sh

# Deploy
To deploy the application, run `3-deploy.sh`.

    ./3-deploy.sh
    
Example output:

    Uploading to e678bc216e6a0d510d661ca9ae2fd941  9519118 / 9519118.0  (100.00%)
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Waiting for stack create/update to complete
    Successfully created/updated stack - blank-python

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

# Test
To invoke the function, run `4-invoke.sh`.

    ./4-invoke.sh

Example output:
      
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    {"TotalCodeSize": 410713698, "FunctionCount": 45}

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map. The following service map shows the function calling Amazon S3.

![Service Map](/sample-apps/blank-python/images/blank-python-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/blank-python/images/blank-python-trace.png)

# Cleanup
To delete the application, run `5-cleanup.sh`.

    ./5-cleanup.sh


#!/bin/bash
set -eo pipefail
STACK=blank-python
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json function/*.pyc
rm -rf package function/__pycache__



import os
import logging
import jsonpickle
import boto3
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

logger = logging.getLogger()
logger.setLevel(logging.INFO)
patch_all()

client = boto3.client('lambda')
client.get_account_settings()

def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES\r' + jsonpickle.encode(dict(**os.environ)))
    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))
    response = client.get_account_settings()
    return response['AccountUsage']



jsonpickle==1.3
aws-xray-sdk==2.4.3


import unittest
import importlib
import logging
import jsonpickle
import json
from aws_xray_sdk.core import xray_recorder

logger = logging.getLogger()
xray_recorder.configure(
  context_missing='LOG_ERROR'
)
#function = importlib.import_module(lambda_function)

xray_recorder.begin_segment('test_init')
function = __import__('lambda_function')
handler = function.lambda_handler
xray_recorder.end_segment()

class TestFunction(unittest.TestCase):

  def test_function(self):
    xray_recorder.begin_segment('test_function')
    file = open('event.json', 'rb')
    try:
      ba = bytearray(file.read())
      event = jsonpickle.decode(ba)
      logger.warning('## EVENT')
      logger.warning(jsonpickle.encode(event))
      context = {'requestid' : '1234'}
      result = handler(event, context)
      print(str(result))
      self.assertRegex(str(result), 'FunctionCount', 'Should match')
    finally:
      file.close()
    file.close()
    xray_recorder.end_segment()

if __name__ == '__main__':
    unittest.main()


#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name blank-python --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name blank-python --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
set -eo pipefail
python3 function/lambda_function.test.py



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      Handler: lambda_function.lambda_handler
      Runtime: python3.11
      CodeUri: function/.
      Description: Call the AWS Lambda API
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
      Tracing: Active
      Layers:
        - !Ref libs
  libs:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: blank-python-lib
      Description: Dependencies for the blank-python sample app.
      ContentUri: package/.
      CompatibleRuntimes:
        - python3.11


{
  "Records": [
    {
      "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
      "receiptHandle": "MessageReceiptHandle",
      "body": "Hello from SQS!",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
      "awsRegion": "us-west-2"
    }
  ]
}



#!/bin/bash
set -eo pipefail
rm -rf package
cd function
pip3 install --target ../package/python -r requirements.txt



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "lambda.amazonaws.com"
                ]
            }
        }
    ]
}


# Blank function with layer (C#)

![Architecture](/sample-apps/blank-csharp/images/sample-blank-csharp.png)

The project source includes function code and supporting resources:

- `src/blank-csharp` - A C# .NET Core function.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application. For more information on the application's architecture and implementation, see [Managing Spot Instance Requests](https://docs.aws.amazon.com/lambda/latest/dg/services-ec2-tutorial.html) in the developer guide.

# Requirements
- [.NET Core SDK 8.0](https://dotnet.microsoft.com/download/dotnet-core/8.0)
- [AWS extensions for .NET CLI](https://github.com/aws/aws-extensions-for-dotnet-cli). Specifically, ensure that you have [Amazon.Lambda.Tools](https://github.com/aws/aws-extensions-for-dotnet-cli#aws-lambda-amazonlambdatools) installed.
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/blank-csharp

To create a new bucket for deployment artifacts, run `1-create-bucket-and-role.sh`.

    blank-csharp$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-d7aec9f2022ef2b4
    make_bucket: lambda-artifacts-d7aec9f2022ef2b4-dotnet-layer
    {
        "Role": {
            "Path": "/",
            "RoleName": "blank-csharp-role",
            "RoleId": "AROA6HOIFXAKKWARP5RSC",
            "Arn": "arn:aws:iam::978061735956:role/blank-csharp-role",
            "CreateDate": "2023-08-22T18:12:29+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "sts:AssumeRole"
                        ],
                        "Principal": {
                            "Service": [
                                "lambda.amazonaws.com"
                            ]
                        }
                    }
                ]
            }
        }
    }

To build a Lambda layer that contains the function's runtime dependencies, run `2-build-layer.sh`. This also uploads the layer to an S3 bucket created by the first script.

    blank-csharp$ ./2-build-layer.sh

# Deploy
To deploy the application, run `3-deploy.sh`.

    blank-csharp$ ./3-deploy.sh
    Amazon Lambda Tools for .NET Core applications (5.8.0)
    ...
    Created publish archive ...
    Creating new Lambda function blank-csharp
    New Lambda function created

This script uses the .NET Amazon Lambda Tools to deploy the Lambda function. It uses the default settings from the `src/aws-lambda-tools-defaults.json` file.

To invoke the function, run `4-invoke.sh`.

    blank-csharp$ ./4-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    {"FunctionCount":13,"TotalCodeSize":598094248}

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map. The following service map shows the function managing spot instances in Amazon EC2.

![Service Map](/sample-apps/blank-csharp-with-layer/images/blank-csharp-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/blank-csharp-with-layer/images/blank-csharp-trace.png)

# Cleanup
To delete the application, run the cleanup script.

    blank-csharp$ ./5-cleanup.sh


using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amazon;
using Amazon.Util;
using Amazon.Lambda;
using Amazon.Lambda.Model;
using Amazon.Lambda.Core;
using Amazon.Lambda.SQSEvents;
using Amazon.XRay.Recorder.Core;
using Amazon.XRay.Recorder.Handlers.AwsSdk;
using System.IO;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.Json.JsonSerializer))]

namespace blankCsharp
{
  public class Function
  {
        private AmazonLambdaClient lambdaClient;

        public Function()
        {
            initialize();
        }

        async void initialize()
        {
            AWSSDKHandler.RegisterXRayForAllServices();
            lambdaClient = new AmazonLambdaClient();
            await callLambda();
        }

        public async Task<AccountUsage> FunctionHandler(SQSEvent invocationEvent, ILambdaContext context)
        {
            GetAccountSettingsResponse accountSettings;
            try
            {
                accountSettings = await callLambda();
            }
            catch (AmazonLambdaException ex)
            {
                throw ex;
            }

            AccountUsage accountUsage = accountSettings.AccountUsage;
            MemoryStream logData = new MemoryStream();
            StreamReader logDataReader = new StreamReader(logData);

            Amazon.Lambda.Serialization.Json.JsonSerializer serializer = new Amazon.Lambda.Serialization.Json.JsonSerializer();

            serializer.Serialize<System.Collections.IDictionary>(System.Environment.GetEnvironmentVariables(), logData);
            LambdaLogger.Log("ENVIRONMENT VARIABLES: " + logDataReader.ReadLine());
            logData.Position = 0;
            serializer.Serialize<ILambdaContext>(context, logData);
            LambdaLogger.Log("CONTEXT: " + logDataReader.ReadLine());
            logData.Position = 0;
            serializer.Serialize<SQSEvent>(invocationEvent, logData);
            LambdaLogger.Log("EVENT: " + logDataReader.ReadLine());

            return accountUsage;
        }

        public async Task<GetAccountSettingsResponse> callLambda()
        {
            var request = new GetAccountSettingsRequest();
            var response = await lambdaClient.GetAccountSettingsAsync(request);
            return response;
        }
  }
}



<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
    <AWSProjectType>Lambda</AWSProjectType>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="2.1.0" />
    <PackageReference Include="Amazon.Lambda.SQSEvents" Version="2.1.0" />
    <PackageReference Include="Amazon.Lambda.Serialization.Json" Version="2.1.0" />
    <PackageReference Include="AWSSDK.Core" Version="3.7.103.24" />
    <PackageReference Include="AWSSDK.Lambda" Version="3.7.104.3" />
    <PackageReference Include="AWSXRayRecorder.Core" Version="2.13.0" />
    <PackageReference Include="AWSXRayRecorder.Handlers.AwsSdk" Version="2.11.0" />
  </ItemGroup>
</Project>


{
  "Information" : [
    "This file provides default values for the deployment wizard inside Visual Studio and the AWS Lambda commands added to the .NET Core CLI.",
    "To learn more about the Lambda commands with the .NET Core CLI execute the following command at the command line in the project root directory.",

    "dotnet lambda help",

    "All the command line options for the Lambda command can be specified in this file."
  ],

  "profile":"default",
  "region" : "us-east-1",
  "configuration" : "Release",
  "framework" : "net8.0",
  "function-runtime":"dotnet8",
  "function-memory-size" : 512,
  "function-timeout" : 30,
  "function-handler" : "blank-csharp::blankCsharp.Function::FunctionHandler",
  "function-role" : "blank-csharp-role"
}



#!/bin/bash
set -eo pipefail
echo "Deleting function blank-csharp"
aws iam detach-role-policy --role-name blank-csharp-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam detach-role-policy --role-name blank-csharp-role --policy-arn arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess
aws iam detach-role-policy --role-name blank-csharp-role --policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess
aws iam delete-role --role-name blank-csharp-role
aws lambda delete-function --function-name blank-csharp

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
    LAYER_BUCKET=$(cat bucket-name.txt)-dotnet-layer
    if [[ ! $LAYER_BUCKET =~ lambda-artifacts-[a-z0-9]{16}-dotnet-layer ]] ; then
        echo "Layer bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($LAYER_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$LAYER_BUCKET; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi
rm bucket-name.txt

while true; do
    read -p "Delete function log group (/aws/lambda/blank-csharp)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/blank-csharp; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json layer-arn.txt
rm -rf src/blank-csharp/bin src/blank-csharp/obj


#!/bin/bash
set -eo pipefail
if [[ $(aws --version) =~ "aws-cli/2." ]]; then PAYLOAD_PROTOCOL="fileb"; else  PAYLOAD_PROTOCOL="file"; fi;
while true; do
  aws lambda invoke --function-name blank-csharp --payload $PAYLOAD_PROTOCOL://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
LAYER_ARN=$(cat layer-arn.txt)
cd src/blank-csharp
dotnet lambda deploy-function blank-csharp --function-layers $LAYER_ARN
cd ../../



{
  "Records": [
    {
      "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
      "receiptHandle": "MessageReceiptHandle",
      "body": "Hello from SQS!",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
      "awsRegion": "us-west-2"
    }
  ]
}



using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using Amazon.XRay.Recorder.Core;
using Amazon.XRay.Recorder.Core.Internal.Entities;
using Amazon.XRay.Recorder.Core.Exceptions;
using Amazon.XRay.Recorder.Core.Sampling;
using Amazon.XRay.Recorder.Core.Internal.Context;
using Amazon.XRay.Recorder.Core.Internal.Utils;

using Xunit;
using Amazon.Lambda.Core;
using Amazon.Lambda.SQSEvents;
using Amazon.Lambda.TestUtilities;

using blankCsharp;

namespace blankCsharp.Tests
{
    public class TraceFixture : IDisposable
    {
        private static readonly String _traceHeaderValue = "Root=" + "1-5d66d2fe-8e6fcab805a0833803735bc8" + ";Parent=53995c3f42cd8ad8;Sampled=1";

        public TraceFixture()
        {
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTaskRootKey, "test");
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTraceHeaderKey, _traceHeaderValue);
            Environment.SetEnvironmentVariable("AWS_REGION", "us-east-2");
        }

        public void Dispose()
        {
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTaskRootKey, null);
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTraceHeaderKey, null);
            Environment.SetEnvironmentVariable("AWS_REGION", null);
        }
    }

    public class FunctionTest : IClassFixture<TraceFixture>
    {
        TraceFixture fixture;

        [Fact]
        public void TestFunction()
        {
            var function = new Function();
            var context = new TestLambdaContext();
            SQSEvent input = new SQSEvent();
            var task = function.FunctionHandler(input, context);
            task.Wait(7000);
            bool completed = task.IsCompleted;
            Assert.True(completed);
        }
    }
}



<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netcoreapp2.1</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="1.1.0" />
    <PackageReference Include="Amazon.Lambda.TestUtilities" Version="1.1.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="15.5.0" />
    <PackageReference Include="xunit" Version="2.3.1" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.3.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\blank-csharp\blank-csharp.csproj" />
  </ItemGroup>
</Project>


#!/bin/bash
LAYER_BUCKET_NAME=$(cat bucket-name.txt)-dotnet-layer
cd src/blank-csharp
LAYER_ARN=$(dotnet lambda publish-layer blank-csharp-layer --layer-type runtime-package-store --s3-bucket "$LAYER_BUCKET_NAME" | tail -1 | cut -c 23-)
cd ../..
echo $LAYER_ARN > layer-arn.txt



#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
LAYER_BUCKET_NAME=$BUCKET_NAME-dotnet-layer
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME
aws s3 mb s3://$LAYER_BUCKET_NAME

aws iam create-role --role-name blank-csharp-role --assume-role-policy-document fileb://assume-policy.json
aws iam attach-role-policy --role-name blank-csharp-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam attach-role-policy --role-name blank-csharp-role --policy-arn arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess
aws iam attach-role-policy --role-name blank-csharp-role --policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
TEMPLATE=template.yml
if [ $1 ]
then
  if [ $1 = mvn ]
  then
    TEMPLATE=template-mvn.yml
    mvn package
  fi
else
  gradle build -i
fi
aws cloudformation package --template-file $TEMPLATE --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name java-events --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# Basic function with event library types (Java)

This sample application shows the use of the `aws-lambda-java-events` library with various event types. To keep the deployment size minimal, it includes only types that can be used without adding the AWS SDK as a dependency. A separate handler class is defined for each input type.

**Note: To use these examples, you must be using version 3.0.0 or newer of the `aws-lambda-java-events` dependency.** If you are on an older version, see the [`java-events-v1sdk` package](https://github.com/awsdocs/aws-lambda-developer-guide/tree/main/sample-apps/java-events-v1sdk) for deprecated examples. If possible, update your `aws-lambda-java-events` dependency to version 3.0.0 or newer.

![Architecture](/sample-apps/java-events/images/sample-java-events.png)

The project includes function code and supporting resources:
- `src/main` - A Java function.
- `src/test` - A unit test and helper classes.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `build.gradle` - A Gradle build file.
- `pom.xml` - A Maven build file.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- [Java 8 runtime environment (SE JRE)](https://www.oracle.com/java/technologies/javase-downloads.html)
- [Gradle 5](https://gradle.org/releases/) or [Maven 3](https://maven.apache.org/docs/history.html)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/java-events

Run `1-create-bucket.sh` to create a new bucket for deployment artifacts.

    java-events$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e4xmplb5b22e0d

# Deploy
Run `2-deploy.sh` to build the application with Gradle and deploy it.

    java-events$ ./2-deploy.sh
    BUILD SUCCESSFUL in 1s
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Successfully created/updated stack - java-events

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

You can also build the application with Maven. To use maven, add `mvn` to the command.

    java-events$ ./2-deploy.sh mvn
    [INFO] Scanning for projects...
    [INFO] -----------------------< com.example:java-events >-----------------------
    [INFO] Building java-events-function 1.0-SNAPSHOT
    [INFO] --------------------------------[ jar ]---------------------------------
    ...

# Test
Run `3-invoke.sh` to invoke the function. The default handler (`Handler.java`) processes an event from an Amazon API Gateway HTTP API and returns a JSON representation of an HTTP response.

    java-events$ ./3-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    {"isBase64Encoded":false,"statusCode":200,"headers":{"Content-Type":"text/html"},"body":"<!DOCTYPE html><html><head><title>AWS Lambda sample</title></head><body><h1>Welcome</h1><p>Page generated by a Lambda function.</p></body></html>"}

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map.

![Service Map](/sample-apps/java-events/images/java-events-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/java-events/images/java-events-trace.png)

# Configure Handler Class

By default, the function uses a handler class named `Handler` that takes an API Gateway proxy event as input and returns a string. The project also includes handlers that use other input and output types. The handlers are defined in the following files under `src/main/java/example`:

- `Handler.java` - Takes `APIGatewayV2ProxyRequestEvent` as input and returns `APIGatewayV2ProxyResponseEvent`.
- `HandlerApiGateway.java` - Takes `APIGatewayProxyRequestEvent` as input and returns `APIGatewayProxyResponseEvent`.
- `HandlerCloudFront.java` - Takes `CloudFrontEvent` as input.
- `HandlerCodeCommit.java` - Takes `CodeCommitEvent` as input.
- `HandlerCognito.java` - Takes `CognitoEvent` as input.
- `HandlerCWEvents.java` - Takes `ScheduledEventEvent` as input.
- `HandlerCWLogs.java` - Takes `CloudWatchLogsEvent` as input.
- `HandlerDynamoDB.java` - Takes `DynamodbEvent` as input.
- `HandlerFirehose.java` - Takes `KinesisFirehoseEvent` as input.
- `HandlerKinesis.java` - Takes `KinesisEvent` as input.
- `HandlerLex.java` - Takes `LexEvent` as input.
- `HandlerS3.java` - Takes `S3Event` as input.
- `HandlerSNS.java` - Takes `SNSEvent` as input.
- `HandlerSQS.java` - Takes `SQSEvent` as input.

To use a different handler, change the value of the Handler setting in the application template (`template.yml` or `template-mvn.yaml`). For example, to use the Amazon Lex handler:

    Properties:
      CodeUri: build/distributions/java-events.zip
      Handler: example.HandlerLex

Deploy the change, and then use the invoke script to test the new configuration. Pass the handler type key as an argument to the invoke script.

    ./3-invoke.sh lex
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    "200 OK"

The following event type keys are supported:
- none - API Gateway HTTP API (`events/apigateway-v2.json`)
- `apig` - API Gateway REST API (`events/apigateway-v1.json`)
- `cws` - CloudWatch scheduled event (`events/cloudwatch-scheduled.json`)
- `cwl` - CloudWatch Logs (`events/cloudwatch-logs.json`)
- `sns` - SNS notification (`events/sns-notification.json`)
- `cfg` - Config rule (`events/config-rule.json`)
- `cc` - CodeCommit push (`events/codecommit-push.json`)
- `cog` - Cognito Sync (`events/cognito-sync.json`)
- `kin` - Kinesis record (`events/kinesis-record.json`)
- `fh` - Kinesis Firehose record (`events/firehose-record.json`)
- `lex` - Lex dialog (`events/lex-flowers.json`)
- `ddb` - DynamoDB record (`events/dynamodb-record.json`)
- `s3` - S3Event record (`events/s3-notification.json`)
- `sqs` - SQSEvent record (`events/sqs-record.json`)

# Cleanup
To delete the application, run `4-cleanup.sh`.

    java-events$ ./4-cleanup.sh



package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;

import java.util.HashMap;

// Handler value: example.Handler
public class HandlerApiGatewayV1 implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent>{

  @Override
  public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent();
    response.setIsBase64Encoded(false);
    response.setStatusCode(200);
    HashMap<String, String> headers = new HashMap<String, String>();
    headers.put("Content-Type", "text/html");
    response.setHeaders(headers);
    String body = event.getBody() != null ? event.getBody() : "Empty body";
    response.setBody("<!DOCTYPE html><html><head><title>" + body + "</title></head><body>" +
      "<h1>Welcome</h1><p>Page generated by a Lambda function.</p>" +
      "</body></html>");
    return response;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;
import com.amazonaws.services.lambda.runtime.events.SNSEvent.SNS;
import com.amazonaws.services.lambda.runtime.events.SNSEvent.SNSRecord;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandlerSNS
public class HandlerSNS implements RequestHandler<SNSEvent, List<String>>{

  @Override
  public List<String> handleRequest(SNSEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var messagesFound = new ArrayList<String>();
    for (SNSRecord record : event.getRecords()) {
      SNS message = record.getSNS();
      messagesFound.add(message.getMessage());
    }
    return messagesFound;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.ConfigEvent;

// Handler value: example.HandlerConfig
public class HandlerConfig implements RequestHandler<ConfigEvent, String>{

  @Override
  public String handleRequest(ConfigEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    return event.getConfigRuleArn();
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.CloudFrontEvent;
import com.amazonaws.services.lambda.runtime.events.CloudFrontEvent.CF;
import com.amazonaws.services.lambda.runtime.events.CloudFrontEvent.Record;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandlerCloudFront
public class HandlerCloudFront implements RequestHandler<CloudFrontEvent, List<String>>{

  @Override
  public List<String> handleRequest(CloudFrontEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var urisFound = new ArrayList<String>();
    for (Record record : event.getRecords()) {
      CF cfBody = record.getCf();
      urisFound.add(cfBody.getRequest().getUri());
    }
    return urisFound;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.LexEvent;

// Handler value: example.HandlerLex
public class HandlerLex implements RequestHandler<LexEvent, String>{

  @Override
  public String handleRequest(LexEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    return event.getCurrentIntent().getName();
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent.KinesisEventRecord;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandleKinesis
public class HandlerKinesis implements RequestHandler<KinesisEvent, List<String>>{

  Gson gson = new GsonBuilder().setPrettyPrinting().create();

  @Override
  public List<String> handleRequest(KinesisEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var dataRecords = new ArrayList<String>();
    for(KinesisEventRecord record : event.getRecords()) {
      dataRecords.add(gson.toJson(record.getKinesis().getData()));
    }
    return dataRecords;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.CloudWatchLogsEvent;

import java.util.Base64;
import java.util.Base64.Decoder;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.zip.GZIPInputStream;

// Handler value: example.HandlerCWLogs
public class HandlerCWLogs implements RequestHandler<CloudWatchLogsEvent, String>{

  @Override
  public String handleRequest(CloudWatchLogsEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    Decoder decoder = Base64.getDecoder();
    byte[] decodedEvent = decoder.decode(event.getAwsLogs().getData());
    StringBuilder output = new StringBuilder();
    try {
      GZIPInputStream inputStream = new GZIPInputStream(new ByteArrayInputStream(decodedEvent));
      InputStreamReader inputStreamReader = new InputStreamReader(inputStream, StandardCharsets.UTF_8);
      BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
      bufferedReader.lines().forEach( line -> {
        output.append(line);
      });
      // logger.info(output.toString());
    } catch(IOException e) {
        logger.log("ERROR: " + e.toString());
    }
    return output.toString();
  }
}



package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.DynamodbEvent;
import com.amazonaws.services.lambda.runtime.events.DynamodbEvent.DynamodbStreamRecord;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandlerDynamoDB
public class HandlerDynamoDB implements RequestHandler<DynamodbEvent, List<String>>{

  @Override
  public List<String> handleRequest(DynamodbEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var operationsFound = new ArrayList<String>();
    for (DynamodbStreamRecord record : event.getRecords()) {
      operationsFound.add(record.getEventName());
    }
    return operationsFound;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.CognitoEvent;
import com.amazonaws.services.lambda.runtime.events.CognitoEvent.DatasetRecord;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandlerCognito
public class HandlerCognito implements RequestHandler<CognitoEvent, List<String>>{

  @Override
  public List<String> handleRequest(CognitoEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var operationsFound = new ArrayList<String>();
    for (DatasetRecord record : event.getDatasetRecords().values()) {
      operationsFound.add(record.getOp());
    }
    return operationsFound;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;

import java.util.HashMap;

// Handler value: example.HandlerApiGateway
public class HandlerApiGatewayV2 implements RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse>{

  @Override
  public APIGatewayV2HTTPResponse handleRequest(APIGatewayV2HTTPEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    APIGatewayV2HTTPResponse response = new APIGatewayV2HTTPResponse();
    response.setIsBase64Encoded(false);
    response.setStatusCode(200);
    HashMap<String, String> headers = new HashMap<String, String>();
    headers.put("Content-Type", "text/html");
    response.setHeaders(headers);
    String body = event.getBody() != null ? event.getBody() : "Empty body";
    response.setBody("<!DOCTYPE html><html><head><title>" + body + "</title></head><body>" +
      "<h1>Welcome</h1><p>Page generated by a Lambda function.</p>" +
      "</body></html>");
    return response;
  }
}



package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.ScheduledEvent;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandlerCWEvents
public class HandlerCWEvents implements RequestHandler<ScheduledEvent, List<String>>{

  @Override
  public List<String> handleRequest(ScheduledEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var resourcesFound = new ArrayList<String>();
    for (String resource : event.getResources()) {
      resourcesFound.add(resource);
    }
    return resourcesFound;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.S3EventNotificationRecord;

// Handler value: example.Handler
public class HandlerS3 implements RequestHandler<S3Event, String>{
    
    @Override
    public String handleRequest(S3Event event, Context context)
    {
        LambdaLogger logger = context.getLogger();
        S3EventNotificationRecord record = event.getRecords().get(0);
        String srcBucket = record.getS3().getBucket().getName();
        // Object key may have spaces or unicode non-ASCII characters.
        String srcKey = record.getS3().getObject().getUrlDecodedKey();
        logger.log("RECORD: " + record);
        logger.log("SOURCE BUCKET: " + srcBucket);
        logger.log("SOURCE KEY: " + srcKey);
        // log execution details
        return srcBucket + "/" + srcKey;
    }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.CodeCommitEvent;
import com.amazonaws.services.lambda.runtime.events.CodeCommitEvent.CodeCommit;
import com.amazonaws.services.lambda.runtime.events.CodeCommitEvent.Record;
import com.amazonaws.services.lambda.runtime.events.CodeCommitEvent.Reference;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandlerCodeCommit
public class HandlerCodeCommit implements RequestHandler<CodeCommitEvent, List<String>>{

  @Override
  public List<String> handleRequest(CodeCommitEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var commitsFound = new ArrayList<String>();
    for (Record record : event.getRecords()) {
      CodeCommit commit = record.getCodeCommit();
      for (Reference reference : commit.getReferences()) {
        commitsFound.add(reference.getCommit());
      }
    }
    return commitsFound;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.amazonaws.services.lambda.runtime.events.SQSEvent.SQSMessage;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandlerSQS
public class HandlerSQS implements RequestHandler<SQSEvent, List<String>>{

  @Override
  public List<String> handleRequest(SQSEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var messagesFound = new ArrayList<String>();
    for(SQSMessage msg : event.getRecords()){
      messagesFound.add(msg.getBody());
    }
    return messagesFound;
  }
}



package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.KinesisFirehoseEvent;
import com.amazonaws.services.lambda.runtime.events.KinesisFirehoseEvent.Record;

import java.util.ArrayList;
import java.util.List;

// Handler value: example.HandlerFirehose
public class HandlerFirehose implements RequestHandler<KinesisFirehoseEvent, List<String>>{

  @Override
  public List<String> handleRequest(KinesisFirehoseEvent event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    var recordIds = new ArrayList<String>();
    for (Record record : event.getRecords()) {
      recordIds.add(record.getRecordId());
    }
    return recordIds;
  }
}


<Configuration status="WARN">
  <Appenders>
    <Console name="ConsoleAppender" target="SYSTEM_OUT">
      <PatternLayout pattern="%d{YYYY-MM-dd HH:mm:ss} [%t] %-5p %c:%L - %m%n" />
    </Console>
  </Appenders>
  <Loggers>
    <Root level="INFO">
      <AppenderRef ref="ConsoleAppender"/>
    </Root>
  </Loggers>
</Configuration>


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.CognitoIdentity;
import com.amazonaws.services.lambda.runtime.ClientContext;
import com.amazonaws.services.lambda.runtime.LambdaLogger;

public class TestContext implements Context{

  public TestContext() {}
  public String getAwsRequestId(){
    return new String("495b12a8-xmpl-4eca-8168-160484189f99");
  }
  public String getLogGroupName(){
    return new String("/aws/lambda/my-function");
  }
  public String getLogStreamName(){
    return new String("2020/02/26/[$LATEST]704f8dxmpla04097b9134246b8438f1a");
  }
  public String getFunctionName(){
    return new String("my-function");
  }
  public String getFunctionVersion(){
    return new String("$LATEST");
  }
  public String getInvokedFunctionArn(){
    return new String("arn:aws:lambda:us-east-2:123456789012:function:my-function");
  }
  public CognitoIdentity getIdentity(){
    return null;
  }
  public ClientContext getClientContext(){
    return null;
  }
  public int getRemainingTimeInMillis(){
    return 300000;
  }
  public int getMemoryLimitInMB(){
    return 512;
  }
  public LambdaLogger getLogger(){
    return new TestLogger();
  }

}


package example;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.amazonaws.services.lambda.runtime.LambdaLogger;

public class TestLogger implements LambdaLogger {
  private static final Logger logger = LoggerFactory.getLogger(TestLogger.class);
  public void log(String message){
    logger.info(message);
  }
  public void log(byte[] message){
    logger.info(new String(message));
  }
}



package example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import com.amazonaws.services.lambda.runtime.events.CloudFrontEvent;
import com.amazonaws.services.lambda.runtime.events.CloudWatchLogsEvent;
import com.amazonaws.services.lambda.runtime.events.CodeCommitEvent;
import com.amazonaws.services.lambda.runtime.events.CognitoEvent;
import com.amazonaws.services.lambda.runtime.events.ConfigEvent;
import com.amazonaws.services.lambda.runtime.events.DynamodbEvent;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent;
import com.amazonaws.services.lambda.runtime.events.KinesisFirehoseEvent;
import com.amazonaws.services.lambda.runtime.events.LexEvent;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.amazonaws.services.lambda.runtime.events.ScheduledEvent;
import com.amazonaws.services.lambda.runtime.tests.annotations.Event;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.List;

import org.junit.jupiter.params.ParameterizedTest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

class InvokeTest {

  private static final Logger logger = LoggerFactory.getLogger(InvokeTest.class);
  Gson gson = new GsonBuilder().setPrettyPrinting().create();

  @ParameterizedTest
  @Event(value = "events/apigateway-v1.json", type = APIGatewayProxyRequestEvent.class)
  void testApiGatewayV1(APIGatewayProxyRequestEvent event) {
    logger.info("Invoke TEST - ApiGatewayV1");
    Context context = new TestContext();
    HandlerApiGatewayV1 handler = new HandlerApiGatewayV1();
    APIGatewayProxyResponseEvent response = handler.handleRequest(event, context);
    String expected = "<!DOCTYPE html><html><head><title>" + "Hello world!" + "</title></head><body>" +
      "<h1>Welcome</h1><p>Page generated by a Lambda function.</p>" +
      "</body></html>";
    assertEquals(expected, response.getBody());
  }

  @ParameterizedTest
  @Event(value = "events/apigateway-v2.json", type = APIGatewayV2HTTPEvent.class)
  void testApiGatewayV2(APIGatewayV2HTTPEvent event) {
    logger.info("Invoke TEST - ApiGatewayV1");
    Context context = new TestContext();
    HandlerApiGatewayV2 handler = new HandlerApiGatewayV2();
    APIGatewayV2HTTPResponse response = handler.handleRequest(event, context);
    String expected = "<!DOCTYPE html><html><head><title>" + "Hello world!" + "</title></head><body>" +
      "<h1>Welcome</h1><p>Page generated by a Lambda function.</p>" +
      "</body></html>";
    assertEquals(expected, response.getBody());
  }

  @ParameterizedTest
  @Event(value = "events/cloudfront.json", type = CloudFrontEvent.class)
  void testCloudFront(CloudFrontEvent event) {
    logger.info("Invoke TEST - CloudFront");
    Context context = new TestContext();
    HandlerCloudFront handler = new HandlerCloudFront();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(1, response.size());
    assertEquals("/picture.jpg", response.get(0));
  }

  @ParameterizedTest
  @Event(value = "events/codecommit-push.json", type = CodeCommitEvent.class)
  void testCodeCommit(CodeCommitEvent event) {
    logger.info("Invoke TEST - CodeCommit");
    Context context = new TestContext();
    HandlerCodeCommit handler = new HandlerCodeCommit();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(1, response.size());
    assertEquals("5c4ef1049f1d27deadbeeff313e0730018be182b", response.get(0));
  }

  @ParameterizedTest
  @Event(value = "events/cognito-sync.json", type = CognitoEvent.class)
  void testCognito(CognitoEvent event) {
    logger.info("Invoke TEST - Cognito");
    Context context = new TestContext();
    HandlerCognito handler = new HandlerCognito();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(2, response.size());
    assertEquals("replace", response.get(0));
    assertEquals("replace", response.get(1));
  }

  @ParameterizedTest
  @Event(value = "events/config-rule.json", type = ConfigEvent.class)
  void testConfig(ConfigEvent event) {
    logger.info("Invoke TEST - Config");
    Context context = new TestContext();
    HandlerConfig handler = new HandlerConfig();
    String response = handler.handleRequest(event, context);
    assertEquals("arn:aws:config:ca-central-1:123456789012:config-rule/config-rule-0123456", response);
  }

  @ParameterizedTest
  @Event(value = "events/cloudwatch-scheduled.json", type = ScheduledEvent.class)
  void testCWEvents(ScheduledEvent event) {
    logger.info("Invoke TEST - CWEvents");
    Context context = new TestContext();
    HandlerCWEvents handler = new HandlerCWEvents();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(1, response.size());
    assertEquals("arn:aws:events:us-east-2:123456789012:rule/my-rule", response.get(0));
  }

  @ParameterizedTest
  @Event(value = "events/cloudwatch-logs.json", type = CloudWatchLogsEvent.class)
  void testCWLogs(CloudWatchLogsEvent event) {
    logger.info("Invoke TEST - CWLogs");
    Context context = new TestContext();
    HandlerCWLogs handler = new HandlerCWLogs();
    String response = handler.handleRequest(event, context);
    assertNotNull(response);
  }

  @ParameterizedTest
  @Event(value = "events/dynamodb-record.json", type = DynamodbEvent.class)
  void testDynamoDB(DynamodbEvent event) {
    logger.info("Invoke TEST - DynamoDB");
    Context context = new TestContext();
    HandlerDynamoDB handler = new HandlerDynamoDB();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(2, response.size());
    assertEquals("INSERT", response.get(0));
    assertEquals("MODIFY", response.get(1));
  }

  @ParameterizedTest
  @Event(value = "events/firehose-record.json", type = KinesisFirehoseEvent.class)
  void testFirehose(KinesisFirehoseEvent event) {
    logger.info("Invoke TEST - Firehose");
    Context context = new TestContext();
    HandlerFirehose handler = new HandlerFirehose();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(1, response.size());
    assertEquals("49546986683135544286507457936321625675700192471156785154", response.get(0));
  }

  @ParameterizedTest
  @Event(value = "events/kinesis-record.json", type = KinesisEvent.class)
  void testKinesis(KinesisEvent event) {
    logger.info("Invoke TEST - Kinesis");
    Context context = new TestContext();
    HandlerKinesis handler = new HandlerKinesis();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(2, response.size());
  }

  @ParameterizedTest
  @Event(value = "events/lex-flowers.json", type = LexEvent.class)
  void testLex(LexEvent event) {
    logger.info("Invoke TEST - Lex");
    Context context = new TestContext();
    HandlerLex handler = new HandlerLex();
    String response = handler.handleRequest(event, context);
    assertEquals("OrderFlowers", response);
  }

  @ParameterizedTest
  @Event(value = "events/s3-notification.json", type = S3Event.class)
  void testS3(S3Event event) {
    logger.info("Invoke TEST - S3");
    Context context = new TestContext();
    HandlerS3 handler = new HandlerS3();
    String response = handler.handleRequest(event, context);
    assertEquals("BUCKET_NAME/inbound/sample-java-s3.png", response);
  }

  @ParameterizedTest
  @Event(value = "events/sns-notification.json", type = SNSEvent.class)
  void testSNS(SNSEvent event) {
    logger.info("Invoke TEST - SNS");
    Context context = new TestContext();
    HandlerSNS handler = new HandlerSNS();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(1, response.size());
    assertEquals("Updated and expanded documentation for using Lambda with API Gateway, including support for HTTP APIs.", response.get(0));
  }

  @ParameterizedTest
  @Event(value = "events/sqs-record.json", type = SQSEvent.class)
  void testSQS(SQSEvent event) {
    logger.info("Invoke TEST - SQS");
    Context context = new TestContext();
    HandlerSQS handler = new HandlerSQS();
    List<String> response = handler.handleRequest(event, context);
    assertEquals(1, response.size());
    assertEquals("Hello from SQS!", response.get(0));
  }
}



plugins {
    id 'java'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'com.amazonaws:aws-lambda-java-core:1.2.1'
    implementation 'com.amazonaws:aws-lambda-java-events:3.11.0'
    implementation 'com.google.code.gson:gson:2.8.9'
    implementation 'org.slf4j:slf4j-nop:2.0.6'
    testImplementation 'com.amazonaws:aws-lambda-java-tests:1.1.1'
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.2'
    testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.2'
}

test {
    useJUnitPlatform()
}

task buildZip(type: Zip) {
    from compileJava
    from processResources
    into('lib') {
        from configurations.runtimeClasspath
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

build.dependsOn buildZip



#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name java-events --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
if [ $1 ]
then
  case $1 in
    apig)
      PAYLOAD='fileb://events/apigateway-v1.json'
      ;;
    cws)
      PAYLOAD='fileb://events/cloudwatch-scheduled.json'
      ;;
    cwl)
      PAYLOAD='fileb://events/cloudwatch-logs.json'
      ;;
    sns)
      PAYLOAD='fileb://events/sns-notification.json'
      ;;
    cdn)
      PAYLOAD='fileb://events/cloudfront.json'
      ;;
    cfg)
      PAYLOAD='fileb://events/config-rule.json'
      ;;
    cc)
      PAYLOAD='fileb://events/codecommit-push.json'
      ;;
    cog)
      PAYLOAD='fileb://events/cognito-sync.json'
      ;;
    kin)
      PAYLOAD='fileb://events/kinesis-record.json'
      ;;
    fh)
      PAYLOAD='fileb://events/firehose-record.json'
      ;;
    lex)
      PAYLOAD='fileb://events/lex-flowers.json'
      ;;
    ddb)
      PAYLOAD='fileb://events/dynamodb-record.json'
      ;;
    s3)
      PAYLOAD='fileb://events/s3-notification.json'
      ;;
    sqs)
      PAYLOAD='fileb://events/sqs-record.json'
      ;;
    *)
      echo -n "Unknown event type"
      ;;
  esac
fi
while true; do
  if [ $PAYLOAD ]
  then
    aws lambda invoke --function-name $FUNCTION --payload $PAYLOAD out.json
  else
    aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  fi
  cat out.json
  echo ""
  sleep 2
done



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: build/distributions/java-events.zip
      Handler: example.HandlerSQS
      Runtime: java11
      Description: Java function
      MemorySize: 2048
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
        - AWSLambdaVPCAccessExecutionRole
      Tracing: Active



<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>java-events</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>java-events-function</name>
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
  </properties>
  <dependencies>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-core</artifactId>
      <version>1.2.1</version>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-events</artifactId>
      <version>3.11.0</version>
    </dependency>
    <dependency>
      <groupId>com.google.code.gson</groupId>
      <artifactId>gson</artifactId>
      <version>2.8.9</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-nop</artifactId>
      <version>2.0.6</version>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>5.8.2</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>5.8.2</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-tests</artifactId>
      <version>1.1.1</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.2</version>
        <configuration>
          <createDependencyReducedPom>false</createDependencyReducedPom>
          <filters>
            <filter>
                <artifact>*:*</artifact>
                <excludes>
                    <exclude>module-info.class</exclude>
                    <exclude>META-INF/*</exclude>
                    <exclude>META-INF/versions/**</exclude>
                </excludes>
            </filter>
        </filters>
        </configuration>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.8.1</version>
        <configuration>
           <source>11</source>
           <target>11</target>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>


{
    "version": "2.0",
    "routeKey": "ANY /nodejs-apig-function-1G3XMPLZXVXYI",
    "rawPath": "/default/nodejs-apig-function-1G3XMPLZXVXYI",
    "rawQueryString": "",
    "cookies": [
        "s_fid=7AABXMPL1AFD9BBF-0643XMPL09956DE2",
        "regStatus=pre-register"
    ],
    "headers": {
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "accept-encoding": "gzip, deflate, br",
        "accept-language": "en-US,en;q=0.9",
        "content-length": "0",
        "host": "r3pmxmplak.execute-api.us-east-2.amazonaws.com",
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "cross-site",
        "sec-fetch-user": "?1",
        "upgrade-insecure-requests": "1",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
        "x-amzn-trace-id": "Root=1-5e6722a7-cc56xmpl46db7ae02d4da47e",
        "x-forwarded-for": "205.255.255.176",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https"
    },
    "requestContext": {
        "accountId": "123456789012",
        "apiId": "r3pmxmplak",
        "domainName": "r3pmxmplak.execute-api.us-east-2.amazonaws.com",
        "domainPrefix": "r3pmxmplak",
        "http": {
            "method": "GET",
            "path": "/default/nodejs-apig-function-1G3XMPLZXVXYI",
            "protocol": "HTTP/1.1",
            "sourceIp": "205.255.255.176",
            "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
        },
        "requestId": "JKJaXmPLvHcESHA=",
        "routeKey": "ANY /nodejs-apig-function-1G3XMPLZXVXYI",
        "stage": "default",
        "time": "10/Mar/2020:05:16:23 +0000",
        "timeEpoch": 1583817383220
    },
    "isBase64Encoded": true
}


AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: target/java-events-1.0-SNAPSHOT.jar
      Handler: example.HandlerSQS
      Runtime: java11
      Description: Java function
      MemorySize: 2048
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
        - AWSLambdaVPCAccessExecutionRole
      Tracing: Active



{
    "Records": [
      {
        "cf": {
          "config": {
            "distributionDomainName": "d111111abcdef8.cloudfront.net",
            "distributionId": "EDFDVBD6EXAMPLE",
            "eventType": "viewer-request",
            "requestId": "4TyzHTaYWb1GX1qTfsHhEqV6HUDd_BzoBZnwfnvQc_1oF26ClkoUSEQ=="
          },
          "request": {
            "clientIp": "203.0.113.178",
            "headers": {
              "host": [
                {
                  "key": "Host",
                  "value": "d111111abcdef8.cloudfront.net"
                }
              ],
              "user-agent": [
                {
                  "key": "User-Agent",
                  "value": "curl/7.66.0"
                }
              ],
              "accept": [
                {
                  "key": "accept",
                  "value": "*/*"
                }
              ]
            },
            "method": "GET",
            "querystring": "",
            "uri": "/picture.jpg"
          }
        }
      }
    ]
}


{
  "messageVersion": "1.0",
  "invocationSource": "DialogCodeHook",
  "userId": "John",
  "sessionAttributes": {},
  "bot": {
    "name": "OrderFlowers",
    "alias": "$LATEST",
    "version": "$LATEST"
  },
  "outputDialogMode": "Text",
  "currentIntent": {
    "name": "OrderFlowers",
    "slots": {
      "FlowerType": "lilies",
      "PickupDate": "2030-11-08",
      "PickupTime": "10:00"
    },
    "confirmationStatus": "None"
  }
}


{
    "Records": [
        {
            "Sns": {
                "MessageAttributes": {
                    "string-att": {
                        "Type": "String",
                        "Value": "[\"value\", \"value\"]"
                    },
                    "binary-att": {
                        "Type": "Binary",
                        "Value": "WyJ2YWx1ZSIsICJ2YWx1ZSJd"
                    }
                },
                "SigningCertUrl": "https://sns.us-east-2.amazonaws.com/SimpleNotificationService-a86cxmpl4e1f29c941702d737128f7b6.pem",
                "MessageId": "476643b1-xmpl-526c-973d-1542ba9af1d6",
                "Message": "Updated and expanded documentation for using Lambda with API Gateway, including support for HTTP APIs.",
                "Subject": "Latest updates from AWS Lambda",
                "UnsubscribeUrl": "https://sns.us-east-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-2:123456789012:java-events-topic:dd15418a-xmpl-4cfd-b418-f7fcb08c7ee4",
                "Type": "Notification",
                "SignatureVersion": "1",
                "Signature": "qZTBXMPL1MoX7HS+m/pg5lRzhJFdaTczB2KqZ6fUCMQGHMF7GhLLTxtC4Hkg2sUysGr14fpDSFRU7MBkzmQmRCXsV9odIHlrxAWvzUuCK2eUnVEoMWJWTH5uyZwWlQHllf9zt2f6eKtEu11yGUqCgzZPfTxg/yu3z/t0EKfdCwDmDL6XqzZbeFvk9uOC1ZIDVv/7cdnbjCslhyx7CTMDnJ7eSu8POgVNIgTItmGFXZDziG1LyV5Afw5fhwObAbypTkfmBSrFuEnDtlQUZvsUCqRJHvdm8g1MmcadSmS1YGBy3OI42oJAmNvfxgZ4/H+KPaXDuvqLNfaZa5qzyRULIg==",
                "Timestamp": "2020-02-02T12:34:56Z",
                "TopicArn": "arn:aws:sns:us-east-2:123456789012:java-events-topic"
            },
            "EventVersion": "1.0",
            "EventSource": "aws:sns",
            "EventSubscriptionArn": "arn:aws:sns:us-east-2:123456789012:java-events-topic:dd15418a-xmpl-4cfd-b418-f7fcb08c7ee4"
        }
    ]
}


{
    "version": "2.0",
    "routeKey": "ANY /nodejs-apig-function-1G3XMPLZXVXYI",
    "rawPath": "/default/nodejs-apig-function-1G3XMPLZXVXYI",
    "rawQueryString": "",
    "cookies": [
        "s_fid=7AABXMPL1AFD9BBF-0643XMPL09956DE2",
        "regStatus=pre-register"
    ],
    "headers": {
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "accept-encoding": "gzip, deflate, br",
        "accept-language": "en-US,en;q=0.9",
        "content-length": "0",
        "host": "r3pmxmplak.execute-api.us-east-2.amazonaws.com",
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "cross-site",
        "sec-fetch-user": "?1",
        "upgrade-insecure-requests": "1",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
        "x-amzn-trace-id": "Root=1-5e6722a7-cc56xmpl46db7ae02d4da47e",
        "x-forwarded-for": "205.255.255.176",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https"
    },
    "requestContext": {
        "accountId": "123456789012",
        "apiId": "r3pmxmplak",
        "domainName": "r3pmxmplak.execute-api.us-east-2.amazonaws.com",
        "domainPrefix": "r3pmxmplak",
        "http": {
            "method": "GET",
            "path": "/default/nodejs-apig-function-1G3XMPLZXVXYI",
            "protocol": "HTTP/1.1",
            "sourceIp": "205.255.255.176",
            "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
        },
        "requestId": "JKJaXmPLvHcESHA=",
        "routeKey": "ANY /nodejs-apig-function-1G3XMPLZXVXYI",
        "stage": "default",
        "time": "10/Mar/2020:05:16:23 +0000",
        "timeEpoch": 1583817383220
    },
    "body": "Hello world!",
    "isBase64Encoded": true
}


{
    "Records": [
        {
            "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
            "receiptHandle": "MessageReceiptHandle",
            "body": "Hello from SQS!",
            "attributes": {
                "ApproximateReceiveCount": "1",
                "SentTimestamp": "1523232000000",
                "SenderId": "123456789012",
                "ApproximateFirstReceiveTimestamp": "1523232000001"
            },
            "messageAttributes": {},
            "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
            "eventSource": "aws:sqs",
            "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
            "awsRegion": "us-west-2"
        }
    ]
}



{
    "account": "123456789012",
    "region": "us-east-2",
    "detail": {},
    "detailType": "Scheduled Event",
    "source": "aws.events",
    "id": "e1fdf1be-xmpl-1cbb-8102-667adfc78d5f",
    "time": "2020-02-02T12:34:56Z",
    "resources": [
        "arn:aws:events:us-east-2:123456789012:rule/my-rule"
    ]
}


{
  "Records": [
    {
      "eventID": "1",
      "eventVersion": "1.0",
      "dynamodb": {
        "Keys": {
          "Id": {
            "N": "101"
          }
        },
        "NewImage": {
          "Message": {
            "S": "New item!"
          },
          "Id": {
            "N": "101"
          }
        },
        "StreamViewType": "NEW_AND_OLD_IMAGES",
        "SequenceNumber": "111",
        "SizeBytes": 26
      },
      "awsRegion": "us-west-2",
      "eventName": "INSERT",
      "eventSourceARN": "eventsourcearn",
      "eventSource": "aws:dynamodb"
    },
    {
      "eventID": "2",
      "eventVersion": "1.0",
      "dynamodb": {
        "OldImage": {
          "Message": {
            "S": "New item!"
          },
          "Id": {
            "N": "101"
          }
        },
        "SequenceNumber": "222",
        "Keys": {
          "Id": {
            "N": "101"
          }
        },
        "SizeBytes": 59,
        "NewImage": {
          "Message": {
            "S": "This item has changed"
          },
          "Id": {
            "N": "101"
          }
        },
        "StreamViewType": "NEW_AND_OLD_IMAGES"
      },
      "awsRegion": "us-west-2",
      "eventName": "MODIFY",
      "eventSourceARN": "sourcearn",
      "eventSource": "aws:dynamodb"
    }
  ]
}


{
    "resource": "/",
    "path": "/",
    "httpMethod": "GET",
    "headers": {
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "accept-encoding": "gzip, deflate, br",
        "accept-language": "en-US,en;q=0.9",
        "cookie": "s_fid=7AAB6XMPLAFD9BBF-0643XMPL09956DE2; regStatus=pre-register",
        "Host": "70ixmpl4fl.execute-api.us-east-2.amazonaws.com",
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "none",
        "upgrade-insecure-requests": "1",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
        "X-Amzn-Trace-Id": "Root=1-5e66d96f-7491f09xmpl79d18acf3d050",
        "X-Forwarded-For": "52.255.255.12",
        "X-Forwarded-Port": "443",
        "X-Forwarded-Proto": "https"
    },
    "multiValueHeaders": {
        "accept": [
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
        ],
        "accept-encoding": [
            "gzip, deflate, br"
        ],
        "accept-language": [
            "en-US,en;q=0.9"
        ],
        "cookie": [
            "s_fid=7AABXMPL1AFD9BBF-0643XMPL09956DE2; regStatus=pre-register;"
        ],
        "Host": [
            "70ixmpl4fl.execute-api.ca-central-1.amazonaws.com"
        ],
        "sec-fetch-dest": [
            "document"
        ],
        "sec-fetch-mode": [
            "navigate"
        ],
        "sec-fetch-site": [
            "none"
        ],
        "upgrade-insecure-requests": [
            "1"
        ],
        "User-Agent": [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
        ],
        "X-Amzn-Trace-Id": [
            "Root=1-5e66d96f-7491f09xmpl79d18acf3d050"
        ],
        "X-Forwarded-For": [
            "52.255.255.12"
        ],
        "X-Forwarded-Port": [
            "443"
        ],
        "X-Forwarded-Proto": [
            "https"
        ]
    },
    "queryStringParameters": null,
    "multiValueQueryStringParameters": null,
    "pathParameters": null,
    "stageVariables": null,
    "requestContext": {
        "resourceId": "2gxmpl",
        "resourcePath": "/",
        "httpMethod": "GET",
        "extendedRequestId": "JJbxmplHYosFVYQ=",
        "requestTime": "10/Mar/2020:00:03:59 +0000",
        "path": "/Prod/",
        "accountId": "123456789012",
        "protocol": "HTTP/1.1",
        "stage": "Prod",
        "domainPrefix": "70ixmpl4fl",
        "requestTimeEpoch": 1583798639428,
        "requestId": "77375676-xmpl-4b79-853a-f982474efe18",
        "identity": {
            "cognitoIdentityPoolId": null,
            "accountId": null,
            "cognitoIdentityId": null,
            "caller": null,
            "sourceIp": "52.255.255.12",
            "principalOrgId": null,
            "accessKey": null,
            "cognitoAuthenticationType": null,
            "cognitoAuthenticationProvider": null,
            "userArn": null,
            "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36",
            "user": null
        },
        "domainName": "70ixmpl4fl.execute-api.us-east-2.amazonaws.com",
        "apiId": "70ixmpl4fl"
    },
    "body": "Hello world!",
    "isBase64Encoded": false
}


{
    "Records": [
        {
            "kinesis": {
                "kinesisSchemaVersion": "1.0",
                "partitionKey": "1",
                "sequenceNumber": "49590338271490256608559692538361571095921575989136588898",
                "data": "SGVsbG8sIHRoaXMgaXMgYSB0ZXN0Lg==",
                "approximateArrivalTimestamp": 1545084650.987
            },
            "eventSource": "aws:kinesis",
            "eventVersion": "1.0",
            "eventID": "shardId-000000000006:49590338271490256608559692538361571095921575989136588898",
            "eventName": "aws:kinesis:record",
            "invokeIdentityArn": "arn:aws:iam::123456789012:role/lambda-role",
            "awsRegion": "us-east-2",
            "eventSourceARN": "arn:aws:kinesis:us-east-2:123456789012:stream/lambda-stream"
        },
        {
            "kinesis": {
                "kinesisSchemaVersion": "1.0",
                "partitionKey": "1",
                "sequenceNumber": "49590338271490256608559692540925702759324208523137515618",
                "data": "VGhpcyBpcyBvbmx5IGEgdGVzdC4=",
                "approximateArrivalTimestamp": 1545084711.166
            },
            "eventSource": "aws:kinesis",
            "eventVersion": "1.0",
            "eventID": "shardId-000000000006:49590338271490256608559692540925702759324208523137515618",
            "eventName": "aws:kinesis:record",
            "invokeIdentityArn": "arn:aws:iam::123456789012:role/lambda-role",
            "awsRegion": "us-east-2",
            "eventSourceARN": "arn:aws:kinesis:us-east-2:123456789012:stream/lambda-stream"
        }
    ]
}


{
  "version": 2,
  "eventType": "SyncTrigger",
  "region": "ca-central-1",
  "identityPoolId": "identityPoolId",
  "identityId": "identityId",
  "datasetName": "datasetName",
  "datasetRecords": {
    "SampleKey1": {
      "oldValue": "oldValue1",
      "newValue": "newValue1",
      "op": "replace"
    },
    "SampleKey2": {
      "oldValue": "oldValue2",
      "newValue": "newValue2",
      "op": "replace"
    }
  }
}


{
  "awslogs": {
    "data": "H4sIAAAAAAAAAHWPwQqCQBCGX0Xm7EFtK+smZBEUgXoLCdMhFtKV3akI8d0bLYmibvPPN3wz00CJxmQnTO41whwWQRIctmEcB6sQbFC3CjW3XW8kxpOpP+OC22d1Wml1qZkQGtoMsScxaczKN3plG8zlaHIta5KqWsozoTYw3/djzwhpLwivWFGHGpAFe7DL68JlBUk+l7KSN7tCOEJ4M3/qOI49vMHj+zCKdlFqLaU2ZHV2a4Ct/an0/ivdX8oYc1UVX860fQDQiMdxRQEAAA=="
  }
}


{
    "Records": [
        {
            "awsRegion": "us-east-2",
            "eventName": "ObjectCreated:Put",
            "eventSource": "aws:s3",
            "eventTime": "2020-03-08T00:30:12.456Z",
            "eventVersion": "2.1",
            "requestParameters": {
                "sourceIPAddress": "174.255.255.156"
            },
            "responseElements": {
                "xAmzId2": "nBbLJPAHhdvxmplPvtCgTrWCqf/KtonyV93l9rcoMLeIWJxpS9x9P8u01+Tj0OdbAoGs+VGvEvWl/Sg1NW5uEsVO25Laq7L",
                "xAmzRequestId": "AF2D7AB6002E898D"
            },
            "s3": {
                "configurationId": "682bbb7a-xmpl-48ca-94b1-7f77c4d6dbf0",
                "bucket": {
                    "name": "BUCKET_NAME",
                    "ownerIdentity": {
                        "principalId": "A3XMPLFAF2AI3E"
                    },
                    "arn": "arn:aws:s3:::BUCKET_NAME"
                },
                "object": {
                    "key": "inbound/sample-java-s3.png",
                    "size": 21476,
                    "eTag": "d132690b6c65b6d1629721dcfb49b883",
                    "versionId": "",
                    "sequencer": "005E64A65DF093B26D"
                },
                "s3SchemaVersion": "1.0"
            },
            "userIdentity": {
                "principalId": "AWS:AIDAINPONIXMPLT3IKHL2"
            }
        }
    ]
}


{
  "invokingEvent": "{\"configurationItem\":{\"configurationItemCaptureTime\":\"2016-10-06T16:46:16.261Z\",\"awsAccountId\":\"123456789012\",\"configurationItemStatus\":\"OK\",\"resourceId\":\"i-00000000\",\"resourceName\":\"foo\",\"configurationStateMd5Hash\":\"8f1ee69b297895a0f8bc5753eca68e96\",\"resourceCreationTime\":\"2016-10-06T16:46:10.489Z\",\"configurationStateId\":0,\"configurationItemVersion\":\"1.2\",\"ARN\":\"arn:aws:ec2:ca-central-1:123456789012:instance/i-00000000\",\"awsRegion\":\"ca-central-1\",\"availabilityZone\":\"ca-central-1\",\"resourceType\":\"AWS::EC2::Instance\",\"tags\":{\"<Foo>\":\"<Bar>\"},\"relationships\":[{\"resourceId\":\"eipalloc-00000000\",\"resourceType\":\"AWS::EC2::EIP\",\"name\":\"Is attached to ElasticIp\"}],\"configuration\":{\"<foo>\":\"<bar>\"}},\"messageType\":\"ConfigurationItemChangeNotification\"}",
  "ruleParameters": "{\"<exampleKey>\":\"<exampleValue>\"}",
  "resultToken": "myResultToken",
  "eventLeftScope": false,
  "executionRoleArn": "arn:aws:iam::123456789012:role/config-role",
  "configRuleArn": "arn:aws:config:ca-central-1:123456789012:config-rule/config-rule-0123456",
  "configRuleName": "change-triggered-config-rule",
  "configRuleId": "config-rule-0123456",
  "accountId": "123456789012",
  "version": "1.0"
}


{
  "invocationId": "invocationIdExample",
  "deliveryStreamArn": "arn:aws:kinesis:EXAMPLE",
  "region": "ca-central-1",
  "records": [
    {
      "recordId": "49546986683135544286507457936321625675700192471156785154",
      "approximateArrivalTimestamp": 1495072949453,
      "data": "SGVsbG8sIHRoaXMgaXMgYSB0ZXN0IDEyMy4="
    }
  ]
}


{
  "Records": [
    {
      "awsRegion": "ca-central-1",
      "codecommit": {
        "references": [
          {
            "commit": "5c4ef1049f1d27deadbeeff313e0730018be182b",
            "ref": "refs/heads/master"
          }
        ]
      },
      "customData": "this is custom data",
      "eventId": "5a824061-17ca-46a9-bbf9-114edeadbeef",
      "eventName": "TriggerEventTest",
      "eventPartNumber": 1,
      "eventSource": "aws:codecommit",
      "eventSourceARN": "arn:aws:codecommit:ca-central-1:123456789012:my-repo",
      "eventTime": "2016-01-01T23:59:59.000+0000",
      "eventTotalParts": 1,
      "eventTriggerConfigId": "5a824061-17ca-46a9-bbf9-114edeadbeef",
      "eventTriggerName": "my-trigger",
      "eventVersion": "1.0",
      "userIdentityARN": "arn:aws:iam::123456789012:root"
    }
  ]
}


#!/bin/bash
set -eo pipefail
STACK=java-events
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf build .gradle target



mkdir java
mkdir java/lib
cp -r target/layer-java-layer-1.0-SNAPSHOT.jar java/lib/
zip -r layer_content.zip java



<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>layer-java-layer</artifactId>
    <packaging>jar</packaging>
    <version>1.0-SNAPSHOT</version>
    <name>layer-java-layer</name>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-lambda-java-core</artifactId>
            <version>1.2.3</version>
        </dependency>

        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.17.0</version>
        </dependency>
  </dependencies>

  <build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.13.0</version>
            <configuration>
                <source>21</source>
                <target>21</target>
                <release>21</release>
            </configuration>
        </plugin>
        
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-shade-plugin</artifactId>
            <version>3.5.2</version>
            <configuration>
                <createDependencyReducedPom>false</createDependencyReducedPom>
            </configuration>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>shade</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>

</project>


mvn clean install



package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.util.Map;

public class Handler {

    public String handleRequest(Map<String, String> input, Context context) throws IOException {
        // Parse the input JSON
        ObjectMapper objectMapper = new ObjectMapper();
        F1Car f1Car = objectMapper.readValue(objectMapper.writeValueAsString(input), F1Car.class);

        StringBuilder finalString = new StringBuilder();
        finalString.append(f1Car.getDriver());
        finalString.append(" is a driver for team ");
        finalString.append(f1Car.getTeam());
        return finalString.toString();
    }
}



package example;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class F1Car {
    
    private String team;
    private String driver;

    @JsonCreator
    public F1Car(@JsonProperty("team") String team,
                 @JsonProperty("driver") String driver) {
        this.team = team;
        this.driver = driver;
    }

    public String getTeam() {
        return team;
    }

    public void setTeam(String team) {
        this.team = team;
    }

    public String getDriver() {
        return driver;
    }

    public void setDriver(String driver) {
        this.driver = driver;
    }
}



<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>layer-java-function</artifactId>
    <packaging>jar</packaging>
    <version>1.0-SNAPSHOT</version>
    <name>layer-java-function</name>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>com.example</groupId>
            <artifactId>layer-java-layer</artifactId>
            <version>1.0-SNAPSHOT</version>
            <scope>provided</scope>
        </dependency>
  </dependencies>

  <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.13.0</version>
                <configuration>
                    <source>21</source>
                    <target>21</target>
                    <release>21</release>
                </configuration>
            </plugin>
            <!-- Use the maven-shade-plugin if you need additional dependencies for
                your function that aren't covered by the shared layer. 
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.5.2</version>
                <configuration>
                    <createDependencyReducedPom>false</createDependencyReducedPom>
                </configuration>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            -->
        </plugins>
    </build>

</project>


# frozen_string_literal: true

source "https://rubygems.org"

gem "tzinfo"



mkdir -p ruby/gems/3.3.0
cp -r vendor/bundle/ruby/3.3.0/* ruby/gems/3.3.0/
zip -r layer_content.zip ruby 



bundle config set --local path 'vendor/bundle'
bundle install




require 'json'
require 'tzinfo'

def lambda_handler(event:, context:)
    tz = TZInfo::Timezone.get('America/New_York')
    { statusCode: 200, body: tz.to_local(Time.utc(2018, 2, 1, 12, 30, 0)) }
end




#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
cd src/blank-csharp
dotnet lambda package
cd ../../
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name blank-csharp --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# Blank function (C#)

![Architecture](/sample-apps/blank-csharp/images/sample-blank-csharp.png)

The project source includes function code and supporting resources:

- `src/blank-csharp` - A C# .NET Core function.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application. For more information on the application's architecture and implementation, see [Managing Spot Instance Requests](https://docs.aws.amazon.com/lambda/latest/dg/services-ec2-tutorial.html) in the developer guide.

# Requirements
- [.NET Core SDK 8.0](https://dotnet.microsoft.com/download/dotnet-core/8.0)
- [AWS extensions for .NET CLI](https://github.com/aws/aws-extensions-for-dotnet-cli)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/blank-csharp

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    blank-csharp$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

# Deploy
To deploy the application, run `2-deploy.sh`.

    blank-csharp$ ./2-deploy.sh
    Amazon Lambda Tools for .NET Core applications (4.0.0)
    Executing publish command
    Uploading to e678bc216e6a0d510d661ca9ae2fd941  1009985 / 1009985.0  (100.00%)
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Waiting for stack create/update to complete
    Successfully created/updated stack - blank-csharp

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

To invoke the function, run `3-invoke.sh`.

    blank-csharp$ ./3-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    {"FunctionCount":43,"TotalCodeSize":362867335}

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map. The following service map shows the function managing spot instances in Amazon EC2.

![Service Map](/sample-apps/blank-csharp/images/blank-csharp-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/blank-csharp/images/blank-csharp-trace.png)

# Cleanup
To delete the application, run the cleanup script.

    blank-csharp$ ./4-cleanup.sh


using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amazon;
using Amazon.Util;
using Amazon.Lambda;
using Amazon.Lambda.Model;
using Amazon.Lambda.Core;
using Amazon.Lambda.SQSEvents;
using Amazon.XRay.Recorder.Core;
using Amazon.XRay.Recorder.Handlers.AwsSdk;
using System.IO;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.Json.JsonSerializer))]

namespace blankCsharp
{
  public class Function
  {
        private AmazonLambdaClient lambdaClient;

        public Function()
        {
            initialize();
        }

        async void initialize()
        {
            AWSSDKHandler.RegisterXRayForAllServices();
            lambdaClient = new AmazonLambdaClient();
            await callLambda();
        }

        public async Task<AccountUsage> FunctionHandler(SQSEvent invocationEvent, ILambdaContext context)
        {
            GetAccountSettingsResponse accountSettings;
            try
            {
                accountSettings = await callLambda();
            }
            catch (AmazonLambdaException ex)
            {
                throw ex;
            }

            AccountUsage accountUsage = accountSettings.AccountUsage;
            MemoryStream logData = new MemoryStream();
            StreamReader logDataReader = new StreamReader(logData);

            Amazon.Lambda.Serialization.Json.JsonSerializer serializer = new Amazon.Lambda.Serialization.Json.JsonSerializer();

            serializer.Serialize<System.Collections.IDictionary>(System.Environment.GetEnvironmentVariables(), logData);
            LambdaLogger.Log("ENVIRONMENT VARIABLES: " + logDataReader.ReadLine());
            logData.Position = 0;
            serializer.Serialize<ILambdaContext>(context, logData);
            LambdaLogger.Log("CONTEXT: " + logDataReader.ReadLine());
            logData.Position = 0;
            serializer.Serialize<SQSEvent>(invocationEvent, logData);
            LambdaLogger.Log("EVENT: " + logDataReader.ReadLine());

            return accountUsage;
        }

        public async Task<GetAccountSettingsResponse> callLambda()
        {
            var request = new GetAccountSettingsRequest();
            var response = await lambdaClient.GetAccountSettingsAsync(request);
            return response;
        }
  }
}



<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
    <AWSProjectType>Lambda</AWSProjectType>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="2.1.0" />
    <PackageReference Include="Amazon.Lambda.SQSEvents" Version="2.1.0" />
    <PackageReference Include="Amazon.Lambda.Serialization.Json" Version="2.1.0" />
    <PackageReference Include="AWSSDK.Core" Version="3.7.103.24" />
    <PackageReference Include="AWSSDK.Lambda" Version="3.7.104.3" />
    <PackageReference Include="AWSXRayRecorder.Core" Version="2.13.0" />
    <PackageReference Include="AWSXRayRecorder.Handlers.AwsSdk" Version="2.11.0" />
  </ItemGroup>
</Project>


{
  "Information" : [
    "This file provides default values for the deployment wizard inside Visual Studio and the AWS Lambda commands added to the .NET Core CLI.",
    "To learn more about the Lambda commands with the .NET Core CLI execute the following command at the command line in the project root directory.",

    "dotnet lambda help",

    "All the command line options for the Lambda command can be specified in this file."
  ],

  "profile":"default",
  "region" : "us-east-2",
  "configuration" : "Release",
  "framework" : "net8.0",
  "function-runtime":"dotnet8",
  "function-memory-size" : 512,
  "function-timeout" : 30,
  "function-handler" : "blank-csharp::blankCsharp.Function::FunctionHandler"
}


AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      Handler: blank-csharp::blankCsharp.Function::FunctionHandler
      Runtime: dotnet8
      CodeUri: src/blank-csharp/bin/Release/net8.0/blank-csharp.zip
      Description: Call the AWS Lambda API
      MemorySize: 256
      Timeout: 9
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
      Tracing: Active


#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name blank-csharp --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
if [[ $(aws --version) =~ "aws-cli/2." ]]; then PAYLOAD_PROTOCOL="fileb"; else  PAYLOAD_PROTOCOL="file"; fi;
while true; do
  aws lambda invoke --function-name $FUNCTION --payload $PAYLOAD_PROTOCOL://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



{
  "Records": [
    {
      "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
      "receiptHandle": "MessageReceiptHandle",
      "body": "Hello from SQS!",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
      "awsRegion": "us-west-2"
    }
  ]
}



using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using Amazon.XRay.Recorder.Core;
using Amazon.XRay.Recorder.Core.Internal.Entities;
using Amazon.XRay.Recorder.Core.Exceptions;
using Amazon.XRay.Recorder.Core.Sampling;
using Amazon.XRay.Recorder.Core.Internal.Context;
using Amazon.XRay.Recorder.Core.Internal.Utils;

using Xunit;
using Amazon.Lambda.Core;
using Amazon.Lambda.SQSEvents;
using Amazon.Lambda.TestUtilities;

using blankCsharp;

namespace blankCsharp.Tests
{
    public class TraceFixture : IDisposable
    {
        private static readonly String _traceHeaderValue = "Root=" + "1-5d66d2fe-8e6fcab805a0833803735bc8" + ";Parent=53995c3f42cd8ad8;Sampled=1";

        public TraceFixture()
        {
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTaskRootKey, "test");
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTraceHeaderKey, _traceHeaderValue);
            Environment.SetEnvironmentVariable("AWS_REGION", "us-east-2");
        }

        public void Dispose()
        {
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTaskRootKey, null);
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTraceHeaderKey, null);
            Environment.SetEnvironmentVariable("AWS_REGION", null);
        }
    }

    public class FunctionTest : IClassFixture<TraceFixture>
    {
        TraceFixture fixture;

        [Fact]
        public void TestFunction()
        {
            var function = new Function();
            var context = new TestLambdaContext();
            SQSEvent input = new SQSEvent();
            var task = function.FunctionHandler(input, context);
            task.Wait(7000);
            bool completed = task.IsCompleted;
            Assert.True(completed);
        }
    }
}



<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netcoreapp2.1</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="1.1.0" />
    <PackageReference Include="Amazon.Lambda.TestUtilities" Version="1.1.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="15.5.0" />
    <PackageReference Include="xunit" Version="2.3.1" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.3.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\blank-csharp\blank-csharp.csproj" />
  </ItemGroup>
</Project>


#!/bin/bash
set -eo pipefail
STACK=blank-csharp
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf src/blank-csharp/bin src/blank-csharp/obj


#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



#!/bin/bash
set -eo pipefail
BUCKET=$(aws cloudformation describe-stack-resource --stack-name s3-java --logical-resource-id bucket --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws s3 cp images/sample-s3-java.png s3://$BUCKET/inbound/



#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name s3-java --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
BUCKET_NAME=$(aws cloudformation describe-stack-resource --stack-name s3-java --logical-resource-id bucket --query 'StackResourceDetail.PhysicalResourceId' --output text)

if [ ! -f event.json ]; then
  cp event.json.template event.json
  sed -i'' -e "s/BUCKET_NAME/$BUCKET_NAME/" event.json

fi
while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



# S3 image resizer (Java)

![Architecture](/sample-apps/s3-java/images/sample-s3-java.png)

The project source includes function code and supporting resources:

- `src/main` - A Java Lambda function that scales down an image stored in S3.
- `src/test` - A unit test and helper classes.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `build.gradle` - A Gradle build file.
- `pom.xml` - A Maven build file.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- [Java 21 runtime environment (SE JRE)](https://www.oracle.com/java/technologies/javase-downloads.html)
- [Gradle 5](https://gradle.org/releases/) or [Maven 3](https://maven.apache.org/docs/history.html)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/s3-java

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    s3-java$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

To build a Lambda layer that contains the function's runtime dependencies, run `2-build-layer.sh`. Packaging dependencies in a layer reduces the size of the deployment package that you upload when you modify your code.

    s3-java$ ./2-build-layer.sh

# Deploy
To deploy the application, run `3-deploy.sh`.

    s3-java$ ./3-deploy.sh
    BUILD SUCCESSFUL in 1s
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Successfully created/updated stack - s3-java

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

You can also build the application with Maven. To use maven, add `mvn` to the command.

    java-basic$ ./3-deploy.sh mvn
    [INFO] Scanning for projects...
    [INFO] -----------------------< com.example:s3-java >-----------------------
    [INFO] Building s3-java-function 1.0-SNAPSHOT
    [INFO] --------------------------------[ jar ]---------------------------------
    ...

# Test
This Lambda function takes an image that's currently stored in S3, and scales it down into
a thumbnail-sized image. To upload an image file to the application bucket, run `4-upload.sh`.

    s3-java$ ./4-upload.sh

In your `s3-java-bucket-<random_uuid>` bucket that was created in step 3, you should now see a
key `inbound/sample-s3-java.png` file, which represents the original image.

To invoke the function directly, run `5-invoke.sh`.

    s3-java$ ./5-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }

Let the script invoke the function a few times and then press `CRTL+C` to exit.

If you look at the `s3-java-bucket-<random_uuid>` bucket in your account, you should now see a
key `resized-inbound/sample-s3-java.png` file, which represents the new, shrunken image.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map.

![Service Map](/sample-apps/s3-java/images/s3-java-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/s3-java/images/s3-java-trace.png)

# Cleanup
To delete the application, run `6-cleanup.sh`.

    blank$ ./6-cleanup.sh



<Configuration status="WARN">
  <Appenders>
    <Lambda name="Lambda">
      <PatternLayout>
          <pattern>%d{yyyy-MM-dd HH:mm:ss} %X{AWSRequestId} %-5p %c{1} - %m%n</pattern>
      </PatternLayout>
    </Lambda>
  </Appenders>
  <Loggers>
    <Root level="INFO">
      <AppenderRef ref="Lambda"/>
    </Root>
    <Logger name="software.amazon.awssdk" level="WARN" />
    <Logger name="software.amazon.awssdk.request" level="DEBUG" />
  </Loggers>
</Configuration>


package example;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.imageio.ImageIO;

import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.S3Client;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.S3EventNotificationRecord;

// Handler value: example.Handler
public class Handler implements RequestHandler<S3Event, String> {
  private static final float MAX_DIMENSION = 100;
  private final String REGEX = ".*\\.([^\\.]*)";
  private final String JPG_TYPE = "jpg";
  private final String JPG_MIME = "image/jpeg";
  private final String PNG_TYPE = "png";
  private final String PNG_MIME = "image/png";
  @Override
  public String handleRequest(S3Event s3event, Context context) {
    LambdaLogger logger = context.getLogger();
    try {
      S3EventNotificationRecord record = s3event.getRecords().get(0);
      
      String srcBucket = record.getS3().getBucket().getName();

      // Object key may have spaces or unicode non-ASCII characters.
      String srcKey = record.getS3().getObject().getUrlDecodedKey();

      String dstBucket = srcBucket;
      String dstKey = "resized-" + srcKey;

      // Infer the image type.
      Matcher matcher = Pattern.compile(REGEX).matcher(srcKey);
      if (!matcher.matches()) {
          logger.log("Unable to infer image type for key " + srcKey);
          return "";
      }
      String imageType = matcher.group(1);
      if (!(JPG_TYPE.equals(imageType)) && !(PNG_TYPE.equals(imageType))) {
          logger.log("Skipping non-image " + srcKey);
          return "";
      }

      // Download the image from S3 into a stream
      S3Client s3Client = S3Client.builder().build();
      InputStream s3Object = getObject(s3Client, srcBucket, srcKey);

      // Read the source image and resize it
      BufferedImage srcImage = ImageIO.read(s3Object);
      BufferedImage newImage = resizeImage(srcImage);

      // Re-encode image to target format
      ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
      ImageIO.write(newImage, imageType, outputStream);

      // Upload new image to S3
      putObject(s3Client, outputStream, dstBucket, dstKey, imageType, logger);

      logger.log("Successfully resized " + srcBucket + "/"
              + srcKey + " and uploaded to " + dstBucket + "/" + dstKey);
      return "Ok";
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  private InputStream getObject(S3Client s3Client, String bucket, String key) {
    GetObjectRequest getObjectRequest = GetObjectRequest.builder()
      .bucket(bucket)
      .key(key)
      .build();
    return s3Client.getObject(getObjectRequest);
  }

  private void putObject(S3Client s3Client, ByteArrayOutputStream outputStream,
    String bucket, String key, String imageType, LambdaLogger logger) {
      Map<String, String> metadata = new HashMap<>();
      metadata.put("Content-Length", Integer.toString(outputStream.size()));
      if (JPG_TYPE.equals(imageType)) {
        metadata.put("Content-Type", JPG_MIME);
      } else if (PNG_TYPE.equals(imageType)) {
        metadata.put("Content-Type", PNG_MIME);
      }

      PutObjectRequest putObjectRequest = PutObjectRequest.builder()
        .bucket(bucket)
        .key(key)
        .metadata(metadata)
        .build();

      // Uploading to S3 destination bucket
      logger.log("Writing to: " + bucket + "/" + key);
      try {
        s3Client.putObject(putObjectRequest,
          RequestBody.fromBytes(outputStream.toByteArray()));
      }
      catch(AwsServiceException e)
      {
        logger.log(e.awsErrorDetails().errorMessage());
        System.exit(1);
      }
  }

  /**
   * Resizes (shrinks) an image into a small, thumbnail-sized image.
   * 
   * The new image is scaled down proportionally based on the source
   * image. The scaling factor is determined based on the value of
   * MAX_DIMENSION. The resulting new image has max(height, width)
   * = MAX_DIMENSION.
   * 
   * @param srcImage BufferedImage to resize.
   * @return New BufferedImage that is scaled down to thumbnail size.
   */
  private BufferedImage resizeImage(BufferedImage srcImage) {
    int srcHeight = srcImage.getHeight();
    int srcWidth = srcImage.getWidth();
    // Infer scaling factor to avoid stretching image unnaturally
    float scalingFactor = Math.min(
      MAX_DIMENSION / srcWidth, MAX_DIMENSION / srcHeight);
    int width = (int) (scalingFactor * srcWidth);
    int height = (int) (scalingFactor * srcHeight);

    BufferedImage resizedImage = new BufferedImage(width, height,
            BufferedImage.TYPE_INT_RGB);
    Graphics2D graphics = resizedImage.createGraphics();
    // Fill with white before applying semi-transparent (alpha) images
    graphics.setPaint(Color.white);
    graphics.fillRect(0, 0, width, height);
    // Simple bilinear resize
    graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
            RenderingHints.VALUE_INTERPOLATION_BILINEAR);
    graphics.drawImage(srcImage, 0, 0, width, height, null);
    graphics.dispose();
    return resizedImage;
  }
}


<Configuration status="WARN">
  <Appenders>
    <Console name="ConsoleAppender" target="SYSTEM_OUT">
      <PatternLayout pattern="%d{YYYY-MM-dd HH:mm:ss} [%t] %-5p %c:%L - %m%n" />
    </Console>
  </Appenders>
  <Loggers>
    <Root level="INFO">
      <AppenderRef ref="ConsoleAppender"/>
    </Root>
    <Logger name="software.amazon.awssdk" level="WARN" />
    <Logger name="software.amazon.awssdk.request" level="DEBUG" />
  </Loggers>
</Configuration>


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.CognitoIdentity;
import com.amazonaws.services.lambda.runtime.ClientContext;
import com.amazonaws.services.lambda.runtime.LambdaLogger;

public class TestContext implements Context{

  public TestContext() {}
  public String getAwsRequestId(){
    return new String("495b12a8-xmpl-4eca-8168-160484189f99");
  }
  public String getLogGroupName(){
    return new String("/aws/lambda/my-function");
  }
  public String getLogStreamName(){
    return new String("2020/02/26/[$LATEST]704f8dxmpla04097b9134246b8438f1a");
  }
  public String getFunctionName(){
    return new String("my-function");
  }
  public String getFunctionVersion(){
    return new String("$LATEST");
  }
  public String getInvokedFunctionArn(){
    return new String("arn:aws:lambda:us-east-2:123456789012:function:my-function");
  }
  public CognitoIdentity getIdentity(){
    return null;
  }
  public ClientContext getClientContext(){
    return null;
  }
  public int getRemainingTimeInMillis(){
    return 300000;
  }
  public int getMemoryLimitInMB(){
    return 512;
  }
  public LambdaLogger getLogger(){
    return new TestLogger();
  }

}


package example;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.amazonaws.services.lambda.runtime.LambdaLogger;

public class TestLogger implements LambdaLogger {
  private static final Logger logger = LoggerFactory.getLogger(TestLogger.class);
  public TestLogger(){}
  public void log(String message){
    logger.info(message);
  }
  public void log(byte[] message){
    logger.info(new String(message));
  }
}



package example;

import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.RequestParametersEntity;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.ResponseElementsEntity;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.S3BucketEntity;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.S3Entity;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.S3EventNotificationRecord;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.S3ObjectEntity;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification.UserIdentityEntity;

import java.util.ArrayList;
import java.lang.Long;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.IOException;

import com.amazonaws.xray.AWSXRay;
import com.amazonaws.xray.AWSXRayRecorderBuilder;
import com.amazonaws.xray.strategy.sampling.NoSamplingStrategy;

class InvokeTest {

  public InvokeTest() {
    AWSXRayRecorderBuilder builder = AWSXRayRecorderBuilder.standard();
    builder.withSamplingStrategy(new NoSamplingStrategy());
    AWSXRay.setGlobalRecorder(builder.build());
  }

  @Test
  void invokeTest() throws IOException {
    AWSXRay.beginSegment("s3-java-test");
    String bucket = new String(Files.readAllLines(Paths.get("bucket-name.txt")).get(0));
    S3EventNotificationRecord record = new S3EventNotificationRecord("us-east-2",
       "ObjectCreated:Put",
       "aws:s3",
       "2020-03-08T00:30:12.456Z",
       "2.1",
       new RequestParametersEntity("174.255.255.156"),
       new ResponseElementsEntity("nBbLJPAHhdvxmplPvtCgTrWCqf/KtonyV93l9rcoMLeIWJxpS9x9P8u01+Tj0OdbAoGs+VGvEvWl/Sg1NW5uEsVO25Laq7L", "AF2D7AB6002E898D"),
       new S3Entity("682bbb7a-xmpl-48ca-94b1-7f77c4d6dbf0",
        new S3BucketEntity(bucket,
          new UserIdentityEntity("A3XMPLFAF2AI3E"),
          "arn:aws:s3:::" + bucket),
        new S3ObjectEntity("inbound/sample-s3-java.png",
          new Long(21476),
          "d132690b6c65b6d1629721dcfb49b883",
          "",
          "005E64A65DF093B26D"),
        "1.0"),
       new UserIdentityEntity("AWS:AIDAINPONIXMPLT3IKHL2"));
    ArrayList<S3EventNotificationRecord> records = new ArrayList<S3EventNotificationRecord>();
    records.add(record);
    S3Event event = new S3Event(records);
    
    Context context = new TestContext();
    Handler handler = new Handler();
    String result = handler.handleRequest(event, context);
    assertTrue(result.contains("Ok"));
    AWSXRay.endSegment();
  }

}



{
    "Records": [
        {
            "awsRegion": "us-east-2",
            "eventName": "ObjectCreated:Put",
            "eventSource": "aws:s3",
            "eventTime": "2020-03-08T00:30:12.456Z",
            "eventVersion": "2.1",
            "requestParameters": {
                "sourceIPAddress": "174.255.255.156"
            },
            "responseElements": {
                "xAmzId2": "nBbLJPAHhdvxmplPvtCgTrWCqf/KtonyV93l9rcoMLeIWJxpS9x9P8u01+Tj0OdbAoGs+VGvEvWl/Sg1NW5uEsVO25Laq7L",
                "xAmzRequestId": "AF2D7AB6002E898D"
            },
            "s3": {
                "configurationId": "682bbb7a-xmpl-48ca-94b1-7f77c4d6dbf0",
                "bucket": {
                    "name": "BUCKET_NAME",
                    "ownerIdentity": {
                        "principalId": "A3XMPLFAF2AI3E"
                    },
                    "arn": "arn:aws:s3:::BUCKET_NAME"
                },
                "object": {
                    "key": "inbound/sample-s3-java.png",
                    "size": 21476,
                    "eTag": "d132690b6c65b6d1629721dcfb49b883",
                    "versionId": "",
                    "sequencer": "005E64A65DF093B26D"
                },
                "s3SchemaVersion": "1.0"
            },
            "userIdentity": {
                "principalId": "AWS:AIDAINPONIXMPLT3IKHL2"
            }
        }
    ]
}


{
    "Records": [
        {
            "awsRegion": "us-east-2",
            "eventName": "ObjectCreated:Put",
            "eventSource": "aws:s3",
            "eventTime": "2020-03-08T00:30:12.456Z",
            "eventVersion": "2.1",
            "requestParameters": {
                "sourceIPAddress": "174.255.255.156"
            },
            "responseElements": {
                "xAmzId2": "nBbLJPAHhdvxmplPvtCgTrWCqf/KtonyV93l9rcoMLeIWJxpS9x9P8u01+Tj0OdbAoGs+VGvEvWl/Sg1NW5uEsVO25Laq7L",
                "xAmzRequestId": "AF2D7AB6002E898D"
            },
            "s3": {
                "configurationId": "682bbb7a-xmpl-48ca-94b1-7f77c4d6dbf0",
                "bucket": {
                    "name": "BUCKET_NAME",
                    "ownerIdentity": {
                        "principalId": "A3XMPLFAF2AI3E"
                    },
                    "arn": "arn:aws:s3:::BUCKET_NAME"
                },
                "object": {
                    "key": "inbound/sample-s3-java.png",
                    "size": 21476,
                    "eTag": "d132690b6c65b6d1629721dcfb49b883",
                    "versionId": "",
                    "sequencer": "005E64A65DF093B26D"
                },
                "s3SchemaVersion": "1.0"
            },
            "userIdentity": {
                "principalId": "AWS:AIDAINPONIXMPLT3IKHL2"
            }
        }
    ]
}


plugins {
    id 'java'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation platform('software.amazon.awssdk:bom:2.16.1')
    implementation platform('com.amazonaws:aws-xray-recorder-sdk-bom:2.11.0')
    implementation 'software.amazon.awssdk:s3'
    implementation 'com.amazonaws:aws-lambda-java-core:1.2.1'
    implementation 'com.amazonaws:aws-lambda-java-events:3.11.0'
    implementation 'com.amazonaws:aws-xray-recorder-sdk-core'
    implementation 'com.amazonaws:aws-xray-recorder-sdk-aws-sdk'
    implementation 'com.amazonaws:aws-xray-recorder-sdk-aws-sdk-v2-instrumentor'
    implementation 'org.slf4j:slf4j-nop:2.0.6'
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.6.0'
    testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.6.0'
}

test {
    useJUnitPlatform()
}

task packageJar(type: Zip) {
    into('lib') {
        from(jar)
        from(configurations.runtimeClasspath)
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

build.dependsOn packageJar



#!/bin/bash
set -eo pipefail
STACK=s3-java
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
APP_BUCKET=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id bucket --query 'StackResourceDetail.PhysicalResourceId' --output text)
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

while true; do
    read -p "Delete application bucket ($APP_BUCKET)?" response
    case $response in
        [Yy]* ) aws s3 rb --force s3://$APP_BUCKET; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json event.json
rm -rf build .gradle target



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
aws s3 cp images/sample-s3-java.png s3://$ARTIFACT_BUCKET/inbound/sample-s3-java.png
TEMPLATE=template.yml
if [ $1 ]
then
  if [ $1 = mvn ]
  then
    TEMPLATE=template-mvn.yml
    mvn package
  fi
else
  gradle build -i
fi
aws cloudformation package --template-file $TEMPLATE --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name s3-java --capabilities CAPABILITY_NAMED_IAM



event.json


AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  bucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: build/distributions/s3-java.zip
      Handler: example.Handler
      Runtime: java21
      Description: Java function
      MemorySize: 512
      Timeout: 30
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
        - AWSLambdaVPCAccessExecutionRole
        - AmazonS3FullAccess
      Tracing: Active
      Layers:
        - !Ref libs
      Events:
        s3Notification:
          Type: S3
          Properties:
            Bucket: !Ref bucket
            Events: s3:ObjectCreated:*
            Filter:
              S3Key:
                Rules:
                - Name: prefix
                  Value: inbound/
  libs:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: s3-java-lib
      Description: Dependencies for the Java S3 sample app.
      ContentUri: build/s3-java-lib.zip
      CompatibleRuntimes:
        - java21



<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>s3-java</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>s3-java-function</name>
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>21</maven.compiler.source>
    <maven.compiler.target>21</maven.compiler.target>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>software.amazon.awssdk</groupId>
        <artifactId>bom</artifactId>
        <version>2.16.1</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
      <dependency>
        <groupId>com.amazonaws</groupId>
        <artifactId>aws-xray-recorder-sdk-bom</artifactId>
        <version>2.11.0</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <dependencies>
    <dependency>
      <groupId>software.amazon.awssdk</groupId>
      <artifactId>s3</artifactId>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-core</artifactId>
      <version>1.2.1</version>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-events</artifactId>
      <version>3.11.0</version>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-xray-recorder-sdk-core</artifactId>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-xray-recorder-sdk-aws-sdk</artifactId>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-xray-recorder-sdk-aws-sdk-v2-instrumentor</artifactId>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-nop</artifactId>
      <version>2.0.13</version>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>5.6.0</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>5.6.0</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.5.2</version>
        <configuration>
          <createDependencyReducedPom>false</createDependencyReducedPom>
        </configuration>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.13.0</version>
        <configuration>
          <source>21</source>
          <target>21</target>
          <release>21</release>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>


AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  bucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: target/s3-java-1.0-SNAPSHOT.jar
      Handler: example.Handler::handleRequest
      Runtime: java21
      Description: Java function
      MemorySize: 512
      Timeout: 30
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
        - AWSLambdaVPCAccessExecutionRole
        - AmazonS3FullAccess
      Tracing: Active
      Events:
        s3Notification:
          Type: S3
          Properties:
            Bucket: !Ref bucket
            Events: s3:ObjectCreated:*
            Filter:
              S3Key:
                Rules:
                - Name: prefix
                  Value: inbound/



#!/bin/bash
set -eo pipefail
gradle -q packageJar
mv build/distributions/s3-java.zip build/s3-java-lib.zip


{
    "java.configuration.updateBuildConfiguration": "automatic",
    "java.jdt.ls.vmargs": "-XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx2G -Xms100m -Xlog:disable"
}


#!/bin/bash
set -eo pipefail
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME


# Using Amazon EFS for file storage

This application demonstrates the use of Amazon EFS with AWS Lambda. You can use Amazon EFS to create file systems that provide shared storage to Lambda functions and other compute resources. Your functions mount a folder in the file system to a local directory with the NFS protocol. The sample application creates a VPC network, file system, function, and supporting resources with AWS CloudFormation.

The function takes a event with the following structure:

```
{
  "fileName": "test.bin",
  "fileSize": 1048576
}
```

The function creates a file of the specified size (1MB in this case) and then reads it into memory.

The project source includes function code and supporting resources:

- `dbadmin` - A Node.js function that reads and writes files.
- `lib` - A Lambda layer with the npm modules used by the application's function.
- `event.json` - A JSON document that can be used to test the application's function.
- `template.yml` - An AWS CloudFormation template that creates the application.
- `template-vpcefs.yml` - A template that creates the VPC and Amazon EFS file system.
- `1-create-bucket.sh`, `2-deploy-vpc.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements

To deploy the sample application, you need the following tools:

- [Node.js 18 with npm](https://nodejs.org/en/download/releases/).
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

To run the sample application in AWS, you need permission to use Lambda and the following services.

- Amazon EFS ([pricing](https://aws.amazon.com/efs/pricing/))
- Amazon VPC ([pricing](https://aws.amazon.com/vpc/pricing/))
- AWS Identity and Access Management
- AWS CloudFormation

Standard charges apply for each service.

# Setup

Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/efs-nodejs

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    efs-nodejs$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

To create the VPC and EFS file system, run the `2-deploy-vpc.sh` script.

    efs-nodejs$ ./2-deploy-vpc.sh

# Deploy

To deploy the application, run `3-deploy.sh`.

    efs-nodejs$ ./3-deploy.sh
    Uploading to e678bc216e6a0d510d661ca9ae2fd941  2678 / 2678.0  (100.00%)
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Waiting for stack create/update to complete
    Successfully created/updated stack - efs-nodejs

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

# Test

To invoke the function with a test event, use the invoke script.

    efs-nodejs$ ./4-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    {"writeTimeMs":3.316225,"readTimeMs":166.129772,"fileSizeBytes":1398104}

Let the script invoke the function a few times and then press `CRTL+C` to exit.

# Cleanup

To delete the application, run the cleanup script.

    efs-nodejs$ ./5-cleanup.sh



#!/bin/bash
set -eo pipefail
aws cloudformation deploy --template-file template-vpcefs.yml --stack-name efs-nodejs-vpc



#!/bin/bash
set -eo pipefail
STACK=efs-nodejs
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json lib/nodejs/package-lock.json
rm -rf lib/nodejs/node_modules



$ ./4-invoke.sh 
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
{"writeTimeMs":60.659086,"readTimeMs":"Read error: Error: ENOENT: no such file or directory, open '/mnt/efs0/test.bin'","fileSizeBytes":0}
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
{"writeTimeMs":60.002857,"readTimeMs":79.54446,"fileSizeBytes":1398104}
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
{"writeTimeMs":50.76445,"readTimeMs":39.566218,"fileSizeBytes":1398104}
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
{"writeTimeMs":60.457508,"readTimeMs":199.181445,"fileSizeBytes":1398104}
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}


import fs from 'node:fs/promises'
const crypto = await import('node:crypto')
const dir = process.env.mountPath

export const handler = async (event) => {
  console.log("EVENT: %s", JSON.stringify(event, null, 2))
  const filePath = dir + "/" + event.fileName
  const fileSize = event.fileSize
  // generate file
  const buffer = crypto.randomBytes(fileSize)
  // write operation
  const writeTimeMs = await writeFile(filePath, buffer)
  // read file
  const readTimeMs = await readFile(filePath)
  // stat file
  const fileStat = await fs.stat(filePath)
  const fileSizeBytes = fileStat.size
  console.log("File size: %s bytes", fileSizeBytes)
  // format response
  var response = {
    "writeTimeMs": writeTimeMs,
    "readTimeMs": readTimeMs,
    "fileSizeBytes": fileSizeBytes
  }
  return response
}

var readFile = async function(filePath){
  console.log("Attempting to read file: %s", filePath)
  const readstart = process.hrtime()
  var fileContents
  try {
    fileContents = await fs.readFile(filePath, "utf8")
    const readend = process.hrtime(readstart)
    const readTimeMs = readend[0] * 1000 + readend[1] / 1000000
    console.log("Read completed in %dms", readTimeMs)
    return readTimeMs
  } catch (error){
    console.error(error)
    return "Read error: " + error
  }
}

var writeFile = async function(filePath, buffer){
  console.log("Attempting to write file: %s", filePath)
  var writestart = process.hrtime()
  try {
    const fileBase64 = buffer.toString('base64')
    fs.writeFile(filePath, fileBase64)
    var writeend = process.hrtime(writestart)
    const writeTimeMs = writeend[0] * 1000 + writeend[1] / 1000000
    console.log("Write completed in %dms", writeTimeMs)
    return writeTimeMs
  } catch (error){
    console.error(error)
    return "Write error: " + error
  }
}


AWSTemplateFormatVersion: 2010-09-09
Resources:
  fileSystem:
    Type: AWS::EFS::FileSystem
  mountTargetA:
    Type: AWS::EFS::MountTarget
    Properties:
      FileSystemId: !Ref fileSystem
      SubnetId: !Ref privateSubnetA
      SecurityGroups:
        - !GetAtt privateVPC.DefaultSecurityGroup
  mountTargetB:
    Type: AWS::EFS::MountTarget
    Properties:
      FileSystemId: !Ref fileSystem
      SubnetId: !Ref privateSubnetB
      SecurityGroups:
        - !GetAtt privateVPC.DefaultSecurityGroup
  accessPoint:
    Type: AWS::EFS::AccessPoint
    Properties:
      FileSystemId: !Ref fileSystem
      PosixUser:
        Uid: "1001"
        Gid: "1001"
      RootDirectory:
        CreationInfo:
          OwnerGid: "1001"
          OwnerUid: "1001"
          Permissions: "755"
        Path: "/efs-nodejs-storage"
  privateVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 172.31.0.0/16
      Tags:
        - Key: Name
          Value: !Ref AWS::StackName
  privateSubnetA:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref privateVPC
      AvailabilityZone:
        Fn::Select:
         - 0
         - Fn::GetAZs: ""
      CidrBlock: 172.31.3.0/24
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Join ["-", [!Ref "AWS::StackName","subnet-a"]]
  privateSubnetB:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref privateVPC
      AvailabilityZone:
        Fn::Select:
         - 1
         - Fn::GetAZs: ""
      CidrBlock: 172.31.2.0/24
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Join ["-", [!Ref "AWS::StackName","subnet-b"]]
  privateRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref privateVPC
  privateSubnetARouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref privateSubnetA
      RouteTableId: !Ref privateRouteTable
  privateSubnetBRouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref privateSubnetB
      RouteTableId: !Ref privateRouteTable
Outputs:
  privateVPCSecurityGroup:
    Description: Default security for Lambda VPC
    Value: !GetAtt privateVPC.DefaultSecurityGroup
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","vpc-sg"]]
  privateVPCID:
    Description: VPC ID
    Value: !Ref privateVPC
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","vpc"]]
  privateSubnetAID:
    Description: Private Subnet A ID
    Value: !Ref privateSubnetA
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","subnet-a"]]
  privateSubnetBID:
    Description: Private Subnet B ID
    Value: !Ref privateSubnetB
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","subnet-b"]]
  fileSystemId:
    Description: File system ID
    Value: !Ref fileSystem
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","filesystem"]]
  mountTargetA:
    Description: Mount point A ID
    Value: !Ref mountTargetA
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","mounttarget-a"]]
  mountTargetB:
    Description: Mount point B ID
    Value: !Ref mountTargetB
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","mounttarget-b"]]
  accessPointArn:
    Description: Access point ARN
    Value: !GetAtt accessPoint.Arn
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","accesspoint"]]



#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name efs-nodejs --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
STACK=efs-nodejs
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deploying to stack $STACK"
fi
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name $STACK --capabilities CAPABILITY_NAMED_IAM

# attach to different VPC
#aws cloudformation deploy --template-file out.yml --stack-name $STACK --capabilities CAPABILITY_NAMED_IAM --parameter-overrides vpcStackName=lambda-vpc



AWSTemplateFormatVersion: 2010-09-09
Description: An AWS Lambda application that connects to an EFS file system in the VPC to share files.
Transform: AWS::Serverless-2016-10-31
Parameters:
  vpcStackName:
    Default: efs-nodejs-vpc
    Description: VPC and file system stack name
    Type: String
  mountPath:
    Default: "/mnt/efs0"
    Description: File system mount path
    Type: String
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: function/.
      Description: Use a file system.
      FileSystemConfigs:
        - LocalMountPath: !Ref mountPath
          Arn: 
            Fn::ImportValue: !Sub "${vpcStackName}-accesspoint"
      Environment:
          Variables:
            mountPath: !Ref mountPath
      MemorySize: 128
      Timeout: 15
      Runtime: nodejs18.x
      Tracing: Active
      Handler: index.handler
      VpcConfig:
        SecurityGroupIds:
          - Fn::ImportValue:
                !Sub "${vpcStackName}-vpc-sg"
        SubnetIds:
          - Fn::ImportValue:
                !Sub "${vpcStackName}-subnet-a"
          - Fn::ImportValue:
                !Sub "${vpcStackName}-subnet-b"
      # Function's execution role
      Policies:
        - AWSLambdaVPCAccessExecutionRole
        - AmazonElasticFileSystemClientReadWriteAccess
        - AWSXRayDaemonWriteAccess



{
  "fileName": "test.bin",
  "fileSize": 1048576
}



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
TEMPLATE=template.yml
if [ $1 ]
then
  if [ $1 = mvn ]
  then
    TEMPLATE=template-mvn.yml
    mvn package
  fi
else
  gradle build -i
fi
aws cloudformation package --template-file $TEMPLATE --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name java-basic --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# Basic function with minimal dependencies (Java)

![Architecture](/sample-apps/java-basic/images/sample-java-basic.png)

The project source includes function code and supporting resources:
- `src/main` - A Java function.
- `src/test` - A unit test and helper classes.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `build.gradle` - A Gradle build file.
- `pom.xml` - A Maven build file.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- [Java 8 runtime environment (SE JRE)](https://www.oracle.com/java/technologies/javase-downloads.html)
- [Gradle 5](https://gradle.org/releases/) or [Maven 3](https://maven.apache.org/docs/history.html)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/java-basic

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    java-basic$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e4xmplb5b22e0d

# Deploy
To deploy the application, run `2-deploy.sh`.

    java-basic$ ./2-deploy.sh
    BUILD SUCCESSFUL in 1s
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Successfully created/updated stack - java-basic

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

You can also build the application with Maven. To use maven, add `mvn` to the command.

    java-basic$ ./2-deploy.sh mvn
    [INFO] Scanning for projects...
    [INFO] -----------------------< com.example:java-basic >-----------------------
    [INFO] Building java-basic-function 1.0-SNAPSHOT
    [INFO] --------------------------------[ jar ]---------------------------------
    ...

# Test
To invoke the function, run `3-invoke.sh`.

    java-basic$ ./3-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    "200 OK"

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map.

![Service Map](/sample-apps/java-basic/images/java-basic-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/java-basic/images/java-basic-trace.png)

# Configure Handler Class

By default, the function uses a handler class named `Handler` that takes a map as input and returns a string. The project also includes handlers that use other input and output types. These are defined in the following files under src/main/java/example:

- `Handler.java` – Takes a `Map<String,String>` as input.
- `HandlerInteger.java` – Takes an `Integer` as input.
- `HandlerList.java` – Takes a `List<Integer>` as input.
- `HandlerDivide.java` – Takes a `List<Integer>` with two integers as input.
- `HandlerStream.java` – Takes an `InputStream` and `OutputStream` as input.
- `HandlerString.java` – Takes a `String` as input.
- `HandlerWeatherData.java` – Takes a custom type as input.

To use a different handler, change the value of the Handler setting in the application template (`template.yml` or `template-mvn.yaml`). For example, to use the list handler:

    Properties:
      CodeUri: build/distributions/java-basic.zip
      Handler: example.HandlerList

Deploy the change, and then use the invoke script to test the new configuration. For handlers, that don't take a JSON object as input, pass the type (`string`, `int`, `list`, or `divide`) as an argument to the invoke script.

    ./3-invoke.sh list
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    9979

# Cleanup
To delete the application, run `4-cleanup.sh`.

    java-basic$ ./4-cleanup.sh



package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

// Handler value: example.HandlerWeatherData
public class HandlerWeatherData implements RequestHandler<WeatherData, WeatherData>{

  @Override
  /*
   * Takes in a WeatherData event object and updates its attributes with dummy values.
   * Returns the updated WeatherData object.
   */
  public WeatherData handleRequest(WeatherData event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());

    event.setHumidityPct(50.5);
    event.setPressureHPa(1005);
    event.setWindKmh(28);
    // Assumes temperature of event is already set
    event.setTemperatureK(event.getTemperatureK() + 2);
    return event;
  }
}


package example;

public class WeatherData {

  private Integer temperatureK;
  private Integer windKmh;
  private Double humidityPct;
  private Integer pressureHPa;

  public Integer getTemperatureK() {
    return temperatureK;
  }

  public void setTemperatureK(Integer temperatureK) {
    this.temperatureK = temperatureK;
  }

  public Integer getWindKmh() {
    return windKmh;
  }

  public void setWindKmh(Integer windKmh) {
    this.windKmh = windKmh;
  }

  public Double getHumidityPct() {
    return humidityPct;
  }

  public void setHumidityPct(Double humidityPct) {
    this.humidityPct = humidityPct;
  }

  public Integer getPressureHPa() {
    return pressureHPa;
  }

  public void setPressureHPa(Integer pressureHPa) {
    this.pressureHPa = pressureHPa;
  }

}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.List;

// Handler value: example.HandlerDivide
public class HandlerDivide implements RequestHandler<List<Integer>, Integer>{
  /*
   * Takes a list of two integers and divides them.
   */
  @Override
  public Integer handleRequest(List<Integer> event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    if ( event.size() != 2 )
    {
      throw new InputLengthException("Input must be an array that contains 2 numbers.");
    }
    int numerator = event.get(0);
    int denominator = event.get(1);
    logger.log("EVENT: Numerator is " + event.get(0).toString() +
      "; Denominator is " + event.get(1).toString());
    return numerator/denominator;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.Map;

// Handler value: example.Handler
public class Handler implements RequestHandler<Map<String,String>, Void>{

  @Override
  public Void handleRequest(Map<String,String> event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass());
    return null;
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

// Handler value: example.HandlerString
public class HandlerString implements RequestHandler<String, String>{

  @Override
  /*
   * Takes a String as input, and converts all characters to lowercase.
   */
  public String handleRequest(String event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    return event.toLowerCase();
  }
}


package example;

import java.lang.RuntimeException;

public class InputLengthException extends RuntimeException { 
    public InputLengthException(String errorMessage) {
        super(errorMessage);
    }
}



// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

public class HandlerStream implements RequestStreamHandler {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void handleRequest(InputStream input, OutputStream output, Context context) throws IOException {
        Order order = objectMapper.readValue(input, Order.class);

        processOrder(order);
        OrderAccepted orderAccepted = new OrderAccepted(order.orderId);

        objectMapper.writeValue(output, orderAccepted);
    }

    private void processOrder(Order order) {
        // business logic
    }

    public record Order(@JsonProperty("orderId") String orderId, @JsonProperty("items") List<Item> items) { }

    public record Item(@JsonProperty("name") String name, @JsonProperty("quantity") Integer quantity) { }

    public record OrderAccepted(@JsonProperty("orderId") String orderId) { }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.List;

// Handler value: example.HandlerList
public class HandlerList implements RequestHandler<List<Integer>, Integer>{

  @Override
  /*
   * Takes a list of Integers and returns its sum.
   */
  public Integer handleRequest(List<Integer> event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    return event.stream().mapToInt(Integer::intValue).sum();
  }
}


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

// Handler value: example.HandlerInteger
public class HandlerInteger implements RequestHandler<Integer, Integer>{

  @Override
  /*
   * Takes an Integer as input, adds 1, and returns it.
   */
  public Integer handleRequest(Integer event, Context context)
  {
    LambdaLogger logger = context.getLogger();
    logger.log("EVENT TYPE: " + event.getClass().toString());
    return event + 1;
  }
}


<Configuration status="WARN">
  <Appenders>
    <Console name="ConsoleAppender" target="SYSTEM_OUT">
      <PatternLayout pattern="%d{YYYY-MM-dd HH:mm:ss} [%t] %-5p %c:%L - %m%n" />
    </Console>
  </Appenders>
  <Loggers>
    <Root level="INFO">
      <AppenderRef ref="ConsoleAppender"/>
    </Root>
  </Loggers>
</Configuration>


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.CognitoIdentity;
import com.amazonaws.services.lambda.runtime.ClientContext;
import com.amazonaws.services.lambda.runtime.LambdaLogger;

public class TestContext implements Context{

  public TestContext() {}
  public String getAwsRequestId(){
    return new String("495b12a8-xmpl-4eca-8168-160484189f99");
  }
  public String getLogGroupName(){
    return new String("/aws/lambda/my-function");
  }
  public String getLogStreamName(){
    return new String("2020/02/26/[$LATEST]704f8dxmpla04097b9134246b8438f1a");
  }
  public String getFunctionName(){
    return new String("my-function");
  }
  public String getFunctionVersion(){
    return new String("$LATEST");
  }
  public String getInvokedFunctionArn(){
    return new String("arn:aws:lambda:us-east-2:123456789012:function:my-function");
  }
  public CognitoIdentity getIdentity(){
    return null;
  }
  public ClientContext getClientContext(){
    return null;
  }
  public int getRemainingTimeInMillis(){
    return 300000;
  }
  public int getMemoryLimitInMB(){
    return 512;
  }
  public LambdaLogger getLogger(){
    return new TestLogger();
  }

}


package example;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.amazonaws.services.lambda.runtime.LambdaLogger;

public class TestLogger implements LambdaLogger {
  private static final Logger logger = LoggerFactory.getLogger(TestLogger.class);
  public void log(String message){
    logger.info(message);
  }
  public void log(byte[] message){
    logger.info(new String(message));
  }
}



package example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import org.junit.jupiter.api.Test;

import com.amazonaws.services.lambda.runtime.Context;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;

class InvokeTest {
  private static final Logger logger = LoggerFactory.getLogger(InvokeTest.class);

  @Test
  void testHandler() {
    logger.info("Invoke TEST - Handler");
    var event = new HashMap<String,String>();
    Context context = new TestContext();
    Handler handler = new Handler();
    assertNull(handler.handleRequest(event, context));
  }

  @Test
  void testHandlerDivide() {
    logger.info("Invoke TEST - HandlerDivide");
    var event = List.of(20, 5);
    Context context = new TestContext();
    HandlerDivide handler = new HandlerDivide();
    assertEquals(4, handler.handleRequest(event, context));
  }

  @Test
  void testHandlerInteger() {
    logger.info("Invoke TEST - HandlerInteger");
    Integer event = 1;
    Context context = new TestContext();
    HandlerInteger handler = new HandlerInteger();
    assertEquals(2, handler.handleRequest(event, context));
  }

  @Test
  void testHandlerList() {
    logger.info("Invoke TEST - HandlerList");
    var event = List.of(1, 2, 3, 4);
    Context context = new TestContext();
    HandlerList handler = new HandlerList();
    assertEquals(10, handler.handleRequest(event, context));
  }

  @Test
    public void testHandlerStream() throws IOException {
        HandlerStream orderProcessor = new HandlerStream();
        String input = """
                {
                    "orderId": "123",
                    "items": [
                        {
                            "name": "widgets",
                            "quantity": 10
                        }
                    ]
                }
                """;
        Context context = null;
        ByteArrayInputStream inputStream = new ByteArrayInputStream(input.getBytes(StandardCharsets.UTF_8));
        OutputStream outputStream = new ByteArrayOutputStream();

        orderProcessor.handleRequest(inputStream, outputStream, context);

        assertEquals("{\"orderId\":\"123\"}", outputStream.toString());
    }

  @Test
  void testHandlerString() {
    logger.info("Invoke TEST - HandlerString");
    String event = "HeLlO wOrLd";
    Context context = new TestContext();
    HandlerString handler = new HandlerString();
    assertEquals("hello world", handler.handleRequest(event, context));
  }

  @Test
  void testHandlerWeatherData() {
    logger.info("Invoke TEST - HandlerWeatherData");
    WeatherData inputData = new WeatherData();
    inputData.setTemperatureK(298);
    Context context = new TestContext();
    HandlerWeatherData handler = new HandlerWeatherData();
    WeatherData outputData = handler.handleRequest(inputData, context);
    assertNotNull(outputData.getHumidityPct());
    assertNotNull(outputData.getPressureHPa());
    assertNotNull(outputData.getWindKmh());
    assertEquals(300, outputData.getTemperatureK());
  }
}



plugins {
    id 'java'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'com.amazonaws:aws-lambda-java-core:1.2.1'
    implementation 'org.slf4j:slf4j-nop:2.0.6'
    implementation 'com.fasterxml.jackson.core:jackson-databind:2.17.0'
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.2'
    testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.2'
}

test {
    useJUnitPlatform()
}

task buildZip(type: Zip) {
    from compileJava
    from processResources
    into('lib') {
        from configurations.runtimeClasspath
    }
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

build.dependsOn buildZip



#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name java-basic --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
if [ $1 ]
then
  case $1 in
    string)
      PAYLOAD='"MYSTRING"'
      ;;

    int | integer)
      PAYLOAD=12345
      ;;

    list)
      PAYLOAD='[24,25,26]'
      ;;

    divide)
      PAYLOAD='[235241,17]'
      ;;

    *)
      echo -n "Unknown event type"
      ;;
  esac
fi
while true; do
  if [ $PAYLOAD ]
  then
    aws lambda invoke --function-name $FUNCTION --payload $PAYLOAD out.json
  else
    aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  fi
  cat out.json
  echo ""
  sleep 2
done



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: build/distributions/java-basic.zip
      Handler: example.Handler
      Runtime: java21
      Description: Java function
      MemorySize: 2048
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
        - AWSLambdaVPCAccessExecutionRole
      Tracing: Active



<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>java-basic</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>java-basic-function</name>
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <java.version>21</java.version>
    <maven.compiler.source>${java.version}</maven.compiler.source>
    <maven.compiler.target>${java.version}</maven.compiler.target>
    <maven.compiler.release>${java.version}</maven.compiler.release>
  </properties>
  <dependencies>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-core</artifactId>
      <version>1.2.1</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-nop</artifactId>
      <version>2.0.6</version>
    </dependency>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>2.17.0</version>
  </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>5.8.2</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>5.8.2</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.2</version>
        <configuration>
          <createDependencyReducedPom>false</createDependencyReducedPom>
          <filters>
            <filter>
                <artifact>*:*</artifact>
                <excludes>
                    <exclude>module-info.class</exclude>
                    <exclude>META-INF/*</exclude>
                    <exclude>META-INF/versions/**</exclude>
                    <exclude>META-INF/services/**</exclude>
                </excludes>
            </filter>
          </filters>
        </configuration>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.8.1</version>
        <configuration>
           <source>11</source>
           <target>11</target>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>


{
  "temperatureK": 281,
  "windKmh": -3,
  "humidityPct": 0.55,
  "pressureHPa": 1020
}



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: target/java-basic-1.0-SNAPSHOT.jar
      Handler: example.Handler
      Runtime: java21
      Description: Java function
      MemorySize: 2048
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
        - AWSLambdaVPCAccessExecutionRole
      Tracing: Active



#!/bin/bash
set -eo pipefail
STACK=java-basic
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf build .gradle target



package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.nio.charset.StandardCharsets;

/**
 * Lambda handler for processing orders and storing receipts in S3.
 */
public class OrderHandler implements RequestHandler<OrderHandler.Order, String> {

    private static final S3Client S3_CLIENT = S3Client.builder().build();

    /**
     * Record to model the input event.
     */
    public record Order(String orderId, double amount, String item) {}

    @Override
    public String handleRequest(Order event, Context context) {
        try {
            // Access environment variables
            String bucketName = System.getenv("RECEIPT_BUCKET");
            if (bucketName == null || bucketName.isEmpty()) {
                throw new IllegalArgumentException("RECEIPT_BUCKET environment variable is not set");
            }

            // Create the receipt content and key destination
            String receiptContent = String.format("OrderID: %s\nAmount: $%.2f\nItem: %s",
                    event.orderId(), event.amount(), event.item());
            String key = "receipts/" + event.orderId() + ".txt";

            // Upload the receipt to S3
            uploadReceiptToS3(bucketName, key, receiptContent);

            context.getLogger().log("Successfully processed order " + event.orderId() +
                    " and stored receipt in S3 bucket " + bucketName);
            return "Success";

        } catch (Exception e) {
            context.getLogger().log("Failed to process order: " + e.getMessage());
            throw new RuntimeException(e);
        }
    }

    private void uploadReceiptToS3(String bucketName, String key, String receiptContent) {
        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            // Convert the receipt content to bytes and upload to S3
            S3_CLIENT.putObject(putObjectRequest, RequestBody.fromBytes(receiptContent.getBytes(StandardCharsets.UTF_8)));
        } catch (S3Exception e) {
            throw new RuntimeException("Failed to upload receipt to S3: " + e.awsErrorDetails().errorMessage(), e);
        }
    }
}



plugins {
    id 'java'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'com.amazonaws:aws-lambda-java-core:1.2.3'
    implementation 'software.amazon.awssdk:s3:2.28.29'
    implementation 'org.slf4j:slf4j-nop:2.0.16'
}

task buildZip(type: Zip) {
    from compileJava
    from processResources
    into('lib') {
        from configurations.runtimeClasspath
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

build.dependsOn buildZip



<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>example-java</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>example-java-function</name>
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>21</maven.compiler.source>
    <maven.compiler.target>21</maven.compiler.target>
  </properties>
  <dependencies>
    <dependency>
        <groupId>com.amazonaws</groupId>
        <artifactId>aws-lambda-java-core</artifactId>
        <version>1.2.3</version>
    </dependency>
    <dependency>
        <groupId>software.amazon.awssdk</groupId>
        <artifactId>s3</artifactId>
        <version>2.28.29</version>
    </dependency>
    <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>slf4j-nop</artifactId>
        <version>2.0.16</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.5.2</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.4.1</version>
        <configuration>
          <createDependencyReducedPom>false</createDependencyReducedPom>
          <filters>
            <filter>
                <artifact>*:*</artifact>
                <excludes>
                    <exclude>META-INF/*</exclude>
                    <exclude>META-INF/versions/**</exclude>
                </excludes>
            </filter>
          </filters>
        </configuration>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.13.0</version>
        <configuration>
           <release>21</release>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>


<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
    <AWSProjectType>Lambda</AWSProjectType>
    <!-- This property makes the build directory similar to a publish directory and helps the AWS .NET Lambda Mock Test Tool find project dependencies. -->
    <CopyLocalLockFileAssemblies>true</CopyLocalLockFileAssemblies>
    <!-- Generate ready to run images during publishing to improve cold start time. -->
    <PublishReadyToRun>true</PublishReadyToRun>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="2.5.0" />
    <PackageReference Include="Amazon.Lambda.Serialization.SystemTextJson" Version="2.4.4" />
    <PackageReference Include="AWSSDK.S3" Version="3.7.415.5" />
  </ItemGroup>
</Project>


using System;
using System.Text;
using System.Threading.Tasks;
using Amazon.Lambda.Core;
using Amazon.S3;
using Amazon.S3.Model;

// Assembly attribute to enable Lambda function logging
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ExampleLambda;

public class Order
{
    public string OrderId { get; set; } = string.Empty;
    public double Amount { get; set; }
    public string Item { get; set; } = string.Empty;
}

public class OrderHandler
{
    private static readonly AmazonS3Client s3Client = new();

    public async Task<string> HandleRequest(Order order, ILambdaContext context)
    {
        try
        {
            string? bucketName = Environment.GetEnvironmentVariable("RECEIPT_BUCKET");
            if (string.IsNullOrWhiteSpace(bucketName))
            {
                throw new ArgumentException("RECEIPT_BUCKET environment variable is not set");
            }

            string receiptContent = $"OrderID: {order.OrderId}\nAmount: ${order.Amount:F2}\nItem: {order.Item}";
            string key = $"receipts/{order.OrderId}.txt";

            await UploadReceiptToS3(bucketName, key, receiptContent);

            context.Logger.LogInformation($"Successfully processed order {order.OrderId} and stored receipt in S3 bucket {bucketName}");
            return "Success";
        }
        catch (Exception ex)
        {
            context.Logger.LogError($"Failed to process order: {ex.Message}");
            throw;
        }
    }

    private async Task UploadReceiptToS3(string bucketName, string key, string receiptContent)
    {
        try
        {
            var putRequest = new PutObjectRequest
            {
                BucketName = bucketName,
                Key = key,
                ContentBody = receiptContent,
                ContentType = "text/plain"
            };

            await s3Client.PutObjectAsync(putRequest);
        }
        catch (AmazonS3Exception ex)
        {
            throw new Exception($"Failed to upload receipt to S3: {ex.Message}", ex);
        }
    }
}



{
  "Information": [
    "This file provides default values for the deployment wizard inside Visual Studio and the AWS Lambda commands added to the .NET Core CLI.",
    "To learn more about the Lambda commands with the .NET Core CLI execute the following command at the command line in the project root directory.",
    "dotnet lambda help",
    "All the command line options for the Lambda command can be specified in this file."
  ],
  "profile": "default",
  "region": "us-east-1",
  "configuration": "Release",
  "function-architecture": "x86_64",
  "function-runtime": "dotnet8",
  "function-memory-size": 512,
  "function-timeout": 30,
  "function-handler": "ExampleCS::ExampleLambda.OrderHandler::HandleRequest"
}


# AWS Lambda Empty Function Project

This starter project consists of:
* Function.cs - class file containing a class with a single function handler method
* aws-lambda-tools-defaults.json - default argument settings for use with Visual Studio and command line deployment tools for AWS

You may also have a test project depending on the options selected.

The generated function handler is a simple method accepting a string argument that returns the uppercase equivalent of the input string. Replace the body of this method, and parameters, to suit your needs. 

## Here are some steps to follow from Visual Studio:

To deploy your function to AWS Lambda, right click the project in Solution Explorer and select *Publish to AWS Lambda*.

To view your deployed function open its Function View window by double-clicking the function name shown beneath the AWS Lambda node in the AWS Explorer tree.

To perform testing against your deployed function use the Test Invoke tab in the opened Function View window.

To configure event sources for your deployed function, for example to have your function invoked when an object is created in an Amazon S3 bucket, use the Event Sources tab in the opened Function View window.

To update the runtime configuration of your deployed function use the Configuration tab in the opened Function View window.

To view execution logs of invocations of your function use the Logs tab in the opened Function View window.

## Here are some steps to follow to get started from the command line:

Once you have edited your template and code you can deploy your application using the [Amazon.Lambda.Tools Global Tool](https://github.com/aws/aws-extensions-for-dotnet-cli#aws-lambda-amazonlambdatools) from the command line.

Install Amazon.Lambda.Tools Global Tools if not already installed.
```
    dotnet tool install -g Amazon.Lambda.Tools
```

If already installed check if new version is available.
```
    dotnet tool update -g Amazon.Lambda.Tools
```

Execute unit tests
```
    cd "ExampleCS/test/ExampleCS.Tests"
    dotnet test
```

Deploy function to AWS Lambda
```
    cd "ExampleCS/src/ExampleCS"
    dotnet lambda deploy-function
```



using Xunit;
using Amazon.Lambda.Core;
using Amazon.Lambda.TestUtilities;

namespace ExampleCS.Tests;

public class FunctionTest
{
    [Fact]
    public void TestToUpperFunction()
    {

        // Invoke the lambda function and confirm the string was upper cased.
        var function = new Function();
        var context = new TestLambdaContext();
        var upperCase = function.FunctionHandler("hello world", context);

        Assert.Equal("HELLO WORLD", upperCase);
    }
}



<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="2.5.0" />
    <PackageReference Include="Amazon.Lambda.TestUtilities" Version="2.0.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.11.1" />
    <PackageReference Include="xunit" Version="2.9.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\ExampleCS\ExampleCS.csproj" />
  </ItemGroup>
</Project>


mkdir python
cp -r create_layer/lib python/
zip -r layer_content.zip python



requests==2.31.0



python3.11 -m venv create_layer
source create_layer/bin/activate
pip install -r requirements.txt



import json
import numpy as np

def lambda_handler(event, context):
    
    x = np.arange(15, dtype=np.int64).reshape(3, 5)
    print(x)
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }



mkdir python
cp -r create_layer/lib python/
zip -r layer_content.zip python


https://files.pythonhosted.org/packages/3a/d0/edc009c27b406c4f9cbc79274d6e46d634d139075492ad055e3d68445925/numpy-1.26.4-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl



python3.11 -m venv create_layer
source create_layer/bin/activate
pip install -r requirements.txt --platform=manylinux2014_x86_64 --only-binary=:all: --target ./create_layer/lib/python3.11/site-packages



import requests

def lambda_handler(event, context):
    print(f"Version of requests library: {requests.__version__}")
    request = requests.get('https://api.github.com/')
    return {
        'statusCode': request.status_code,
        'body': request.text
    }



mkdir -p nodejs/node20
cp -r node_modules nodejs/node20/
zip -r layer_content.zip nodejs



{
  "name": "layer",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "MIT-0",
  "description": "",
  "dependencies": {
    "lodash": "4.17.21"
  }
}



npm install .



import _ from "lodash"

export const handler = async (event) => {
  
  var users = [
  { 'user': 'Carlos',  'active': true },
  { 'user': 'Gil-dong',    'active': false },
  { 'user': 'Pat', 'active': false }
  ];
   
  let out = _.findLastIndex(users, function(o) { return o.user == 'Pat'; });
  const response = {
    statusCode: 200,
    body: JSON.stringify(out + ", " + users[out].user),
  };
  return response;
};



{
  "name": "lambda-typescript-layer-example",
  "version": "1.0.0",
  "main": "dist/index.js",
  "scripts": {
    "prebuild": "rm -rf dist",
    "build": "tsc index.ts --module nodenext --lib es2020 --outDir dist/",
    "postbuild": "cd dist && zip -r index.zip index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "MIT-0",
  "description": "",
  "devDependencies": {
    "@types/aws-lambda": "^8.10.145",
    "@types/lodash": "^4.17.9",
    "lodash": "^4.17.21",
    "typescript": "^5.6.2"
  }
}



import { Handler } from 'aws-lambda';
import * as _ from 'lodash';

type User = {
  user: string;
  active: boolean;
}

type UserResult = {
  statusCode: number;
  body: string;
}

const users: User[] = [
  { 'user': 'Carlos', 'active': true },
  { 'user': 'Gil-dong', 'active': false },
  { 'user': 'Pat', 'active': false }
];

export const handler: Handler<any, UserResult> = async (): Promise<UserResult> => {

  let out = _.findLastIndex(users, (user: User) => { return user.user == 'Pat'; });
  const response = {
    statusCode: 200,
    body: JSON.stringify(out + ", " + users[out].user),
  };
  return response;
};



node_modules
npm-debug.log
package-lock.json
package
*out.yml
out.json
bucket-name.txt
target
build
.gradle
*.zip
bin
obj
Gemfile.lock
lib
__pycache__
*.pyc
.DS_Store



#!/bin/bash
set -eo pipefail
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# Blank function (Node.js)
This sample application is a Lambda function that calls the Lambda API. It shows the use of logging, environment variables, AWS X-Ray tracing, layers, unit tests and the AWS SDK. You can use it to learn about Lambda features or use it as a starting point for your own projects.

![Architecture](/sample-apps/blank-nodejs/images/sample-blank-nodejs.png)

The project source includes function code and supporting resources:

- `function` - A Node.js function.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Variants of this sample application are available for the following languages:

- Python – [blank-python](/sample-apps/blank-python).
- Ruby – [blank-ruby](/sample-apps/blank-ruby).
- Java – [blank-java](/sample-apps/blank-java).
- Go – [blank-go](/sample-apps/blank-go).
- C# – [blank-csharp](/sample-apps/blank-csharp).
- PowerShell – [blank-powershell](/sample-apps/blank-powershell).

Use the following instructions to deploy the sample application. For an in-depth look at its architecture and features, see [Blank Function Sample Application for AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/samples-blank-nodejs.html) in the developer guide.

# Requirements
- [Node.js 18 with npm](https://nodejs.org/en/download/releases/)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/blank-nodejs

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    blank-nodejs$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

To build a Lambda layer that contains the function's runtime dependencies, run `2-build-layer.sh`. Packaging dependencies in a layer reduces the size of the deployment package that you upload when you modify your code.

    blank-nodejs$ ./2-build-layer.sh

# Deploy
To deploy the application, run `3-deploy.sh`.

    blank-nodejs$ ./3-deploy.sh
    added 16 packages from 18 contributors and audited 18 packages in 0.926s
    added 17 packages from 19 contributors and audited 19 packages in 0.916s
    Uploading to e678bc216e6a0d510d661ca9ae2fd941  2737254 / 2737254.0  (100.00%)
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Waiting for stack create/update to complete
    Successfully created/updated stack - blank-nodejs

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

# Test
To invoke the function, run `4-invoke.sh`.

    blank-nodejs$ ./4-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }
    {"AccountLimit":{"TotalCodeSize":80530636800,"CodeSizeUnzipped":262144000,"CodeSizeZipped":52428800,"ConcurrentExecutions":1000,"UnreservedConcurrentExecutions":933},"AccountUsage":{"TotalCodeSize":303678359,"FunctionCount":75}}

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map. The following service map shows the function calling Amazon S3.

![Service Map](/sample-apps/blank-nodejs/images/blank-nodejs-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/blank-nodejs/images/blank-nodejs-trace.png)

Finally, view the application in the Lambda console.

*To view the application*
1. Open the [applications page](https://console.aws.amazon.com/lambda/home#/applications) in the Lambda console.
2. Choose **blank-nodejs**.

  ![Application](/sample-apps/blank-nodejs/images/blank-nodejs-application.png)

# Cleanup
To delete the application, run `5-cleanup.sh`.

    blank-nodejs$ ./5-cleanup.sh
    Deleted blank-nodejs stack.
    Delete deployment artifacts and bucket (lambda-artifacts-4475xmpl08ba7f8d)?y
    delete: s3://lambda-artifacts-4475xmpl08ba7f8d/6f2edcce52085e31a4a5ba823dba2c9d
    delete: s3://lambda-artifacts-4475xmpl08ba7f8d/3d3aee62473d249d039d2d7a37512db3
    remove_bucket: lambda-artifacts-4475xmpl08ba7f8d
    Delete function logs? (log group /aws/lambda/blank-nodejs-function-1RQTXMPLR0YSO)y

The cleanup script delete's the application stack, which includes the function and execution role, and local build artifacts. You can choose to delete the bucket and function logs as well.



{
  "name": "blank-nodejs",
  "version": "1.0.0",
  "private": true,
  "devDependencies": {
    "jest": "29.7.0"
  },
  "dependencies": {
    "@aws-sdk/client-lambda": "3.582.0",
    "aws-xray-sdk-core": "3.6.0"
  },
  "scripts": {
    "test": "jest"
  }
}


#!/bin/bash
set -eo pipefail
STACK=blank-nodejs
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf lib package-lock.json



const AWSXRay = require('aws-xray-sdk-core');
const { LambdaClient, GetAccountSettingsCommand } = require('@aws-sdk/client-lambda');

// Create client outside of handler to reuse
const lambda = AWSXRay.captureAWSv3Client(new LambdaClient());

// Handler
exports.handler = async function(event, context) {
    event.Records.forEach(record => {
        console.log(record.body);
    });

    console.log('## ENVIRONMENT VARIABLES: ' + serialize(process.env));
    console.log('## CONTEXT: ' + serialize(context));
    console.log('## EVENT: ' + serialize(event));

    return getAccountSettings();
};

// Use SDK client
var getAccountSettings = function() {
    return lambda.send(new GetAccountSettingsCommand());
};

var serialize = function(object) {
    return JSON.stringify(object, null, 2);
};


const index = require('./index')
const fs = require('fs')
const AWSXRay = require('aws-xray-sdk-core')
AWSXRay.setContextMissingStrategy('LOG_ERROR')

test('Runs function handler', async () => {
    let eventFile = fs.readFileSync('event.json')
    let event = JSON.parse(eventFile)
    let response = await index.handler(event, null)
    expect(JSON.stringify(response)).toContain('AccountLimit')
  }
)


#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name blank-nodejs --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name blank-nodejs --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
set -eo pipefail
if [ ! -d node_modules ]; then
  echo "Installing libraries..."
  npm install
fi
REGION=$(aws configure get region)
AWS_REGION=$REGION npm run test


AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      Handler: index.handler
      Runtime: nodejs20.x
      CodeUri: function/.
      Description: Call the AWS Lambda API
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
      Tracing: Active
      Layers:
        - !Ref libs
  libs:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: blank-nodejs-lib
      Description: Dependencies for the blank sample app.
      ContentUri: lib/.
      CompatibleRuntimes:
        - nodejs20.x


{
  "Records": [
    {
      "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
      "receiptHandle": "MessageReceiptHandle",
      "body": "Hello from SQS!",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
      "awsRegion": "us-west-2"
    }
  ]
}



#!/bin/bash
set -eo pipefail
mkdir -p lib/nodejs
rm -rf node_modules lib/nodejs/node_modules
npm install --omit=dev
mv node_modules lib/nodejs/


#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
cd src/ec2spot
dotnet lambda package
cd ../../
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name ec2-spot --capabilities CAPABILITY_NAMED_IAM



#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# EC2 spot instance function

![Architecture](/sample-apps/ec2-spot/images/sample-ec2spot.png)

The project source includes function code and supporting resources:

- `src/ec2-spot` - A C# .NET Core function.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `1-create-bucket.sh`, `2-deploy.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application. For more information on the application's architecture and implementation, see [Managing Spot Instance Requests](https://docs.aws.amazon.com/lambda/latest/dg/services-ec2-tutorial.html) in the developer guide.

# Requirements
- [.NET Core SDK 2.1](https://dotnet.microsoft.com/download/dotnet-core/2.1)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/ec2-spot

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    ec2-spot$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

# Deploy
To deploy the application, run `2-deploy.sh`.

    ec2-spot$ ./2-deploy.sh
    Uploading to e678bc216e6a0d510d661ca9ae2fd941  2737254 / 2737254.0  (100.00%)
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Waiting for stack create/update to complete
    Successfully created/updated stack - ec2-spot

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

To invoke the function, run `3-invoke.sh`.

    ec2-spot$ ./3-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map. The following service map shows the function managing spot instances in Amazon EC2.

![Service Map](/sample-apps/ec2-spot/images/sample-ec2spot-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/ec2-spot/images/sample-ec2spot-timeline.png)

Finally, view the application in the Lambda console.

*To view the application*
1. Open the [applications page](https://console.aws.amazon.com/lambda/home#/applications) in the Lambda console.
2. Choose **ec2-spot**.

  ![Application](/sample-apps/ec2-spot/images/sample-ec2spot-application.png)

# Cleanup
To delete the application, run the cleanup script.

    ec2-spot$ ./4-cleanup.sh



using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amazon;
using Amazon.Util;
using Amazon.EC2;
using Amazon.EC2.Model;
using Amazon.Lambda.Core;
using Amazon.XRay.Recorder.Core;
using Amazon.XRay.Recorder.Handlers.AwsSdk;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.Json.JsonSerializer))]

namespace ec2spot
{
    public class Function
    {
        private static AmazonEC2Client ec2Client;

        static Function() {
          AWSSDKHandler.RegisterXRayForAllServices();
          ec2Client = new AmazonEC2Client();
        }

        public async Task<string> FunctionHandler(Dictionary<string, string> input, ILambdaContext context)
        {
          // More AMI IDs: aws.amazon.com/amazon-linux-2/release-notes/
          // us-east-2  HVM  EBS-Backed  64-bit  Amazon Linux 2
          string ami = "ami-09d9edae5eb90d556";
          string sg = "default";
          // docs.aws.amazon.com/sdkfornet/v3/apidocs/items/EC2/TInstanceType.html
          InstanceType type = InstanceType.T3aNano;
          string price = "0.003";
          int count = 1;
          var requestSpotInstances = await RequestSpotInstance(ami, sg, type, price, count);
          var spotRequestId = requestSpotInstances.SpotInstanceRequests[0].SpotInstanceRequestId;
          Console.WriteLine(spotRequestId);

          string instanceId;
          while (true)
          {
            SpotInstanceRequest spotRequest = await GetSpotRequest(spotRequestId);
            Console.WriteLine(spotRequest.State);
            if (spotRequest.State == SpotInstanceState.Active) {
              instanceId = spotRequest.InstanceId;
              break;
            }
          }
          var cancelRequest = CancelSpotRequest(spotRequestId);
          var terminateRequest = TerminateSpotInstance(instanceId);

          await Task.WhenAll(cancelRequest, terminateRequest);

          Console.WriteLine("Complete");
          return spotRequestId;
        }

        public async Task<RequestSpotInstancesResponse> RequestSpotInstance(
          string amiId,
          string securityGroupName,
          InstanceType instanceType,
          string spotPrice,
          int instanceCount)
        {
          var request = new RequestSpotInstancesRequest();

          // https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_RequestSpotLaunchSpecification.html
          var launchSpecification = new LaunchSpecification();
          launchSpecification.ImageId = amiId;
          launchSpecification.InstanceType = instanceType;
          launchSpecification.SecurityGroups.Add(securityGroupName);

          request.SpotPrice = spotPrice;
          request.InstanceCount = instanceCount;
          request.LaunchSpecification = launchSpecification;

          RequestSpotInstancesResponse response =  await ec2Client.RequestSpotInstancesAsync(request);

          return response;
        }
        public async Task<SpotInstanceRequest> GetSpotRequest(string spotRequestId)
        {
          var request = new DescribeSpotInstanceRequestsRequest();
          request.SpotInstanceRequestIds.Add(spotRequestId);

          var describeResponse = await ec2Client.DescribeSpotInstanceRequestsAsync(request);

          return describeResponse.SpotInstanceRequests[0];
        }
        public async Task CancelSpotRequest(string spotRequestId)
        {
          Console.WriteLine("Canceling request " + spotRequestId);
          var cancelRequest = new CancelSpotInstanceRequestsRequest();
          cancelRequest.SpotInstanceRequestIds.Add(spotRequestId);

          await ec2Client.CancelSpotInstanceRequestsAsync(cancelRequest);
        }
        public async Task TerminateSpotInstance(string instanceId)
        {
          Console.WriteLine("Terminating instance " + instanceId);
          var terminateRequest = new TerminateInstancesRequest();
          terminateRequest.InstanceIds = new List<string>() { instanceId };
          try
          {
            var terminateResponse = await ec2Client.TerminateInstancesAsync(terminateRequest);
          }
          catch (AmazonEC2Exception ex)
          {
            // Check the ErrorCode to see if the instance does not exist.
            if ("InvalidInstanceID.NotFound" == ex.ErrorCode)
            {
              Console.WriteLine("Instance {0} does not exist.", instanceId);
            }
            else
            {
              // The exception was thrown for another reason, so re-throw the exception.
              throw;
            }
          }
        }
    }
}



<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netcoreapp2.1</TargetFramework>
    <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
    <AWSProjectType>Lambda</AWSProjectType>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="1.1.0" />
    <PackageReference Include="Amazon.Lambda.Serialization.Json" Version="1.6.0" />
    <PackageReference Include="AWSSDK.Core" Version="3.3.103.32" />
    <PackageReference Include="AWSSDK.EC2" Version="3.3.127.1" />
    <PackageReference Include="AWSXRayRecorder.Core" Version="2.6.0" />
    <PackageReference Include="AWSXRayRecorder.Handlers.AwsSdk" Version="2.7.0" />
  </ItemGroup>
</Project>


﻿{
  "Information" : [
    "This file provides default values for the deployment wizard inside Visual Studio and the AWS Lambda commands added to the .NET Core CLI.",
    "To learn more about the Lambda commands with the .NET Core CLI execute the following command at the command line in the project root directory.",

    "dotnet lambda help",

    "All the command line options for the Lambda command can be specified in this file."
  ],

  "profile":"default",
  "region" : "us-east-2",
  "configuration" : "Release",
  "framework" : "netcoreapp2.1",
  "function-runtime":"dotnetcore2.1",
  "function-memory-size" : 256,
  "function-timeout" : 30,
  "function-handler" : "ec2spot::ec2spot.Function::FunctionHandler"
}



#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name ec2-spot --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload '{"key": "value"}' out.json
  cat out.json
  echo ""
  sleep 2
done



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that uses Amazon EC2 spot instances.
Resources:
  role:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          -
            Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
            Action:
              - sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonEC2FullAccess
        - arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Path: /service-role/
  function:
    Type: AWS::Serverless::Function
    Properties:
      Handler: ec2spot::ec2spot.Function::FunctionHandler
      Runtime: dotnetcore2.1
      CodeUri: src/ec2spot/bin/Release/netcoreapp2.1/ec2spot.zip
      Description: Manage spot instances.
      MemorySize: 256
      Timeout: 9
      Role: !GetAtt role.Arn
      Tracing: Active



using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using Amazon.XRay.Recorder.Core;
using Amazon.XRay.Recorder.Core.Internal.Entities;
using Amazon.XRay.Recorder.Core.Exceptions;
using Amazon.XRay.Recorder.Core.Sampling;
using Amazon.XRay.Recorder.Core.Internal.Context;
using Amazon.XRay.Recorder.Core.Internal.Utils;

using Xunit;
using Amazon.Lambda.Core;
using Amazon.Lambda.TestUtilities;

using ec2spot;

namespace ec2spot.Tests
{
    public class TraceFixture : IDisposable
    {
        private static readonly String _traceHeaderValue = "Root=" + "1-5d66d2fe-8e6fcab805a0833803735bc8" + ";Parent=53995c3f42cd8ad8;Sampled=1";

        public TraceFixture()
        {
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTaskRootKey, "test");
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTraceHeaderKey, _traceHeaderValue);
            Environment.SetEnvironmentVariable("AWS_REGION", "us-east-2");
        }

        public void Dispose()
        {
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTaskRootKey, null);
            Environment.SetEnvironmentVariable(AWSXRayRecorder.LambdaTraceHeaderKey, null);
            Environment.SetEnvironmentVariable("AWS_REGION", null);
        }
    }

    public class FunctionTest : IClassFixture<TraceFixture>
    {
        TraceFixture fixture;

        [Fact]
        public void TestFunction()
        {
            var function = new Function();
            var context = new TestLambdaContext();
            Dictionary<string, string> input = new Dictionary<string, string>();
            input.Add("key", "value");
            var task = function.FunctionHandler(input, context);
            task.Wait(7000);
            bool completed = task.IsCompleted;
            Assert.True(completed);
        }
    }
}



<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netcoreapp2.1</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="1.1.0" />
    <PackageReference Include="Amazon.Lambda.TestUtilities" Version="1.1.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="15.5.0" />
    <PackageReference Include="xunit" Version="2.3.1" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.3.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\ec2spot\ec2spot.csproj" />
  </ItemGroup>
</Project>


#!/bin/bash
set -eo pipefail
STACK=ec2-spot
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf src/ec2-spot/bin src/ec2-spot/obj


#!/bin/bash
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME



# Blank function (Java)

![Architecture](/sample-apps/blank-java/images/sample-blank-java.png)

The project source includes function code and supporting resources:

- `src/main` - A Java function.
- `src/test` - A unit test and helper classes.
- `template.yml` - An AWS CloudFormation template that creates an application.
- `build.gradle` - A Gradle build file.
- `pom.xml` - A Maven build file.
- `1-create-bucket.sh`, `2-build-layer.sh`, etc. - Shell scripts that use the AWS CLI to deploy and manage the application.

Use the following instructions to deploy the sample application.

# Requirements
- An AWS account.
- [Java 8 runtime environment (SE JRE)](https://www.oracle.com/java/technologies/javase-downloads.html)
- [Gradle 5](https://gradle.org/releases/) or [Maven 3](https://maven.apache.org/docs/history.html)
- The Bash shell. For Linux and macOS, this is included by default. In Windows 10, you can install the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to get a Windows-integrated version of Ubuntu and Bash.
- [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) v1.17 or newer.

# Setup
Download or clone this repository.

    $ git clone https://github.com/awsdocs/aws-lambda-developer-guide.git
    $ cd aws-lambda-developer-guide/sample-apps/blank-java

To create a new bucket for deployment artifacts, run `1-create-bucket.sh`.

    blank-java$ ./1-create-bucket.sh
    make_bucket: lambda-artifacts-a5e491dbb5b22e0d

To build a Lambda layer that contains the function's runtime dependencies, run `2-build-layer.sh`. Packaging dependencies in a layer reduces the size of the deployment package that you upload when you modify your code.

    blank-java$ ./2-build-layer.sh

You can also run this commnand with Maven. To use Maven, add `mvn` to the command.

    blank-java$ ./2-build-layer.sh mvn

# Deploy

To deploy the application, run `3-deploy.sh`.

    blank-java$ ./3-deploy.sh
    BUILD SUCCESSFUL in 1s
    Successfully packaged artifacts and wrote output template to file out.yml.
    Waiting for changeset to be created..
    Successfully created/updated stack - blank-java

This script uses AWS CloudFormation to deploy the Lambda functions and an IAM role. If the AWS CloudFormation stack that contains the resources already exists, the script updates it with any changes to the template or function code.

You can also build the application with Maven. To use Maven, add `mvn` to the command.

    java-basic$ ./3-deploy.sh mvn
    [INFO] Scanning for projects...
    [INFO] -----------------------< com.example:blank-java >-----------------------
    [INFO] Building blank-java-function 1.0-SNAPSHOT
    [INFO] --------------------------------[ jar ]---------------------------------
    ...

# Test
To invoke the function, run `4-invoke.sh`.

    blank-java$ ./4-invoke.sh
    {
        "StatusCode": 200,
        "ExecutedVersion": "$LATEST"
    }

Let the script invoke the function a few times and then press `CRTL+C` to exit.

The application uses AWS X-Ray to trace requests. Open the [X-Ray console](https://console.aws.amazon.com/xray/home#/service-map) to view the service map.

![Service Map](/sample-apps/blank-java/images/blank-java-servicemap.png)

Choose a node in the main function graph. Then choose **View traces** to see a list of traces. Choose any trace to view a timeline that breaks down the work done by the function.

![Trace](/sample-apps/blank-java/images/blank-java-trace.png)

Finally, view the application in the Lambda console.

*To view the application*
1. Open the [applications page](https://console.aws.amazon.com/lambda/home#/applications) in the Lambda console.
2. Choose **blank-java**.

  ![Application](/sample-apps/blank-java/images/blank-java-application.png)

# Cleanup
To delete the application, run `5-cleanup.sh`.

    blank$ ./5-cleanup.sh



package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.Map;

import software.amazon.awssdk.services.lambda.LambdaClient;
import software.amazon.awssdk.services.lambda.model.GetAccountSettingsResponse;
import software.amazon.awssdk.services.lambda.model.LambdaException;

// Handler value: example.Handler
public class Handler implements RequestHandler<Map<String,String>, String> {

    private static final LambdaClient lambdaClient = LambdaClient.builder().build();

    @Override
    public String handleRequest(Map<String,String> event, Context context) {

        LambdaLogger logger = context.getLogger();
        logger.log("Handler invoked");

        GetAccountSettingsResponse response = null;
        try {
            response = lambdaClient.getAccountSettings();
        } catch(LambdaException e) {
            logger.log(e.getMessage());
        }
        return response != null ? "Total code size for your account is " + response.accountLimit().totalCodeSize() + " bytes" : "Error";
    }
}



{
  "Records": [
    {
      "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
      "receiptHandle": "MessageReceiptHandle",
      "body": "Hello from SQS!",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "7b270e59b47ff90a553787216d55d91d",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-west-2:123456789012:MyQueue",
      "awsRegion": "us-west-2"
    }
  ]
}



<Configuration status="WARN">
  <Appenders>
    <Console name="ConsoleAppender" target="SYSTEM_OUT">
      <PatternLayout pattern="%d{YYYY-MM-dd HH:mm:ss} [%t] %-5p %c:%L - %m%n" />
    </Console>
  </Appenders>
  <Loggers>
    <Root level="INFO">
      <AppenderRef ref="ConsoleAppender"/>
    </Root>
    <Logger name="software.amazon.awssdk" level="WARN" />
    <Logger name="software.amazon.awssdk.request" level="DEBUG" />
  </Loggers>
</Configuration>


package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.CognitoIdentity;
import com.amazonaws.services.lambda.runtime.ClientContext;
import com.amazonaws.services.lambda.runtime.LambdaLogger;

public class TestContext implements Context{

  public TestContext() {}
  public String getAwsRequestId(){
    return new String("495b12a8-xmpl-4eca-8168-160484189f99");
  }
  public String getLogGroupName(){
    return new String("/aws/lambda/my-function");
  }
  public String getLogStreamName(){
    return new String("2020/02/26/[$LATEST]704f8dxmpla04097b9134246b8438f1a");
  }
  public String getFunctionName(){
    return new String("my-function");
  }
  public String getFunctionVersion(){
    return new String("$LATEST");
  }
  public String getInvokedFunctionArn(){
    return new String("arn:aws:lambda:us-east-2:123456789012:function:my-function");
  }
  public CognitoIdentity getIdentity(){
    return null;
  }
  public ClientContext getClientContext(){
    return null;
  }
  public int getRemainingTimeInMillis(){
    return 300000;
  }
  public int getMemoryLimitInMB(){
    return 512;
  }
  public LambdaLogger getLogger(){
    return new TestLogger();
  }

}


package example;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.amazonaws.services.lambda.runtime.LambdaLogger;

public class TestLogger implements LambdaLogger {
  private static final Logger logger = LoggerFactory.getLogger(TestLogger.class);
  public TestLogger(){}
  public void log(String message){
    logger.info(message);
  }
  public void log(byte[] message){
    logger.info(new String(message));
  }
}



package example;

import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.params.ParameterizedTest;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.tests.annotations.Event;

import java.util.Map;

import com.amazonaws.xray.AWSXRay;
import com.amazonaws.xray.AWSXRayRecorderBuilder;
import com.amazonaws.xray.strategy.sampling.NoSamplingStrategy;

class InvokeTest {

  public InvokeTest() {
      AWSXRayRecorderBuilder builder = AWSXRayRecorderBuilder.standard();
      builder.withSamplingStrategy(new NoSamplingStrategy());
      AWSXRay.setGlobalRecorder(builder.build());
  }

  @ParameterizedTest
  @Event(value = "event.json", type = Map.class)
  void invokeTest(Map<String, String> event) {
      AWSXRay.beginSegment("blank-java-test");
      Context context = new TestContext();
      Handler handler = new Handler();
      String result = handler.handleRequest(event, context);
      assertTrue(result.contains("Total code size for your account"));
      AWSXRay.endSegment();
  }
}



#!/bin/bash
set -eo pipefail
STACK=blank-java
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deleting stack $STACK"
fi
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
aws cloudformation delete-stack --stack-name $STACK
echo "Deleted $STACK stack."

if [ -f bucket-name.txt ]; then
    ARTIFACT_BUCKET=$(cat bucket-name.txt)
    if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
        echo "Bucket was not created by this application. Skipping."
    else
        while true; do
            read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
            case $response in
                [Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
                [Nn]* ) break;;
                * ) echo "Response must start with y or n.";;
            esac
        done
    fi
fi

while true; do
    read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
    case $response in
        [Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done

rm -f out.yml out.json
rm -rf build .gradle target



#!/bin/bash
set -eo pipefail
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name blank-java --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

while true; do
  aws lambda invoke --function-name $FUNCTION --payload fileb://event.json out.json
  cat out.json
  echo ""
  sleep 2
done



<assembly xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.2"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.2 http://maven.apache.org/xsd/assembly-1.1.2.xsd">
    <id>zip</id>
    <includeBaseDirectory>false</includeBaseDirectory>

    <formats>
        <format>zip</format>
    </formats>
	<fileSets>
		<fileSet>
			<directory>${project.build.directory}/classes/java</directory>
			<outputDirectory>java/</outputDirectory>
			<excludes>
				<exclude>example/</exclude>
            </excludes>
		</fileSet>
	</fileSets>
</assembly>


plugins {
    id 'java'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation platform('software.amazon.awssdk:bom:2.10.72')
    implementation platform('com.amazonaws:aws-xray-recorder-sdk-bom:2.4.0')
    implementation 'software.amazon.awssdk:lambda'
    implementation 'com.amazonaws:aws-xray-recorder-sdk-core'
    implementation 'com.amazonaws:aws-lambda-java-core:1.2.1'
    implementation 'com.amazonaws:aws-lambda-java-events:2.2.9'
    implementation 'org.slf4j:slf4j-nop:2.0.6'
    testImplementation 'com.amazonaws:aws-lambda-java-tests:1.1.1'
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.2'
    testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.2'
}

test {
    useJUnitPlatform()
}

task packageFat(type: Zip) {
    from compileJava
    from processResources
    into('lib') {
        from configurations.runtimeClasspath
    }
    dirMode = 0755
    fileMode = 0755
}

task packageLibs(type: Zip) {
    into('java/lib') {
        from configurations.runtimeClasspath
    }
    dirMode = 0755
    fileMode = 0755
}

task packageSkinny(type: Zip) {
    from compileJava
    from processResources
}

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

build.dependsOn packageSkinny



#!/bin/bash
set -eo pipefail
ARTIFACT_BUCKET=$(cat bucket-name.txt)
TEMPLATE=template.yml
if [ $1 ]
then
  if [ $1 = mvn ]
  then
    TEMPLATE=template-mvn.yml
    mvn package
  fi
else
  gradle build -i
fi
aws cloudformation package --template-file $TEMPLATE --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name blank-java --capabilities CAPABILITY_NAMED_IAM



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: build/distributions/blank-java.zip
      Handler: example.Handler::handleRequest
      Runtime: java11
      Description: Java function
      MemorySize: 2048
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
        - AWSLambdaVPCAccessExecutionRole
      Tracing: Active
      Layers:
        - !Ref libs
  libs:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: blank-java-lib
      Description: Dependencies for the blank-java sample app.
      ContentUri: build/blank-java-lib.zip
      CompatibleRuntimes:
        - java11


<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>blank-java</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>blank-java-function</name>
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
  </properties>
  <dependencies>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-core</artifactId>
      <version>1.2.1</version>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-events</artifactId>
      <version>2.2.9</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-nop</artifactId>
      <version>2.0.6</version>
    </dependency>
    <dependency>
      <groupId>software.amazon.awssdk</groupId>
      <artifactId>lambda</artifactId>
      <version>2.10.72</version>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-xray-recorder-sdk-core</artifactId>
      <version>2.4.0</version>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>5.8.2</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>5.8.2</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-tests</artifactId>
      <version>1.1.1</version>
      <scope>test</scope>
  </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.2</version>
        <configuration>
          <createDependencyReducedPom>false</createDependencyReducedPom>
          <filters>
            <filter>
                <artifact>*:*</artifact>
                <excludes>
                    <exclude>module-info.class</exclude>
                    <exclude>META-INF/*</exclude>
                    <exclude>META-INF/versions/**</exclude>
                    <exclude>META-INF/services/**</exclude>
                </excludes>
            </filter>
          </filters>
        </configuration>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <executions>
          <execution>
            <id>copy-dependencies</id>
            <phase>prepare-package</phase>
            <goals>
              <goal>copy-dependencies</goal>
            </goals>
            <configuration>
                <outputDirectory>
                    ${project.build.directory}/classes/java/lib
                </outputDirectory>
                <includeScope>runtime</includeScope>
                <excludeScope>test</excludeScope>
            </configuration>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-assembly-plugin</artifactId>
        <executions>
          <execution>
            <phase>prepare-package</phase>
            <goals>
              <goal>single</goal>
            </goals>
            <configuration>
              <appendAssemblyId>false</appendAssemblyId>
              <descriptors>
                <descriptor>zip.xml</descriptor>
              </descriptors>
            </configuration>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.8.1</version>
        <configuration>
           <source>11</source>
           <target>11</target>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>


{
    "key1": "value1",
    "key2": "value2",
    "key3": "value3"
}



AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: An AWS Lambda application that calls the Lambda API.
Resources:
  function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: target/blank-java-1.0-SNAPSHOT.jar
      Handler: example.Handler::handleRequest
      Runtime: java11
      Description: Java function
      MemorySize: 2048
      Timeout: 10
      # Function's execution role
      Policies:
        - AWSLambdaBasicExecutionRole
        - AWSLambda_ReadOnlyAccess
        - AWSXrayWriteOnlyAccess
        - AWSLambdaVPCAccessExecutionRole
      Tracing: Active
      Layers:
        - !Ref libs
  libs:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: blank-java-lib
      Description: Dependencies for the blank-java sample app.
      ContentUri: target/blank-java-1.0-SNAPSHOT.zip
      CompatibleRuntimes:
        - java11


#!/bin/bash
set -eo pipefail

if [ $1 ]
then
  if [ $1 = mvn ]
  then
    mvn prepare-package
  fi
else
  gradle -q packageLibs
  mv build/distributions/blank-java.zip build/blank-java-lib.zip
fi


Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



# Contributing Guidelines

Thank you for your interest in contributing to our project. We greatly value feedback and contributions from our community.

Please read through this document before submitting any issues or pull requests to ensure we have all the necessary
information to effectively respond to your bug report or contribution.


## Reporting Bugs/Feature Requests

We welcome you to use the GitHub issue tracker to report bugs or suggest features.

When filing an issue, please check existing open, or recently closed, issues to make sure somebody else hasn't already
reported the issue. Please try to include as much information as you can. Details like these are incredibly useful:

* A reproducible test case or series of steps
* The version of our code being used
* Any modifications you've made relevant to the bug
* Anything unusual about your environment or deployment


## Contributing via Pull Requests

Contributions via pull requests are much appreciated. Before sending us a pull request, please ensure that:

1. You are working against the latest source on the *main* branch.
2. You check existing open, and recently merged, pull requests to make sure someone else hasn't addressed the problem already.
3. You open an issue to discuss any significant work - we would hate for your time to be wasted.

To send us a pull request, please:

1. Fork the repository.
2. Modify the source; please focus on the specific change you are contributing. If you also reformat all the code, it will be hard for us to focus on your change.
3. Ensure local tests pass.
4. Commit to your fork using clear commit messages.
5. Send us a pull request, answering any default questions in the pull request interface.
6. Pay attention to any automated CI failures reported in the pull request, and stay involved in the conversation.

GitHub provides additional document on [forking a repository](https://help.github.com/articles/fork-a-repo/) and
[creating a pull request](https://help.github.com/articles/creating-a-pull-request/).


## Finding contributions to work on

Looking at the existing issues is a great way to find something to contribute on. As our projects, by default, use the default GitHub issue labels (enhancement/bug/duplicate/help wanted/invalid/question/wontfix), looking at any 'help wanted' issues is a great place to start.


## Code of Conduct

This project has adopted the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct).
For more information see the [Code of Conduct FAQ](https://aws.github.io/code-of-conduct-faq) or contact
opensource-codeofconduct@amazon.com with any additional questions or comments.


## Security issue notifications

If you discover a potential security issue in this project we ask that you notify AWS/Amazon Security via our [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public github issue.


## Licensing

See the [LICENSE](LICENSE) file for our project's licensing. We will ask you to confirm the licensing of your contribution.

We may ask you to sign a [Contributor License Agreement (CLA)](http://en.wikipedia.org/wiki/Contributor_License_Agreement) for larger changes.



gitdir: ../../../.git/modules/repos/awsdocs/aws-lambda-developer-guide



## AWS Lambda Developer Guide

This repository contains additional resources for the AWS Lambda developer guide.

- [iam-policies](./iam-policies) - Sample permissions policies for cross-service use cases.
- [sample-apps](./sample-apps) - Sample applications that demonstrate features and use cases for the AWS Lambda service and managed runtimes.
- [templates](./templates) - AWS CloudFormation templates for creating functions and VPC network resources.

## License Summary

The sample code within this repo is made available under a modified MIT license. See the [LICENSE](./LICENSE) file.



{
    "java.configuration.updateBuildConfiguration": "interactive"
}


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DDBpermissions1",
            "Effect": "Allow",
            "Action": [
                "dynamodb:DescribeStream",
                "dynamodb:DescribeTable",
                "dynamodb:UpdateTable"
            ],
            "Resource": "arn:aws:dynamodb:us-east-2:123456789012:table/*"
        },
        {
            "Sid": "DDBpermissions2",
            "Effect": "Allow",
            "Action": [
                "dynamodb:ListStreams",
                "dynamodb:ListTables"
            ],
            "Resource": "*"
        },
        {
            "Sid": "LambdaGetPolicyPerm",
            "Effect": "Allow",
            "Action": [
                "lambda:GetPolicy"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        },
        {
            "Sid": "LambdaEventSourcePerms",
            "Effect": "Allow",
            "Action": [
                "lambda:CreateEventSourceMapping",
                "lambda:DeleteEventSourceMapping",
                "lambda:GetEventSourceMapping",
                "lambda:ListEventSourceMappings",
                "lambda:UpdateEventSourceMapping"
            ],
            "Resource": "*"
        }
    ]
}


{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":"logs:CreateLogGroup",
         "Resource":"arn:aws:logs:us-east-2:123456789012:*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "logs:CreateLogStream",
            "logs:PutLogEvents"
         ],
         "Resource":[
            "arn:aws:logs:us-east-2:123456789012:log-group:[[logGroups]]:*"
         ]
      }
   ]
}


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SNSPerms",
            "Effect": "Allow",
            "Action": [
                "sns:ListSubscriptions",
                "sns:ListSubscriptionsByTopic",
                "sns:ListTopics",
                "sns:Subscribe",
                "sns:Unsubscribe"
            ],
            "Resource": "arn:aws:sns:us-east-2:123456789012:*"
        },
        {
            "Sid": "AddPermissionToFunctionPolicy",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:GetPolicy"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        },
        {
            "Sid": "LambdaListESMappingsPerms",
            "Effect": "Allow",
            "Action": [
                "lambda:ListEventSourceMappings"
            ],
            "Resource": "*"
        }
    ]
}



{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeNetworkInterfaces"
      ],
      "Resource": "*"
    }
  ]
}


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ApiGatewayPermissions",
            "Effect": "Allow",
            "Action": [
                "apigateway:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AddPermissionToFunctionPolicy",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:GetPolicy"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        },
        {
            "Sid": "ListEventSourcePerm",
            "Effect": "Allow",
            "Action": [
                "lambda:ListEventSourceMappings"
            ],
            "Resource": "*"
        }
    ]
}



{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":"lambda:InvokeFunction",
         "Resource":"arn:aws:lambda:us-east-2:123456789012:function:my-function*"
      },
      {
         "Effect":"Allow",
         "Action":"kinesis:ListStreams",
         "Resource":"arn:aws:kinesis:us-east-2:123456789012:stream/*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "kinesis:DescribeStream",
            "kinesis:GetRecords",
            "kinesis:GetShardIterator"
         ],
         "Resource":"arn:aws:kinesis:us-east-2:123456789012:stream/myStream"
      }
   ]
}



{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rekognition:ListCollections",
        "rekognition:ListFaces",
        "rekognition:SearchFaces",
        "rekognition:SearchFacesByImage"
      ],
      "Resource": "*"
    }
  ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CloudWatchLogsPerms",
            "Effect": "Allow",
            "Action": [
                "logs:FilterLogEvents",
                "logs:DescribeLogGroups",
                "logs:PutSubscriptionFilter",
                "logs:DescribeSubscriptionFilters",
                "logs:DeleteSubscriptionFilter",
                "logs:TestMetricFilter"
            ],
            "Resource": "arn:aws:logs:us-east-2:123456789012:*"
        },
        {
            "Sid": "AddPermissionToFunctionPolicy",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:GetPolicy"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        },
        {
            "Sid": "ListEventSourceMappingsPerms",
            "Effect": "Allow",
            "Action": [
                "lambda:ListEventSourceMappings"
            ],
            "Resource": "*"
        }
    ]
}


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "IoTperms",
            "Effect": "Allow",
            "Action": [
                "iot:GetTopicRule",
                "iot:CreateTopicRule",
                "iot:ReplaceTopicRule"
            ],
            "Resource": "arn:aws:iot:us-east-2:123456789012:*"
        },
        {
            "Sid": "IoTlistTopicRulePerms",
            "Effect": "Allow",
            "Action": [
                "iot:ListTopicRules"
            ],
            "Resource": "*"
        },
        {
            "Sid": "LambdaPerms",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:GetPolicy"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        }
    ]
}


{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "es:ESHttpPost"
            ],
            "Resource": "*"
        }
    ]
}



{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":"lambda:InvokeFunction",
         "Resource":"arn:aws:lambda:us-east-2:123456789012:function:my-function*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "dynamodb:DescribeStream",
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:ListStreams"
         ],
         "Resource":"arn:aws:dynamodb:us-east-2:123456789012:table/tableName/stream/*"
      }
   ]
}



{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rekognition:CreateCollection",
        "rekognition:IndexFaces"
      ],
      "Resource": "*"
    }
  ]
}



# Lambda console IAM policy examples

The documents in this folder show AWS Identity and Access Management (IAM) policies related to the AWS Lambda console. They show permissions that you need to use the Lambda console, and permissions that the console can add to your function's execution role.

## Console Use Policies

These policies show the user permissions required to configure triggers in the Lambda console.

- console-apigateway.json
- console-cloudwatchevents.json
- console-cloudwatchlogs.json
- console-cognito.json
- console-dynamodb.json
- console-iot.json
- console-kinesis.json
- console-s3.json
- console-sns.json

## Execution Role Templates

These policies show the permissions that the Lambda console adds to your function's execution role when you create a new role from a template.

- template-atedge.json
- template-basic.json
- template-dlq-sns.json
- template-dlq-sqs.json
- template-dynamodb.json
- template-kinesis.json
- template-vpcaccess.json

## Blueprint Policies

These policies show the permissions that the Lambda console adds to your function's execution role when you create a function from a blueprint.

- blueprint-cloudformation.json
- blueprint-ec2ami.json
- blueprint-elasticsearch.json
- blueprint-iotbutton.json
- blueprint-kmsdecrypt.json
- blueprint-microservice.json
- blueprint-rekognition-nodata.json
- blueprint-rekognition-readonly.json
- blueprint-rekognition-writeonly.json
- blueprint-s3get.json
- blueprint-sesbounce.json
- blueprint-sqspoller.json
- blueprint-testharness.json
- blueprint-vpnmonitor.json



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3Permissions",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:GetBucketNotification",
                "s3:PutBucketNotification",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Sid": "AddPermissionToFunctionPolicy",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:RemovePermission"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeRegions",
                "ec2:DescribeVpnConnections"
            ],
            "Resource": "*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:DescribeStacks"
            ],
            "Resource": "*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PermissionForDescribeStream",
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream"
            ],
            "Resource": "arn:aws:kinesis:us-east-2:123456789012:stream/*"
        },
        {
            "Sid": "PermissionForListStreams",
            "Effect": "Allow",
            "Action": [
                "kinesis:ListStreams"
            ],
            "Resource": "*"
        },
        {
            "Sid": "PermissionForGetFunctionPolicy",
            "Effect": "Allow",
            "Action": [
                "lambda:GetPolicy"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        },
        {
            "Sid": "LambdaEventSourcePerms",
            "Effect": "Allow",
            "Action": [
                "lambda:CreateEventSourceMapping",
                "lambda:DeleteEventSourceMapping",
                "lambda:GetEventSourceMapping",
                "lambda:ListEventSourceMappings",
                "lambda:UpdateEventSourceMapping"
            ],
            "Resource": "*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages"
            ],
            "Resource": "*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::*"
        }
    ]
}



{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "arn:aws:sns:us-east-2:123456789012:topicName"
    }
  ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CognitoPerms1",
            "Effect": "Allow",
            "Action": [
                "cognito-identity:ListIdentityPools"
            ],
            "Resource": [
                "arn:aws:cognito-identity:region:account-id:*"
            ]
        },
        {
            "Sid": "CognitoPerms2",
            "Effect": "Allow",
            "Action": [
                "cognito-sync:GetCognitoEvents",
                "cognito-sync:SetCognitoEvents"
            ],
            "Resource": [
                "arn:aws:cognito-sync:region:account-id:*"
            ]
        },
        {
            "Sid": "AddPermissionToFunctionPolicy",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:GetPolicy"
            ],
            "Resource": "arn:aws:lambda:region:account-id:function:*"
        },
        {
            "Sid": "ListEventSourcePerms",
            "Effect": "Allow",
            "Action": [
                "lambda:ListEventSourceMappings"
            ],
            "Resource": "*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sqs:DeleteMessage",
                "sqs:ReceiveMessage"
            ],
            "Resource": "arn:aws:sqs:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:my-function*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "*"
        }
    ]
}



{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Action": [
       "sqs:SendMessage"
     ],
    "Resource": "arn:aws:sqs:us-east-2:123456789012:queueName"
  }
 ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:us-east-2:123456789012:table/*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendBounce"
            ],
            "Resource": "*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EventPerms",
            "Effect": "Allow",
            "Action": [
                "events:PutRule",
                "events:ListRules",
                "events:ListRuleNamesByTarget",
                "events:PutTargets",
                "events:RemoveTargets",
                "events:DescribeRule",
                "events:TestEventPattern",
                "events:ListTargetsByRule",
                "events:DeleteRule"

              ],
            "Resource": "arn:aws:events:us-east-2:123456789012:*"
        },
        {
            "Sid": "AddPermissionToFunctionPolicy",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:GetPolicy"
              ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        }
    ]
}


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem"
            ],
            "Resource": "arn:aws:dynamodb:us-east-2:123456789012:table/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "arn:aws:lambda:us-east-2:123456789012:function:*"
        }
    ]
}



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:ListSubscriptionsByTopic",
                "sns:CreateTopic",
                "sns:SetTopicAttributes",
                "sns:Subscribe",
                "sns:Publish"
            ],
            "Resource": "*"
        }
    ]
}



{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rekognition:CompareFaces",
        "rekognition:DetectFaces",
        "rekognition:DetectLabels"
      ],
      "Resource": "*"
    }
  ]
}



*.DS_Store



*Issue #, if available:*

*Description of changes:*


By submitting this pull request, I confirm that you can use, modify, copy, and redistribute this contribution, under the terms of your choice.



#!/bin/bash
set -eo pipefail
if [[ $# -gt 1 ]]; then
    TEMPLATE_NAME=$1
    shift
    OVERRIDES="$@"
    OVERRIDES_ARG="--parameter-overrides ${OVERRIDES}"
    TEMPLATE=$(cat ${TEMPLATE_NAME}.yml)
elif [[ $# -eq 1 ]]; then
    TEMPLATE_NAME=$1
    TEMPLATE=$(cat ${TEMPLATE_NAME}.yml)
    if [[ "$TEMPLATE" =~ PLACEHOLDER ]]; then
        echo "Usage: ./create-stack.sh <template-name> <parameters>"
        echo "e.g.   ./create-stack.sh my-template parameter=value parameter2=value2"
        exit 0
    fi
else
    echo "Usage: ./create-stack.sh <template-name> <parameters>"
    echo "e.g.   ./create-stack.sh function-inline"
    echo "e.g.   ./create-stack.sh my-template parameter=value parameter2=value2"
    exit 0
fi
STACK_NAME=lambda-${TEMPLATE_NAME}
if [[ "$TEMPLATE" =~ "AWS::IAM::Role" ]]; then
    CAPA_ARG="--capabilities CAPABILITY_NAMED_IAM"
fi
aws cloudformation deploy --template-file ${TEMPLATE_NAME}.yml --stack-name ${STACK_NAME} ${CAPA_ARG} ${OVERRIDES_ARG}


AWSTemplateFormatVersion: '2010-09-09'
Description: An AWS Lambda application that uses the AWS Lambda API.
Resources:
  function:
    Type: AWS::Lambda::Function
    Properties: 
      Code: 
        ZipFile: |
          const AWS = require('aws-sdk')
          // Read environment variable
          let region = process.env.AWS_REGION
          if (process.env.region)
            region = process.env.region
          // Create client outside of handler to reuse
          const lambda = new AWS.Lambda({region: region})

          // Handler
          exports.handler = function(event, context) {
            console.log('Region: ' + region)
            console.log('Event: ' + JSON.stringify(event, null, 2))
            return getAccountSettings()
          }

          // Use SDK client
          var getAccountSettings = function(){
            return lambda.getAccountSettings().promise()
          }
      Description: Blank application function
      Handler: index.handler
      MemorySize: 128
      Role: !GetAtt executionRole.Arn
      Runtime: nodejs16.x
      Timeout: 10
      TracingConfig:
        Mode: Active
  scheduledEvent:
    Type: AWS::Events::Rule
    Properties:
      Description: Scheduled event
      ScheduleExpression: rate(2 minutes)
      State: ENABLED
      Targets:
        - Arn: !GetAtt function.Arn
          Id: Function
  invokePermission:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref function
      Action: lambda:InvokeFunction
      Principal: events.amazonaws.com
      SourceArn: !GetAtt scheduledEvent.Arn
  executionRole:
    Type: AWS::IAM::Role
    Properties:
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess
        - arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole
      Policies:
        - PolicyName: read-lambdasettings
          PolicyDocument:
            Version: 2012-10-17
            Statement:
            - Effect: Allow
              Action: lambda:GetAccountSettings
              Resource: '*'
      AssumeRolePolicyDocument: |
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Action": [
                "sts:AssumeRole"
              ],
              "Effect": "Allow",
              "Principal": {
                "Service": [
                  "lambda.amazonaws.com"
                ]
              }
            }
          ]
        }



AWSTemplateFormatVersion: 2010-09-09
Resources:
  pubPrivateVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 172.31.0.0/16
      Tags:
        - Key: Name
          Value: !Ref AWS::StackName
  publicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref pubPrivateVPC
      AvailabilityZone:
        Fn::Select:
         - 0
         - Fn::GetAZs: ""
      CidrBlock: 172.31.0.0/24
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Join ["-", [!Ref "AWS::StackName","public-subnet"]]
  privateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref pubPrivateVPC
      AvailabilityZone:
        Fn::Select:
         - 0
         - Fn::GetAZs: ""
      CidrBlock: 172.31.3.0/24
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Join ["-", [!Ref "AWS::StackName","private-subnet-a"]]
  privateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref pubPrivateVPC
      AvailabilityZone:
        Fn::Select:
         - 1
         - Fn::GetAZs: ""
      CidrBlock: 172.31.2.0/24
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Join ["-", [!Ref "AWS::StackName","private-subnet-b"]]
  internetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Join ["-", [!Ref "AWS::StackName","gateway"]]
  gatewayToInternet:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref pubPrivateVPC
      InternetGatewayId: !Ref internetGateway
  publicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref pubPrivateVPC
  publicRoute:
    Type: AWS::EC2::Route
    DependsOn: gatewayToInternet
    Properties:
      RouteTableId: !Ref publicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref internetGateway
  publicSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref publicSubnet1
      RouteTableId: !Ref publicRouteTable
  natGateway:
    Type: AWS::EC2::NatGateway
    DependsOn: natPublicIP
    Properties:
      AllocationId: !GetAtt natPublicIP.AllocationId
      SubnetId: !Ref publicSubnet1
  natPublicIP:
    Type: AWS::EC2::EIP
    DependsOn: pubPrivateVPC
    Properties:
      Domain: vpc
  privateRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref pubPrivateVPC
  privateRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref privateRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref natGateway
  privateSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref privateSubnet1
      RouteTableId: !Ref privateRouteTable
  privateSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref privateSubnet2
      RouteTableId: !Ref privateRouteTable
  s3Endpoint:
    Type: AWS::EC2::VPCEndpoint
    Properties:
      PolicyDocument:
        Version: 2012-10-17
        Statement:
        - Effect: Allow
          Principal: "*"
          Action:
            - "s3:*"
          Resource:
            - "*"
      RouteTableIds:
        - !Ref privateRouteTable
      ServiceName: !Sub com.amazonaws.${AWS::Region}.s3
      VpcId: !Ref pubPrivateVPC
  dynamoDBEndpoint:
    Type: AWS::EC2::VPCEndpoint
    Properties:
      PolicyDocument:
        Version: 2012-10-17
        Statement:
        - Effect: Allow
          Principal: "*"
          Action:
            - "dynamodb:*"
          Resource:
            - "*"
      RouteTableIds:
        - !Ref privateRouteTable
      ServiceName: !Sub com.amazonaws.${AWS::Region}.dynamodb
      VpcId: !Ref pubPrivateVPC
Outputs:
  pubPrivateVPCID:
    Description: VPC ID
    Value: !Ref pubPrivateVPC
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","vpc"]]
  publicSubnet1ID:
    Description: Public Subnet A ID
    Value: !Ref publicSubnet1
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","public-subnet-a"]]
  privateSubnet1ID:
    Description: Private Subnet A ID
    Value: !Ref privateSubnet1
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","private-subnet-a"]]
  privateSubnet2ID:
    Description: Private Subnet B ID
    Value: !Ref privateSubnet2
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","private-subnet-b"]]
  privateVPCSecurityGroup:
    Description: Default security for Lambda VPC
    Value: !GetAtt pubPrivateVPC.DefaultSecurityGroup
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","vpc-sg"]]





AWSTemplateFormatVersion: 2010-09-09
Resources:
  privateVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 172.31.0.0/16
      Tags:
        - Key: Name
          Value: !Ref AWS::StackName
  privateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref privateVPC
      AvailabilityZone:
        Fn::Select:
         - 0
         - Fn::GetAZs: ""
      CidrBlock: 172.31.3.0/24
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Join ["-", [!Ref "AWS::StackName","subnet-a"]]
  privateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref privateVPC
      AvailabilityZone:
        Fn::Select:
         - 1
         - Fn::GetAZs: ""
      CidrBlock: 172.31.2.0/24
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Join ["-", [!Ref "AWS::StackName","subnet-b"]]
  privateRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref privateVPC
  privateSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref privateSubnet1
      RouteTableId: !Ref privateRouteTable
  privateSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref privateSubnet2
      RouteTableId: !Ref privateRouteTable
  s3Endpoint:
    Type: AWS::EC2::VPCEndpoint
    Properties:
      PolicyDocument:
        Version: 2012-10-17
        Statement:
        - Effect: Allow
          Principal: "*"
          Action:
            - "s3:*"
          Resource:
            - "*"
      RouteTableIds:
        - !Ref privateRouteTable
      ServiceName: !Sub com.amazonaws.${AWS::Region}.s3
      VpcId: !Ref privateVPC
  dynamoDBEndpoint:
    Type: AWS::EC2::VPCEndpoint
    Properties:
      PolicyDocument:
        Version: 2012-10-17
        Statement:
        - Effect: Allow
          Principal: "*"
          Action:
            - "dynamodb:*"
          Resource:
            - "*"
      RouteTableIds:
        - !Ref privateRouteTable
      ServiceName: !Sub com.amazonaws.${AWS::Region}.dynamodb
      VpcId: !Ref privateVPC
Outputs:
  privateVPCID:
    Description: VPC ID
    Value: !Ref privateVPC
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","vpc"]]
  privateSubnet1ID:
    Description: Private Subnet A ID
    Value: !Ref privateSubnet1
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","subnet-a"]]
  privateSubnet2ID:
    Description: Private Subnet B ID
    Value: !Ref privateSubnet2
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","subnet-b"]]
  privateVPCSecurityGroup:
    Description: Default security for Lambda VPC
    Value: !GetAtt privateVPC.DefaultSecurityGroup
    Export:
      Name: !Join ["-", [!Ref "AWS::StackName","vpc-sg"]]


#!/bin/bash
set -eo pipefail
if [[ $# -eq 1 ]]; then
    TEMPLATE_NAME=$1
else
    echo "Usage: ./delete-stack.sh <template-name>"
    echo "e.g.   ./delete-stack.sh function-inline"
    exit 0
fi
STACK_NAME=lambda-${TEMPLATE_NAME}
while true; do
    read -p "Delete stack ${STACK_NAME}? (y/n)" response
    case $response in
        [Yy]* ) aws cloudformation delete-stack --stack-name ${STACK_NAME}; break;;
        [Nn]* ) break;;
        * ) echo "Response must start with y or n.";;
    esac
done


