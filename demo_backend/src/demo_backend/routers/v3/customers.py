from datetime import datetime

from fastapi import APIRouter
from pydantic import BaseModel
from fastapi import HTTPException

class CustomerPublic(BaseModel):
    id: str
    first_name: str
    middle_name: str
    last_name: str
    street_address: str

class Customer(CustomerPublic):
    created_at: datetime
    last_login_at: datetime


class Database:
    def __init__(self) -> None:
        self.customers: dict[str, Customer] = {}

router = APIRouter(
    prefix="/customers",
)

database = Database()

@router.get("/")
def root() -> list[str]:
    return list(database.customers.keys())

@router.post("/")
def create_customer(customer: CustomerPublic) -> Customer:
    if customer.id in database.customers.keys():
        raise HTTPException(status_code=400, detail="Customer already exists")

    real_customer = Customer(
        id=customer.id,
        first_name=customer.first_name,
        middle_name=customer.middle_name,
        last_name=customer.last_name,
        street_address=customer.street_address,
        created_at=datetime.now(),
        last_login_at=datetime.now(),
    )
    database.customers[customer.id] = real_customer
    return real_customer

@router.delete("/{id}")
def delete_customer(id: str) -> Customer:
    customer = database.customers.pop(id, None)
    if customer is None:
        raise HTTPException(status_code=400, detail="Customer does not exist")

    return customer