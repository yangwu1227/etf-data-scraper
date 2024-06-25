import logging
import sys
from typing import Dict, List

import awswrangler as wr
import boto3
import pandas as pd

def setup_logger(name: str) -> logging.Logger:
    """
    Set up a logger with the specified name. If a handler is already attached, it won't add another.

    Parameters
    ----------
    name : str
        The name of the logger

    Returns
    -------
    logging.Logger
        A logger instance
    """
    logger = logging.getLogger(name)  # Return a logger with the specified name

    if not logger.hasHandlers():
        handler = logging.StreamHandler(sys.stdout)
        formatter = logging.Formatter('%(asctime)s %(levelname)s %(name)s: %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)

    logger.setLevel(logging.INFO)
    
    return logger

def write_to_s3(data: pd.DataFrame, s3_path: str, parquet: bool = True) -> Dict[str, List[str]]:
    """
    Save the input data to s3 either as a parquet file or csv file.

    Parameters
    ----------
    data : pd.DataFrame
        Data Frame to be saved
    s3_path : str
        Full s3 url, excluding the file extension
    parquet : bool, optional
        `True` for parquet or `False` for csv

    Returns
    -------
    Dict[str, List[str]]
        A dictionary containing list of all store objects paths
    """
    if parquet:
        s3_path += '.parquet'
        path = wr.s3.to_parquet(df=data, path=s3_path)
    else:
        s3_path += '.csv'
        path = wr.s3.to_csv(df=data, path=s3_path)

    return path
