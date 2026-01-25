from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from ..base import Base


class Role(Base):
    __tablename__ = "role"
    
    id: Mapped[int]= mapped_column(primary_key=True, autoincrement=True)
    role_name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    
