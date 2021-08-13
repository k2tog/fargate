# ECS Status Function

A simple function build on AWS lambda in pythin 3.6.

## Function

The service reports on current ECS FARGATE services (ie status is 'ACTIVE')

- the service can be queried from a public URL.
- the public URL is created by AWS API Gateway during deployment process.
- http://..URL../`list` should respond with the list of all current services.
- http://..URL../`list?key=value` should respond with the tagged service details.
  - valid keys are: `environment`, `owner`, `contact`
- informtion returned is: 
  * service name 
  * the number of ecs services that are currently running 
  * the number of ecs services that pending 
  * tags

The response format is JSON.

## Deployment

Full Infrastructure as Code written in terraform 0.12 provided that

- creates VPC with internet gateway and security setup.
- creates ECS Fargate cluster in VPC with 1 task running docker image helloworld.
- provisions lambda service, creates API Gateway and publishes endpoint.

All resources are tagged with `environment`, `owner`, `contact`

#### To deploy:

Using terraform 12.

`terraform init`  
`terraform apply`

The API endpoint will be found via the console at API Gateway > frankie > stages > k2tog

#### Prerequisite:  
A role with update permissions for Lambda, IAM, API Gateway, EC2, ECS and VPC:  
For this coding challenge - the terraform was tested using AWS managed policy:

- AWSLambdaFullAccess
- IAMFullAccess
- AmazonAPIGatewayInvokeFullAccess
- AmazonAPIGatewayAdministrator
- AmazonECS_FullAccess
- AmazonVPCFullAccess


#### Setup:
The terraform can be modified easily to deploy different containers or lambda code.
- the environment name for this coding challenge is `frankie` 
- review and update the variables.tf in terraform > environments > frankie
- particuarly update the `credentials file location`
- to use a different docker image
  - create a new .json & save under 'modules > ecs'
  - change the environment > variables > ecs_task_image to the new name
- to use different python code
  - add the code to 'modules > api_lambda'
  - change the environment > variables > lambda_name to the new name



#### Testing Using the Provided ECS Cluster IaC

| URL | expected result
| -- | --
| http:// API endpoint /list | should return cluster list (of 1 cluster, 1 service)
| http:// API endpoint /list?owner=F1 | should return empty list  
| http:// API endpoint /list?owner=K2 | should return cluster list including the k2tog cluster

---

TO DO 

1. Publically accessible URL.  
   API Gateway created through terraform is getting "access denied" issues to lambda
   Creating same gateway via console (or even adding new method) add required permissions.

2. Report filter AWS Fargate services.  
   The describe_clusters is returning 'capacityProviders': []  
   Instead of the expected 'capacityProviders': ['FARGATE']  
   However creating from console 'capacityProviders': ['FARGATE_SPOT', 'FARGATE'].

WOULD DO if doing this for real / production

- Additional logging included in Lambda.
- Public URL http://hostname/ should respond with a help message.
- Allow multiple services/tasks/containers from single ECS module.
- Granular IAM permissions.
- Use proper environment names and tags - like `production`, `staging` etc

NOT DONE

- How to build - used python so no build required.
- Auotmated testing - used lambda not native python.
- Using ECR or other repository - pulled small image from dockerhub.
- Small increments and regular pushes - was testing locally.
