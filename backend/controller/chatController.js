import { fetchChatMessages, chatRoom } from '../services/chatService.js';

export const getMessage = async (req, res) => {
    const { senderId, receiverId, page, limit } = req.query;
    try {
        const messages = await fetchChatMessages({
            currentUserId: req.userId,
            senderId,
            receiverId,
            page:  parseInt(page,  10) || 1,
            limit: parseInt(limit, 10) || 20,
        });
        res.json(messages);
    } catch {
        res.status(500).json({ message: 'Error fetching messages' });
    }
};

export const getChatRoom = async (req, res) => {
    try {
        const rooms = await chatRoom(req.userId);
        res.json(rooms);
    } catch {
        res.status(500).json({ message: 'Error fetching chat rooms' });
    }
};
