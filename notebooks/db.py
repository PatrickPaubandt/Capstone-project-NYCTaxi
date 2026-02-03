from sqlalchemy import create_engine, text
from src.config import Settings

def get_engine(settings: Settings):
    settings.validate()
    url = (
        f"postgresql+psycopg2://{settings.pg_user}:{settings.pg_pass}"
        f"@{settings.pg_host}:{settings.pg_port}/{settings.pg_db}"
    )
    return create_engine(url, future=True)

def smoke_test(engine, schema: str):
    with engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema};"))
        res = conn.execute(text("SELECT 1;")).scalar()
    return res
