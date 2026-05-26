import User from '../models/user.js';
import jwt  from 'jsonwebtoken';

export const register = async (username, password) => {
    if (password.length < 8) {
        return { error: 'Password must be at least 8 characters long' };
    }
    try {
        const user  = await User.create({ username, password });
        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '10d' }
        );
        return { userId: user._id, token };
    } catch (err) {
        if (err.code === 11000)        return { error: 'Username already taken' };
        if (err.name === 'ValidationError') {
            const msgs = Object.values(err.errors).map(e => e.message);
            return { error: msgs.join(', ') };
        }
        return { error: 'Registration failed' };
    }
};

export const login = async (username, password) => {
    try {
        const user = await User.findOne({ username });
        if (!user) throw new Error('User not found');

        const isMatch = await user.correctPassword(password, user.password);
        if (!isMatch) throw new Error('Invalid password');

        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '10d' }
        );
        return { token, userId: user._id };
    } catch (err) {
        console.error(err.message);
        return null;
    }
};
