import json
import boto3
import dateutil.tz
from datetime import datetime

def lambda_handler(event, context):
    print(event)

    # Get Region name
    region = event['region']
    client = boto3.client('ssm')
    response = client.get_parameter(
        Name=f'/aws/service/global-infrastructure/regions/{region}/longName'
    )
    region_name = response['Parameter']['Value']

    # Get Time in MMT
    time = event['time']
    tz = dateutil.tz.gettz('Asia/Yangon')
    d = datetime.fromisoformat(time[:-1]).astimezone(tz)
    dt = d.strftime('%b %d, %Y %-I:%M:%S %p MMT')

    message = ''
    if event['detail-type'] == 'EC2 Spot Fleet Instance Change':
        instance_id = event['detail']['instance-id']
        instance_name = get_instance_name(instance_id)
        
        description = json.loads(event['detail']['description'])
        instance_type = description['instanceType']
        instance_az = description['availabilityZone']
        sub_type = event['detail']['sub-type']

        message = f"Event: {sub_type} \nInstance Name: {instance_name} \nInstance ID: {instance_id} \nType: {instance_type} \nTime: {dt} \nRegion: {region_name} \nAvailability Zone: {instance_az}"

    elif event['detail-type'] == 'EC2 Spot Instance Interruption Warning':
        instance_id = event['detail']['instance-id']
        instance_name = get_instance_name(instance_id)

        instance_action = event['detail']['instance-action']
        message = f"Event: Spot Instance Interruption Warning \nInstance Name: {instance_name} \nInstance ID: {instance_id} \nAction: {instance_action} \nTime: {dt} \nRegion: {region_name}"

    elif event['detail-type'] == 'EC2 Instance Rebalance Recommendation':
        instance_id = event['detail']['instance-id']
        instance_name = get_instance_name(instance_id)
        message = f"Event: Instance Rebalance Recommendation \nInstance Name: {instance_name} \nInstance ID: {instance_id} \nTime: {dt} \nRegion: {region_name}"

    elif event['detail-type'] == 'CodePipeline Pipeline Execution State Change':
        pipeline_name = event['detail']['pipeline']
        state = event['detail']['state']
        eid = event['detail']['execution-id']

        message = f"Pipeline Name: {pipeline_name} \nState: {state} \nExecution ID: {eid} \nRegion: {region_name} \nTime: {dt}"

    else:
        description = event['detail']['description']
        sub_type = event['detail']['sub-type']
        message = f"Region: {region_name} \nTime: {dt} \nDescription: {description} \nEvent: {sub_type}"
        
    sns = boto3.client('sns')
    sns.publish(
        TopicArn = '{{TOPIC_ARN}}',
        Subject = event['detail-type'],
        Message = message
    )
    return {
        'statusCode': 200,
        'body': json.dumps('Sent a message to an Amazon SNS topic'),
        'message': json.dumps(message)
    }

def get_instance_name(fid):
    """
        When given an instance ID as str e.g. 'i-1234567', return the instance 'Name' from the name tag.
        :param fid:
        :return:
    """
    print(fid)
    client = boto3.client('ec2')
    response = client.describe_tags(
        Filters=[
            {
                'Name': 'resource-id',
                'Values': [
                    fid
                ]
            },
            {
                'Name': 'resource-type',
                'Values': [
                    'instance'
                ]
            },
            {
                'Name': 'key',
                'Values': [
                    'Name'
                ]
            },
        ]
    )
    print(response)
    tags = response['Tags']
    instance_name = ''
    if len(tags) > 0: instance_name = tags[0]['Value']
    print(instance_name)
    return instance_name
