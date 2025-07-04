from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import time
from app.core.metrics import DB_QUERY_DURATION

from app.core.config import settings

engine = create_engine(str(settings.DATABASE_URI))
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        # Medir tempo de commit/rollback
        start_time = time.time()
        db.close()
        duration = time.time() - start_time
        DB_QUERY_DURATION.labels(operation='close').observe(duration)
