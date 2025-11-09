from openai import OpenAI
from pydantic import BaseModel


class OutputSchema(BaseModel):
    product_name: str
    price: float
    features: list[str]

class OutputSchemaColor(BaseModel):
    color_red: int
    color_green: int
    color_blue: int

class OutputSchemaStr(BaseModel):
    text: str

class OutputSchemaResponse(BaseModel):
    unimportant_keys: list[str]


def get_unimportant_keys_nemotron(api_response_1, api_response_2):
    json_schema = OutputSchemaResponse.model_json_schema()

    prompt = (
        "You are a developer checking for breaking changes after upgrading an API server. You are given two API responses: one from an older version of the API, and another from an upgraded version. Compare the response schemas to detect breaking changes."
        "List which keys are unchanged in the new schema."
    )

    # api_response_1 = {
    #     "id": "0",
    #     "first_name": "john",
    #     "last_name": "doe",
    #     "street_address": "1111 SomePlace Lane",
    #     "created_at": "2025-11-09T02:07:10.131782",
    #     "last_login_at": "2025-11-09T02:07:10.131787"
    # }
    # api_response_2 = {
    #     "id": "0",
    #     "first_name": "john",
    #     "middle_name": "",
    #     "last_name": "doe",
    #     "street_address": "1111 SomePlace Lane",
    #     "created_at": "2025-11-09T03:26:07.728452",
    #     "last_login_at": "2025-11-09T03:26:07.728456"
    # }

    messages = [
        # system prompts
        # {"role": "system", "content": "/no_think"},
        {"role": "system", "content": prompt},

        # user prompts (input from our application)
        {"role": "user", "content": str(api_response_1)},
        {"role": "user", "content": str(api_response_2)},
    ]

    # hosted instance
    client = OpenAI(
        base_url="http://38.80.122.216:8000/v1",
        api_key="no-key",
    )

    # free API endpoint
    # client = OpenAI(
    #     base_url="https://integrate.api.nvidia.com/v1",
    #     api_key="YOUR_API_KEY_HERE",
    # )

    response = client.chat.completions.create(
        model="nvidia/nvidia-nemotron-nano-9b-v2",
        messages=messages,
        extra_body={"guided_json": json_schema},
        temperature=0,
        stream=False
    )

    return response.choices[0].message.content
