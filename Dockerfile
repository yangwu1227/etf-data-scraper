FROM python:3.11.9-slim-bullseye AS python-base

    # Ensure python I/O is unbuffered so that log messages are flushed to the stream
ENV PYTHONUNBUFFERED=1 \ 
    # Prevents Python from creating pyc files
    PYTHONDONTWRITEBYTECODE=1 \ 
    # See https://github.com/python-poetry/poetry/issues/2200 and https://github.com/python-poetry/poetry/pull/7081
    POETRY_REQUESTS_TIMEOUT=30 \
    # Poetry version
    POETRY_VERSION=1.8.3 \
    # Override the poetry installation path
    POETRY_HOME="/opt/poetry" \
    # Create virtualenv inside the project root
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # Working directory for the project
    PROJECT_ROOT_PATH="/opt/project" \
    # Virtual environment directory placed in project root
    VENV_PATH="/opt/project/.venv"

# Update PATH to include Poetry's bin directory and the virtual environment's bin directory
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

FROM python-base AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential 
# Official installation script from https://github.com/python-poetry/install.python-poetry.org
RUN curl -sSL https://install.python-poetry.org | python3 -

# Copy lock file and pyproject.toml from local project root onto the container
WORKDIR $PROJECT_ROOT_PATH
COPY pyproject.toml poetry.lock ./
RUN poetry install --only main --sync --no-root

FROM python-base AS production 

# Copy the project directory from the builder stage with all dependencies installed (not including the poetry executable)
COPY --from=builder $PROJECT_ROOT_PATH $PROJECT_ROOT_PATH
# Copy source code from local project root onto the container
COPY src/ $PROJECT_ROOT_PATH/src
COPY main.py $PROJECT_ROOT_PATH/main.py

WORKDIR $PROJECT_ROOT_PATH
# Use the python interpreter and packages from the virtual environment directly (without poetry run)
CMD [".venv/bin/python3", "main.py"]
