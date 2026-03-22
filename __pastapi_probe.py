import asyncio
from PastAPI import get_transaction

async def main():
    result = await get_transaction('chi 40k an trua', ['Ăn uống','Đi lại'])
    print(result)

asyncio.run(main())
