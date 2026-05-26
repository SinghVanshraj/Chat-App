import mongoose from "mongoose";
import Message   from "../models/message.js";
import User      from "../models/user.js";
import { getRoomId } from "../utils/chatHelper.js";
export const createMessage = async (messageData) => {
    const message = new Message({
        chatRoomId: messageData.roomId,
        messageId:  messageData.messageId,
        sender:     messageData.sender,
        receiver:   messageData.receiver,
        message:    messageData.message,
        status:     messageData.status || 'sent',
    });
    await message.save();
    return message;
};

export const fetchChatMessages = async ({
    currentUserId,
    senderId,
    receiverId,
    page  = 1,
    limit = 20,
}) => {
    if (!senderId || !receiverId) return [];
    const roomId = getRoomId(senderId, receiverId);

    if (currentUserId === receiverId) {
        await Message.updateMany(
            {
                chatRoomId: roomId,
                receiver:   new mongoose.Types.ObjectId(currentUserId),
                sender:     new mongoose.Types.ObjectId(senderId),
                status:     'sent',
            },
            { $set: { status: 'delivered' } }
        );
    }

    const messages = await Message.aggregate([
        { $match: { chatRoomId: roomId } },
        { $sort:  { createdAt: -1 } },
        { $skip:  (page - 1) * limit },
        { $limit: limit },
        {
            $addFields: {
                isMine: {
                    $eq: [
                        "$sender",
                        { $toObjectId: currentUserId },
                    ],
                },
            },
        },
    ]);

    return messages.reverse();
};

export const updateMessageStatus = async (messageId, status) => {
    return Message.findOneAndUpdate(
        { messageId },
        { status },
        { new: true }
    );
};

export const getUndeliveredMessage = async (userId, partnerId) => {
    return Message.find({
        receiver: userId,
        sender:   partnerId,
        status:   'sent',
    }).sort({ createdAt: 1 });
};

export const markMessageAsDelivered = async (userId, partnerId) => {
    const result = await Message.updateMany(
        {
            receiver: new mongoose.Types.ObjectId(userId),
            sender:   new mongoose.Types.ObjectId(partnerId),
            status:   'sent',
        },
        { $set: { status: 'delivered' } }
    );
    return result.modifiedCount;
};
export const markMessageAsRead = async (userId, partnerId) => {

    const result = await Message.updateMany(
        {
            receiver: new mongoose.Types.ObjectId(userId),
            sender:   new mongoose.Types.ObjectId(partnerId),
            status:   { $in: ['sent', 'delivered'] },
        },
        { $set: { status: 'read' } }
    );
    return result.modifiedCount;
};

export const updateUserLastSeen = async (userId, lastSeen) => {
    return User.findByIdAndUpdate(userId, { lastSeen }, { new: true });
};

export const getUserOnlineStatus = async (userId) => {
    const user = await User.findById(userId).select('isOnline lastSeen');
    if (!user) return { isOnline: false, lastSeen: null };
    return {
        isOnline: user.isOnline || false,
        lastSeen: user.lastSeen ? user.lastSeen.toISOString() : null,
    };
};

export const chatRoom = async (userId) => {
    const userObjectId = new mongoose.Types.ObjectId(userId);

    const privateChats = await Message.aggregate([
        {
            $match: {
                $or: [{ sender: userObjectId }, { receiver: userObjectId }],
            },
        },
        { $sort: { createdAt: -1 } },
        {
            $group: {
                _id: {
                    $cond: [
                        { $ne: ["$sender", userObjectId] },
                        "$sender",
                        "$receiver",
                    ],
                },
                latestMessageTime: { $first: "$createdAt" },
                latestMessage:     { $first: "$message" },
                latestMessageId:   { $first: "$_id" },
                sender:            { $first: "$sender" },
                messages: {
                    $push: {
                        sender:   "$sender",
                        receiver: "$receiver",
                        status:   "$status",
                    },
                },
            },
        },
        {
            $lookup: {
                from:         "users",
                localField:   "_id",
                foreignField: "_id",
                as:           "userDetails",
            },
        },
        { $unwind: "$userDetails" },
        {
            $project: {
                _id:               0,
                username:          "$userDetails.username",
                userId:            "$userDetails._id",
                isOnline:          "$userDetails.isOnline",
                latestMessageTime: 1,
                latestMessage:     1,
                sender:            1,
                unreadCount: {
                    $size: {
                        $filter: {
                            input: "$messages",
                            as:    "msg",
                            cond: {
                                $and: [
                                    { $eq: ["$$msg.receiver", userObjectId] },
                                    { $in: ["$$msg.status", ["sent", "delivered"]] },
                                ],
                            },
                        },
                    },
                },
                latestMessageStatus: {
                    $cond: [
                        { $eq: ["$sender", userObjectId] },
                        {
                            $arrayElemAt: [
                                {
                                    $map: {
                                        input: {
                                            $filter: {
                                                input: "$messages",
                                                as:    "msg",
                                                cond:  { $eq: ["$$msg.sender", userObjectId] },
                                            },
                                        },
                                        as: "m",
                                        in: "$$m.status",
                                    },
                                },
                                0,
                            ],
                        },
                        null,
                    ],
                },
            },
        },
    ]);

    return privateChats.sort(
        (a, b) => new Date(b.latestMessageTime) - new Date(a.latestMessageTime)
    );
};
