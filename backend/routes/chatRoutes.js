import express from 'express';
import { getMessage, getChatRoom } from '../controller/chatController.js';
import authMiddleware from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/messages',  authMiddleware, getMessage);
router.get('/chat-room', authMiddleware, getChatRoom);

export default router;
