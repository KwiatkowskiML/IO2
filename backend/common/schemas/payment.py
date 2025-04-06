from typing import Optional

from pydantic import BaseModel

class PaymentResponse(BaseModel):
    success: bool
    transaction_id: Optional[str] = None
    error_message: Optional[str] = None