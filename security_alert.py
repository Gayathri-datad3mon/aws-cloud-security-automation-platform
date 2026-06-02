import json
import boto3
import os

sns = boto3.client("sns")

def lambda_handler(event, context):

    detail = event.get("detail", {})

    actor = detail.get("userIdentity", {}).get("userName", "Unknown")
    action = detail.get("eventName", "Unknown")
    source_ip = detail.get("sourceIPAddress", "Unknown")

    target = "N/A"

    if "requestParameters" in detail:
        target = detail["requestParameters"].get("userName", "N/A")

    message = f"""
SECURITY ALERT

Event: {action}

Actor: {actor}

Target User: {target}

Source IP: {source_ip}

Region: {detail.get('awsRegion', 'Unknown')}

Risk Level: Medium

Recommended Action:
Verify the activity was authorized.
"""

    print(message)

    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Subject=f"Security Alert - {action}",
        Message=message
    )

    return {
        "statusCode": 200,
        "body": message
    }
