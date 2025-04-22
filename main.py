from typing import List
from datetime import datetime
from pymongo import MongoClient
from pymongo.errors import PyMongoError
from log import logger

# Assuming chat_collection is defined and connected to the database

@app.get("/history/list", response_model=List[HistoryItem])
async def list_chat_histories():
    """
    List all available chat histories
    """
    try:
        histories = []
        cursor = chat_collection.find().sort("updated_at", -1)
        
        # Check if the cursor is empty and debug it
        count = await chat_collection.count_documents({})
        logger.info(f"Found {count} chat documents in the database")
        
        async for chat in cursor:
            # Ensure each document has required fields
            if "chat_id" not in chat:
                logger.warning(f"Found chat document without chat_id: {chat}")
                continue
                
            try:
                # Convert ObjectId to string if present
                chat_id = str(chat["chat_id"])
                created_at = chat.get("created_at", datetime.now())
                language = chat.get("language", "english")
                message_count = len(chat.get("messages", []))
                
                histories.append(
                    HistoryItem(
                        chat_id=chat_id,
                        created_at=created_at,
                        language=language,
                        message_count=message_count
                    )
                )
            except Exception as e:
                logger.error(f"Error processing chat document: {str(e)}")
                continue
        
        logger.info(f"Returning {len(histories)} chat histories")
        return histories
    except Exception as e:
        logger.error(f"Error listing chat histories: {str(e)}")
        # Return empty list instead of throwing an error
        # This ensures the mobile app doesn't crash
        return []
 