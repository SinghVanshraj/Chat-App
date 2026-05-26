import mongoose from 'mongoose';
import bcrypt    from 'bcryptjs';

const userSchema = new mongoose.Schema({
    username: { type: String,  required: true, unique: true },
    password: { type: String,  required: true },
    lastSeen: { type: Date,    default: Date.now },
    isOnline: { type: Boolean, default: false },
});

userSchema.pre('save', async function () {
    if (this.isModified('password')) {
        this.password = await bcrypt.hash(this.password, 12);
    }
});

userSchema.methods.correctPassword = async function (candidate, hashed) {
    return bcrypt.compare(candidate, hashed);
};

export default mongoose.model('User', userSchema);
