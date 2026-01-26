from pydantic_settings import SettingsConfigDict

from .base import BaseAppSettings


class AuthSettings(BaseAppSettings):
    model_config = SettingsConfigDict(env_prefix = "AUTH_")
    
    standard_on: bool
    apple_on: bool
    google_on: bool
    strava_on: bool