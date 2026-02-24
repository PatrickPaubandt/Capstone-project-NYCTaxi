
from dataclasses import dataclass
import os
from dotenv import load_dotenv

load_dotenv()

@dataclass(frozen=True)
class Settings:
    pg_user: str = os.getenv("POSTGRES_USER", "")
    pg_pass: str = os.getenv("POSTGRES_PASS", "")
    pg_host: str = os.getenv("POSTGRES_HOST", "")
    pg_port: str = os.getenv("POSTGRES_PORT", "5432")
    pg_db: str = os.getenv("POSTGRES_DB", "")
    pg_schema: str = os.getenv("POSTGRES_SCHEMA", "")

    def validate(self) -> None:
        missing = [k for k, v in self.__dict__.items() if not v]
        if missing:
            raise ValueError(f"Missing env vars: {missing}")
