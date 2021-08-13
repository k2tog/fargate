import sys
import json
import boto3


def lambda_handler(event, context):
    
    # set flag to filter on tags, when tags are provided
    checkTag = False
    if "owner" in event or "environment" in event or "contact" in event:
        checkTag = True

    # variables are here for future resizing if required
    max_items = 10
    page_size = 10

    # initialising iteration variables
    token = None
    result = {}
    i = 0
    
    # instantiating the ecs client
    client = boto3.client('ecs')

    # loops until no more nextToken for further pages - the catch ends this loop     
    while True:
        # loop through all clusters on account
        paginator = client.get_paginator('list_clusters')
        cluster_list = paginator.paginate(
            PaginationConfig={
                'MaxItems': max_items,
                'PageSize': page_size,
                'StartingToken': token
            })
    
        # for each cluster - obtain the description including tags
        for cluster in cluster_list:
            for cluster_arn in cluster['clusterArns']:
                description = client.describe_clusters(
                    clusters=[cluster_arn],
                    include=['TAGS'])
    
                # return the cluster desciption only when the criteria are met:
                # - cluster is 'ACTIVE'
                # - ECS capacity provider is type 'FARGATE'
                # - return only services with the tag if provided in input 
                for stat in description['clusters']:
                    #if stat['status'] == 'ACTIVE' and 'FARGATE' in stat['capacityProviders']: 
                    if stat['status'] == 'ACTIVE':     
                        stats = {}
                        stats['ECS cluster name'] = stat['clusterName']
                        stats['number of services running'] = stat['runningTasksCount']
                        stats['number of services pending'] = stat['pendingTasksCount']
                        stats['tags on ECS cluster'] = stat['tags']
                        
                        # when tags are provided, filter on matching tags
                        returnStats = True
                        if checkTag:
                            returnStats = False
                            tagset = stat['tags']
                            for t in tagset:
                                for e in event:
                                    if event[e] == t['value']:
                                        returnStats = True
    
                        if returnStats:                  
                            i += 1
                            result[i] = stats

        try:
            token = cluster['nextToken']
        except KeyError:
            break

    responseObject = {}
    responseObject['statusCode'] = 200
    responseObject['headers'] = {}
    responseObject['headers']['contentType'] = 'application/json'
    responseObject['body'] = json.dumps(result)

    return responseObject