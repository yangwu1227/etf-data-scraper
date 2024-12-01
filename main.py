import os
from datetime import datetime

from src.api import query_etf_data
from src.utils import setup_logger, write_to_s3


def main() -> int:
    logger = setup_logger(name="ETF KPIs Scraper")

    ENV = os.getenv("ENV", "dev")
    logger.info(f"Running the task in {ENV} mode")

    # If in 'dev' mode, specify a smaller number of etfs to query for testing purposes
    if ENV == "dev":
        max_etfs = 20
    elif ENV == "prod":
        max_etfs = int(os.getenv("MAX_ETFS", 1))
    ipo_date = datetime.strptime(
        os.getenv("IPO_DATE", datetime.today().strftime("%Y-%m-%d")), "%Y-%m-%d"
    )
    etfs_data = query_etf_data(logger=logger, max_etfs=max_etfs, ipo_date=ipo_date)

    s3_bucket = os.getenv("S3_BUCKET")
    parquet = os.getenv("PARQUET") == "True"
    s3_path = (
        f"s3://{s3_bucket}/daily-kpis/etf_kpis_{datetime.today().strftime('%Y_%m_%d')}"
    )
    logger.info("Writing scraper data to s3")
    paths = write_to_s3(data=etfs_data, s3_path=s3_path, parquet=parquet)
    logger.info(
        f"Successfully written data to {paths['paths'][0]} as a {'parquet' if parquet else 'csv'} file"
    )

    return 0


if __name__ == "__main__":
    main()
