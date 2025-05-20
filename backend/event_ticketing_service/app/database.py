import os
import boto3
import json

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# Load .env file for local development.
# In AWS Fargate, environment variables will be set directly.
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", "..", ".env"))

DB_URL = os.getenv("DB_URL")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD_SECRET_ARN = os.getenv("DB_PASSWORD_SECRET_ARN")
AWS_REGION = os.getenv("AWS_REGION")
DB_PASSWORD = os.getenv("DB_PASSWORD", None)

# Try to get password from Secrets Manager if running in AWS
if DB_PASSWORD_SECRET_ARN and DB_URL and DB_URL != "localhost":
    if not AWS_REGION:
        print("Warning: AWS_REGION environment variable is not set. boto3 might not function correctly.")
        # Attempt to proceed, boto3 might infer region from EC2/ECS metadata if available

    print(f"Event Service: Attempting to retrieve DB password from Secrets Manager ARN: {DB_PASSWORD_SECRET_ARN} in region {AWS_REGION}")
    try:
        client = boto3.client('secretsmanager', region_name=AWS_REGION)
        get_secret_value_response = client.get_secret_value(SecretId=DB_PASSWORD_SECRET_ARN)

        if 'SecretString' in get_secret_value_response:
            secret_string = get_secret_value_response['SecretString']
            DB_PASSWORD = secret_string
            if DB_PASSWORD:
                print("Event Service: Successfully retrieved DB password from Secrets Manager.")
            else:
                print("Event Service: Warning: SecretString retrieved but password key not found or password is empty.")
        else:
            print("Event Service: Password is binary in Secrets Manager, not handled by this script.")
            raise ValueError("Password in Secrets Manager is binary, expected SecretString.")

    except Exception as e:
        print(f"Event Service: ERROR: Failed to retrieve DB password from Secrets Manager: {e}")
        raise RuntimeError(f"Could not retrieve database password from Secrets Manager: {e}")

# Fallback for local development if AWS environment variables are not fully set
if not DB_PASSWORD:
    print("Event Service: Password not retrieved from Secrets Manager. Checking local .env for DB_PASSWORD.")
    DB_PASSWORD = os.getenv("DB_PASSWORD") # Shared local password or define service-specific one
    if DB_PASSWORD:
        print("Event Service: Using DB_PASSWORD from .env for local development.")
    else:
        print("Event Service: Warning: DB_PASSWORD not found in .env for local development.")

# Validate final configuration
if not all([DB_URL, DB_USER, DB_NAME, DB_PASSWORD, DB_PORT]):
    missing_vars = []
    if not DB_URL: missing_vars.append("DB_URL")
    if not DB_USER: missing_vars.append("DB_USER")
    if not DB_NAME: missing_vars.append("DB_NAME")
    if not DB_PASSWORD: missing_vars.append("DB_PASSWORD")
    if not DB_PORT: missing_vars.append("DB_PORT")

    error_message = (
        "Event Service: Database configuration is incomplete. "
        f"Missing or empty: {', '.join(missing_vars)}. "
        f"Current values - Host: {DB_URL}, User: {DB_USER}, DB: {DB_NAME}, "
        f"Port: {DB_PORT}, Password Set: {'Yes' if DB_PASSWORD else 'No'}"
    )
    print(f"ERROR: {error_message}")
    raise ValueError(error_message)

# Construct the database URL - uses POSTGRES_DB_NAME from env, which TF sets to the shared DB.
DATABASE_URL = (
    f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_URL}:{DB_PORT}/{DB_NAME}"
)

print(f"Event Service: Connecting to database URL: postgresql://{DB_USER}:****@{DB_URL}:{DB_PORT}/{DB_NAME}")

# SQLAlchemy setup
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base() # Even if not used for create_all, it's standard to have.

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
