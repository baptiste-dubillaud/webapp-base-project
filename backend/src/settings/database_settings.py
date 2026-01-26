from pydantic_settings import SettingsConfigDict

from .base import BaseAppSettings


class DatabaseSettings(BaseAppSettings):
    model_config = SettingsConfigDict(env_prefix = "DATABASE_")
    
    # connection
    host: str
    port: str
    user: str
    password: str
    db_name: str
    
    # management
    echo: bool
    pool_size: int
    