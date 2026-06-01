import express          from 'express';
import http             from 'http';
import { Server }       from 'socket.io';
import cors             from 'cors';
import 'dotenv/config';
import { v4 as uuidv4 } from 'uuid';

import { connectDB }  from './db/db.js';
import userRoutes     from './routes/userRoutes.js';
import chatRoutes     from './routes/chatRoutes.js';
import User           from './models/user.js';
import { getRoomId }  from './utils/chatHelper.js';
import {
    createMessage,
    updateMessageStatus,
    markMessageAsRead,
    getUserOnlineStatus,
} from './services/chatService.js';

const app    = express();
const server = http.createServer(app);
const io     = new Server(server, {
    cors:         { origin: '*', methods: ['GET', 'POST'] },
    pingTimeout:  60000,
    pingInterval: 25000,
});

app.use(cors());
app.use(express.json());

app.use('/api/user',  userRoutes);  
app.use('/api/users', userRoutes);  
app.use('/api/chat',  chatRoutes);  

app.get('/health', (_, res) => res.json({ status: 'ok' }));

const onlineUsers = new Map();
io.on('connection', (socket) => {

    socket.on('user_connected', async (userId) => {
        if (!userId) return;
        const uid = userId.toString();
        onlineUsers.set(uid, socket.id);
        socket.userId = uid;
        await User.findByIdAndUpdate(uid, { isOnline: true }).catch(() => {});
        socket.broadcast.emit('user_online', { userId: uid });
    });

    socket.on('send_message', async ({ senderId, receiverId, message, clientTempId }) => {
        if (!senderId || !receiverId || !message) {
            return socket.emit('message_error', { error: 'Missing fields' });
        }
        try {
            const roomId    = getRoomId(senderId.toString(), receiverId.toString());
            const messageId = uuidv4();
            const createdAt = new Date().toISOString();

            await createMessage({
                roomId,
                messageId,
                sender:   senderId,
                receiver: receiverId,
                message,
                status:   'sent',
            });

            const receiverSocketId = onlineUsers.get(receiverId.toString());

            if (receiverSocketId) {
                io.to(receiverSocketId).emit('receive_message', {
                    messageId,
                    chatRoomId: roomId,
                    sender:     senderId,
                    receiver:   receiverId,
                    message,
                    status:     'delivered',
                    createdAt,
                });
                await updateMessageStatus(messageId, 'delivered');
                 socket.emit('message_status_update', { messageId, status: 'delivered', clientTempId });
            } else {
                 socket.emit('message_status_update', { messageId, status: 'sent', clientTempId });
            }
        } catch (err) {
            console.error('send_message error:', err);
            socket.emit('message_error', { error: 'Failed to send message' });
        }
    });

    socket.on('message_read', async ({ messageId, senderId }) => {
        if (!messageId || !senderId) return;
        try {
            await updateMessageStatus(messageId, 'read');
            const senderSocketId = onlineUsers.get(senderId.toString());
            if (senderSocketId) {
                io.to(senderSocketId).emit('message_status_update', {
                    messageId,
                    status: 'read',
                });
            }
        } catch (err) {
            console.error('message_read error:', err);
        }
    });

    socket.on('mark_all_read', async ({ userId, partnerId }) => {
        if (!userId || !partnerId) return;
        try {
            await markMessageAsRead(userId.toString(), partnerId.toString());
            const partnerSocketId = onlineUsers.get(partnerId.toString());
            if (partnerSocketId) {
                io.to(partnerSocketId).emit('all_messages_read', {
                    byUserId: userId,
                });
            }
        } catch (err) {
            console.error('mark_all_read error:', err);
        }
    });

    socket.on('typing_start', ({ senderId, receiverId }) => {
        if (!senderId || !receiverId) return;
        const s = onlineUsers.get(receiverId.toString());
        if (s) io.to(s).emit('user_typing', { userId: senderId, isTyping: true });
    });

    socket.on('typing_stop', ({ senderId, receiverId }) => {
        if (!senderId || !receiverId) return;
        const s = onlineUsers.get(receiverId.toString());
        if (s) io.to(s).emit('user_typing', { userId: senderId, isTyping: false });
    });

    socket.on('check_online_status', async ({ userId }) => {
        if (!userId) return;
        const status = await getUserOnlineStatus(userId.toString());
        socket.emit('online_status', { userId, ...status });
    });

    socket.on('disconnect', async () => {
        const userId = socket.userId;
        if (userId) {
            onlineUsers.delete(userId);
            const lastSeen = new Date();
            await User.findByIdAndUpdate(userId, { isOnline: false, lastSeen }).catch(() => {});
            socket.broadcast.emit('user_offline', { userId, lastSeen });
        }
    });
});

const PORT = process.env.PORT || 3000;
connectDB().then(() => {
    server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
});
