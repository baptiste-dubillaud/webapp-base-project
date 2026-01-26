from pydantic_settings import SettingsConfigDict

from .base import BaseAppSettings


class LLMSettings(BaseAppSettings):
    model_config = SettingsConfigDict(env_prefix = "LLM_")
    
    api_key: str
    api_url: str
    model: str