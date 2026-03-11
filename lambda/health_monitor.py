import boto3
import urllib.request
import json
import os

def handler(event, context):
    endpoint = os.environ.get('HEALTH_ENDPOINT')
    sns_arn = os.environ.get('SNS_TOPIC_ARN')

    try:
        with urllib.request.urlopen(endpoint, timeout=5) as r:
            status = r.status
            body = json.loads(r.read())
    except Exception as e:
        status = 0
        body = {'error': str(e)}

    if status != 200:
        sns = boto3.client('sns')
        sns.publish(
            TopicArn=sns_arn,
            Subject='PULSE HEALTH CHECK FAILED',
            Message=f'Status: {status}\nResponse: {body}\nEndpoint: {endpoint}'
        )
        return {'statusCode': 500, 'body': 'unhealthy'}

    return {'statusCode': 200, 'body': 'healthy'}