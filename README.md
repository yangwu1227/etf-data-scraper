# ETF Data Scraper

This is a Python 3 based daily scraper that collects data on actively listed ETFs using the [Alpha Vantage](https://www.alphavantage.co/#page-top) and [Yahoo Finance](https://finance.yahoo.com/) APIs (via the [yfinance](https://pypi.org/project/yfinance/) package).

The infrasturcture of the scraper includes:

* **Amazon EventBridge**: Triggers a Lambda function to run daily at 5:00 PM EST / 4:00 PM CST on weekdays after the market closes.
* **AWS Lambda**: Starts an AWS Fargate task, which runs the containerized application code.
* **AWS Fargate**: Executes the application code to collect and process ETF data, then stores the data in an S3 bucket as either a Parquet file or a CSV file.

For a detailed walkthrough of the project, check out the following blog post: [ETF Data Scraping with AWS Lambda, AWS Fargate, and Alpha Vantage & Yahoo Finance APIs](https://www.kenwuyang.com/en/post/etf-data-scraping-with-aws-lambda-aws-fargate-and-alpha-vantage-yahoo-finance-apis/).

## Project Setup

### Fork and Clone the Repository

Fork the repository and clone the forked repository to local machine:

```bash
# HTTPS
$ git clone https://github.com/YOUR_GITHUB_USERNAME/etf-data-scraper.git
# SSH
$ git clone git@github/YOUR_GITHUB_USERNAME/etf-data-scraper.git
```

### Set Up with `poetry`

There are two primary methods to set up and use `poetry` for this project:

#### Method 1: Using the Official `poetry` Installer

1. Install `poetry` using the official installer for your operating system. Detailed instructions can be found in [Poetry's Official Documentation](https://python-poetry.org/docs/#installing-with-the-official-installer). Make sure to add `poetry` to your PATH. Refer to the official documentation linked above for specific steps for your operating system.

2. Navigate to the root of the cloned project, which contains the `poetry.lock` and `pyproject.toml` files:

```bash
$ cd [path_to_cloned_repository]
```

3. Configure `poetry` to create the virtual environment inside the project's root directory (and only do so for the current project using the [--local](https://python-poetry.org/docs/configuration/#local-configuration) flag):

```bash
$ poetry config --local virtualenvs.in-project true
```

4. Ensure Python `3.11` is installed on your system and install the project dependencies; for example, with [pyenv](https://github.com/pyenv/pyenv), this can be done as follows:

```bash
$ pyenv install 3.11.8
# Activate Python 3.11.8 for the current project
$ pyenv local 3.11.8
$ poetry install
```

#### Method 2: Using `conda` and `poetry` Together

1. Create a new conda environment named `etf_data_scraper` with Python `3.11`:

```bash
$ yes | conda create --name etf_data_scraper python=3.11
```

2. Install `poetry` within the `etf_data_scraper` environment:

```bash
$ conda activate etf_data_scraper
$ pip3 install poetry
```

3. Navigate to the project root:

```bash
$ cd [path_to_cloned_repository]
```

4. Install the project dependencies (ensure that the `conda` environment is activated):

```bash
$ conda activate etf_data_scraper
$ poetry install
```

### Create Environment Variables

To test run the code locally, create a `.env` file in the root of the project directory with the following environment variables:

```bash
API_KEY=your_alpha_vantage_api_key
S3_BUCKET=your_s3_bucket_name
IPO_DATE=threshold_for_etf_ipo_date
MAX_ETFS=maximum_number_of_etfs_to_scrape
PARQUET=True
```

Set `ENV` to `dev` in the `.env` file to run the scraper in `dev` mode when running the entrypoint `main.py` locally. Ensure that this environment variable is **removed** from `.env` before uploading it to S3 for production.

Details on these environment variables can be found in the [Modules](https://www.kenwuyang.com/en/post/etf-data-scraping-with-aws-lambda-aws-fargate-and-alpha-vantage-yahoo-finance-apis/#modules) subsection of the blog post.

### Set Up AWS CLI

Ensure that the AWS CLI is installed on the local machine and that it is configured with the necessary credentials. Follow the instructions in the [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

A good starting point, though it may violate the principle of least privilege, is to create an IAM user with [programmatic access](https://docs.aws.amazon.com/workspaces-web/latest/adminguide/getting-started-iam-user-access-keys.html) and attach the [AdministratorAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AdministratorAccess.html) policy.
