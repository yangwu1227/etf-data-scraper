import argparse
import json
import os
from typing import Dict, Union
from copy import deepcopy

import boto3
from botocore.exceptions import ClientError, ParamValidationError
from botocore.client import BaseClient

from src.utils import setup_logger

def load_parameters(template_file: str, parameters_file: str) -> Dict[str, Union[str, int]]:
    """
    Load the parameters for a CloudFormation stack from a JSON file.

    Parameters
    ----------
    template_file : str
        The file path of the CloudFormation template YAML
    parameters_file : str
        The file path of the stack parameters JSON file

    Returns
    -------
    Dict[str, Union[str, int]]
        The parameters for the CloudFormation stack as a dictionary

    Raises
    ------
    ValueError
        If the template key is not found in the parameters file
    """
    with open(parameters_file, 'r') as file:
        parameters = json.load(file)
    # This assumes that the template file 'xxx.yaml' is in the parameters json file
    template_key = os.path.basename(template_file)
    if template_key not in parameters:
        raise ValueError(f"No parameters found for template: {template_key}")
    return parameters[template_key]

def create_stack(client: BaseClient, template_file: str, parameters: str) -> Dict[str, str]:
    """
    Create a CloudFormation stack based on a template and parameters.

    Parameters
    ----------
    client : botocore.client.BaseClient
        The CloudFormation client
    template_file : str
        The file path of the CloudFormation template YAML
    parameters : Dict[str, Union[str, int]]
        The parameters for the CloudFormation stack

    Returns
    -------
    Dict[str, str]
        The response from the `create_stack` API call, which is just `{'StackId': 'string'}`

    Raises
    ------
    ClientError
        If the create_stack API call fails
    ValueError
        If the create_stack API call returns an invalid parameter error
    """
    with open(template_file, 'r') as file:
        template_body = file.read()
    
    # Create a copy of the parameters dictionary and pop the StackName key
    parameters = deepcopy(parameters)
    stack_name = parameters.pop('StackName')
    stack_parameters = [{'ParameterKey': param_key, 'ParameterValue': str(param_value)} for param_key, param_value in parameters.items()]

    try:
        response = client.create_stack(
            StackName=stack_name,
            TemplateBody=template_body,
            Parameters=stack_parameters,
            # These are needed only for the IAM template, but they don't hurt for other templates
            Capabilities=['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM']
        )
        return response
    except ClientError as client_error:
        raise client_error
    except ParamValidationError as param_error:
        raise ValueError(f"Invalid parameter to the create_stack API: {param_error}")

def get_stack_outputs(client: BaseClient, stack_name: str) -> Dict[str, Union[str, int]]:
    """
    Get the key-value exported outputs from a CloudFormation stack just created.

    Parameters
    ----------
    client : botocore.client.BaseClient
        The CloudFormation client
    stack_name : str
        The name of the CloudFormation stack

    Returns
    -------
    Dict[str, Union[str, int]]
        The outputs of the CloudFormation stack as a dictionary

    Raises
    ------
    ClientError
        If the describe_stacks API call fails
    ValueError
        If the describe_stacks API call returns an invalid parameter error
    """
    try:
        response = client.describe_stacks(StackName=stack_name)
        # The response structure: https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/cloudformation/client/describe_stacks.html
        stack = response['Stacks'][0]
        outputs = {output['OutputKey']: output['OutputValue'] for output in stack.get('Outputs', [])}
        return outputs
    except ClientError as client_error:
        raise client_error
    except ParamValidationError as param_error:
        raise ValueError(f"Invalid parameter to the describe_stacks API: {param_error}")

def main() -> int:

    logger = setup_logger(name="Deploy Stack")
    parser = argparse.ArgumentParser(description="Create a CloudFormation stack and optionally save outputs to a JSON file")
    parser.add_argument("--template_file", help="The file path of the CloudFormation template YAML")
    parser.add_argument("--parameters_file", help="The file path of the stack parameters JSON file")
    parser.add_argument("--save_outputs", action="store_true", help="Whether to save the outputs as a JSON file")
    args, _ = parser.parse_known_args()

    logger.info(f"Deploying stack with template file: {args.template_file} and parameters file: {args.parameters_file}")
    parameters = load_parameters(args.template_file, args.parameters_file)

    logger.info(f"Creating stack with parameters: {parameters}")
    client = boto3.client('cloudformation')
    create_stack(client, args.template_file, parameters)
    stack_name = parameters['StackName']
    print(f"Stack creation initiated: {stack_name}")
    # Wait for stack creation to complete
    waiter = client.get_waiter('stack_create_complete')
    try:
        waiter.wait(StackName=stack_name)
    except ClientError as client_error:
        logger.error(f"Error while waiting for stack creation: {client_error}")
        return 1

    logger.info(f"Getting outputs for stack: {stack_name}")
    outputs = get_stack_outputs(client, stack_name)
    if outputs is None:
        logger.info("No outputs found for the stack")
        return 0

    if args.save_outputs:
        # Create a template output directory if it doesn't exist in the current working directory
        output_dir = os.path.join(os.getcwd(), "stack_outputs")
        os.makedirs(output_dir, exist_ok=True)
        output_file = os.path.join(output_dir, f"{stack_name}_outputs.json")
        with open(output_file, 'w') as file:
            json.dump(outputs, file, indent=4)
        logger.info(f"Outputs saved to file: {output_file}")
    else:
        logger.info("Outputs:")
        logger.info(json.dumps(outputs, indent=4))

    return 0

if __name__ == "__main__":

    main()
