import httpx
import  json
import os
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Any, Dict, List, Optional
from dotenv import load_dotenv

load_dotenv(dotenv_path=Path(__file__).resolve().parent / ".env")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://127.0.0.1"],
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Transaction(BaseModel):
    text : str
    categories : List[str]
    context: Optional[Dict[str, Any]] = None

async def get_transaction(
    user_text: str,
    categories: List[str],
    context: Optional[Dict[str, Any]] = None,
):
    API_KEY = os.getenv("GROQ_API_KEY", "").strip()
    if not API_KEY:
        return {
            "transaction": {
                "is_transaction": False,
                "amount": 0,
                "category": ""
            },
            "reply": "Chưa cấu hình GROQ_API_KEY cho FastAPI local."
        }

    url = "https://api.groq.com/openai/v1/chat/completions"

    categories_str = ", ".join(categories)

    system_prompt =f"""
    Bạn là trợ lý ảo quản lý chi tiêu . Trả về duy nhất 1 định dạng JSON.
    Nếu là các câu hỏi giao tiếp thông thường không liên quan đến giao dịch, trả về is_transaction = false và reply là câu trả lời tự nhiên.
    Nếu người dùng nhập thông tin về giao dịch, hãy phân tích và trích xuất số
    Danh sách các danh mục hợp lệ : {categories_str}
    Chỉ phân loại các giao dịch vào 1 trong các danh mục được liệt kê ở trên.
    Cấu trúc JSON BẮT BUỘC :
    {{
        "transaction": {{
            "is_transaction": boolean,
            "amount": number,
            "category": string
        }},
        "reply": "Câu trả lời giao tiếp tự nhiên bằng tiếng Việt"
    }},
    """

    try:
        context_prompt = ""
        if context:
            selected_wallet_balance = context.get("selected_wallet_balance", 0)
            total_balance = context.get("total_balance", 0)
            today_expense = context.get("today_expense", 0)
            category_limits = context.get("category_limits", [])

            limits_lines = []
            for item in category_limits:
                category_name = item.get("category", "Danh mục")
                total_limit = item.get("total_limit", 0)
                remaining = item.get("remaining", 0)
                limits_lines.append(
                    f"- {category_name}: tổng hạn mức {total_limit}, còn lại {remaining}"
                )

            limits_text = "\n".join(limits_lines) if limits_lines else "- Chưa có dữ liệu hạn mức"
            context_prompt = f"""
            Ngữ cảnh tài chính hiện tại của người dùng:
            - Số dư ví đang chọn: {selected_wallet_balance}
            - Tổng số dư tất cả ví: {total_balance}
            - Chi tiêu hôm nay: {today_expense}
            - Hạn mức theo danh mục:
            {limits_text}
            """

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {API_KEY}"},
                json={
                    "model": "llama-3.1-8b-instant",
                    "messages":[
                        {"role": "system", "content": system_prompt},
                        {
                            "role": "user",
                            "content": f"{context_prompt}\n\nTin nhắn người dùng: {user_text}".strip(),
                        }
                    ],
                    "temperature": 0.2
                }
            )
            response.raise_for_status()
            content = response.json()["choices"][0]["message"]["content"]
            try:
                return json.loads(content)
            except Exception:
                return {
                    "transaction": {
                        "is_transaction": False,
                        "amount": 0,
                        "category": ""
                    },
                    "reply": content
                }
    except Exception as ex:
        return {
            "transaction": {
                "is_transaction": False,
                "amount": 0,
                "category": ""
            },
            "reply": f"FastAPI gọi LLM lỗi: {ex}"
        }


@app.post("/classify_transaction")
async def chat_endpoint(transaction: Transaction):
    result = await get_transaction(
        transaction.text,
        transaction.categories,
        transaction.context,
    )
    return result


@app.post("/chat")
async def chat_alias_endpoint(transaction: Transaction):
    result = await get_transaction(
        transaction.text,
        transaction.categories,
        transaction.context,
    )
    return result
