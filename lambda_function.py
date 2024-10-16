import logging
import os
from typing import Any, Dict

import boto3
import botocore
from mypy_boto3_ecs import ECSClient

ecs_client: ECSClient = boto3.client("ecs")
logger = logging.getLogger(name="Trigger ECS Fargate Task")
logger.setLevel(logging.INFO)


def lambda_handler(event: Dict[str, str], context: Any) -> None:
    try:
        env = os.getenv("env")
        # If 'env' is passed in as part of the event payload, e.g. {"env": "dev"}, use that value
        if "env" in event:
            env = event["env"]

        # Cluster name is required to know where to run the task
        cluster_name = os.getenv("ECS_CLUSTER_NAME")
        # Task definition specifies the Docker image and container settings
        task_definition = os.getenv("ECS_TASK_DEFINITION")
        # Container name is required to override the environment variable
        container_name = os.getenv("ECS_CONTAINER_NAME")
        # Subnet IDs and security group are required for network configuration
        subnet_1 = os.getenv("SUBNET_1")
        subnet_2 = os.getenv("SUBNET_2")
        security_group = os.getenv("SECURITY_GROUP")
        # Disabled when running in a private subnet with NAT Gateway or Enabled when running in a public subnet
        assign_public_ip = os.getenv("ASSIGN_PUBLIC_IP")
        # Get the latest revision of the task definition
        version = ecs_client.describe_task_definition(taskDefinition=task_definition)[
            "taskDefinition"
        ]["revision"]

        response = ecs_client.run_task(
            cluster=cluster_name,
            launchType="FARGATE",
            count=1,
            taskDefinition=f"{task_definition}:{version}",
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": [subnet_1, subnet_2],
                    "securityGroups": [security_group],
                    "assignPublicIp": assign_public_ip,
                }
            },
            overrides={
                "containerOverrides": [
                    {
                        # The container we wish to override the environment variable
                        "name": container_name,
                        # This defaults to 'prod' but can be overridden by passing 'dev' to the Lambda function for testing purposes
                        "environment": [{"name": "ENV", "value": env}],
                    }
                ]
            },
        )

        logger.info(f"Task started with taskArn: {response}")

    except Exception as error:
        logger.error(f"An error occurred while starting the task: {error}")
        raise error

    except botocore.exceptions.ParamValidationError as error:
        logger.error(
            f"The parameters passed to the `run_task` method are invalid: {error}"
        )
        raise error

    return None
