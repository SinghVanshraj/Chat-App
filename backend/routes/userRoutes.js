import express from 'express';
import { registerUser, loginUser, getAllUsers } from '../controller/userController.js';
import authMiddleware from '../middlewares/authMiddleware.js';

const router = express.Router();

router.post('/register', registerUser);
router.post('/login',    loginUser);
router.get('/users', authMiddleware, getAllUsers);

export default router;
