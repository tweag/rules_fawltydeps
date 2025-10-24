from sqlalchemy import create_engine

def init_db():
    engine = create_engine("sqlite:///:memory:", echo=False)
    return engine
