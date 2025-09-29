from pydantic import BaseModel

class House(BaseModel):
    Size: float
    Bedrooms: int
    Age: int
