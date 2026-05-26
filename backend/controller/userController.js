import { register, login } from '../services/authService.js';
import User    from '../models/user.js';
import mongoose from 'mongoose';

export const registerUser = async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password)
        return res.status(400).json({ message: 'Username and password required' });

    const result = await register(username, password);
    if (result.error) return res.status(400).json({ message: result.error });
    return res.status(201).json(result)
};

export const loginUser = async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password)
        return res.status(400).json({ message: 'Username and password required' });

    const result = await login(username, password);
    if (!result) return res.status(401).json({ message: 'Invalid username or password' });
    return res.status(200).json(result);
};

export const getAllUsers = async (req, res) => {
    try {
        const users = await User.find(
            { _id: { $ne: new mongoose.Types.ObjectId(req.userId) } },
            { password: 0 }
        ).sort({ username: 1 });
        return res.status(200).json(users);
    } catch (err) {
        console.error('getAllUsers error:', err);
        return res.status(500).json({ message: 'Error fetching users' });
    }
};
