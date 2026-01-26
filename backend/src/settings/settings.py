from typing import Literal

from .auth_settings import AuthSettings
from .database_settings import DatabaseSettings
from .llm_settings import LLMSettings


class ApplicationSettings:
  
    # variables
    env: Literal["DEV", "PPROD", "PROD"] = "DEV"
    
    # submodels
    database = DatabaseSettings() # type: ignore[call-arg]
    llm = LLMSettings() # type: ignore[call-arg]
    auth = AuthSettings() # type: ignore[call-arg]