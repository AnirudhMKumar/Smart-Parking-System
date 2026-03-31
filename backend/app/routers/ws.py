import asyncio
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.services import cache_service

router = APIRouter(tags=["WebSocket"])


class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections[:]:
            try:
                await connection.send_json(message)
            except Exception:
                self.active_connections.remove(connection)


manager = ConnectionManager()


@router.websocket("/ws/parking")
async def parking_websocket(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_json({"type": "pong"})
    except WebSocketDisconnect:
        manager.disconnect(websocket)


async def listen_for_updates():
    pubsub = cache_service.subscribe_parking_updates()
    while True:
        message = pubsub.get_message(ignore_subscribe_messages=True, timeout=1)
        if message and message["type"] == "message":
            data = json.loads(message["data"])
            await manager.broadcast(data)
        await asyncio.sleep(0.1)
