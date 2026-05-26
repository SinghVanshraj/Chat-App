export const getRoomId = (user1, user2) => [user1, user2].sort().join('_');
