# Instagram Clone (Momento) - Complete Node.js Backend API Roadmap

This document outlines the complete set of REST API endpoints and WebSocket events required for a full-featured Instagram-level social application (like Momento), incorporating all core features, advanced story editor metadata, comment management, and online presence tracking.

---

## 1. Authentication & Session Management (`/api/auth`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Register a new user (`username`, `email`, `password`, `name`) |
| `POST` | `/api/auth/login` | Authenticate user & return JWT token |
| `POST` | `/api/auth/refresh` | Refresh expired JWT token |
| `POST` | `/api/auth/logout` | Invalidate session / log out |
| `POST` | `/api/auth/forgot-password` | Request password reset OTP / link |

---

## 2. Users & Profile Management (`/api/users`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/users/:userId` | Get user profile details, posts count, followers/following count |
| `PUT` | `/api/users/profile` | Update profile (`name`, `bio`, `profileImage`, `website`) |
| `GET` | `/api/users/:userId/followers` | Get list of followers for a user |
| `GET` | `/api/users/:userId/following` | Get list of following users |
| `POST` | `/api/users/:userId/follow` | Follow / Unfollow user (toggle) |
| `GET` | `/api/users/online` | Get online status IDs of followers + following |
| `PUT` | `/api/users/activity-status` | Toggle `show_activity_status` (privacy setting) |

---

## 3. Close Friends (`/api/close-friends`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/close-friends` | Get list of close friends for current user |
| `POST` | `/api/close-friends/:userId` | Add user to close friends list |
| `DELETE` | `/api/close-friends/:userId` | Remove user from close friends list |

---

## 4. Posts & Feed (`/api/posts`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/posts` | Create a new post (multipart image/video upload + `caption`) |
| `GET` | `/api/posts` | Get home feed posts (pagination, following-only filter) |
| `GET` | `/api/posts/user/:userId` | Get posts created by a specific user |
| `GET` | `/api/posts/:postId` | Get single post details by ID |
| `DELETE` | `/api/posts/:postId` | Delete a post |
| `POST` | `/api/posts/:postId/like` | Like / Unlike post (toggle) |

---

## 5. Reels (`/api/reels`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/reels` | Upload a new reel video (`caption`, video file) |
| `GET` | `/api/reels` | Get reels feed |
| `GET` | `/api/reels/user/:userId` | Get reels by user ID |
| `GET` | `/api/reels/:reelId` | Get single reel by ID |
| `DELETE` | `/api/reels/:reelId` | Delete a reel |
| `POST` | `/api/reels/:reelId/like` | Like / Unlike reel (toggle) |

---

## 6. Stories & Story Editor (`/api/stories`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/stories` | Create rich story (media, layers JSON, music metadata, mentions[], is_ai_generated, audience 'followers'/'close_friends', hide_from[], allow_replies, allow_sharing, alt_text) |
| `GET` | `/api/stories` | Fetch active 24h stories (filtered by following + close friends, excluding hidden users) |
| `PUT` | `/api/stories/:storyId/view` | Mark story as viewed by current user |
| `DELETE` | `/api/stories/:storyId` | Delete user's own story |

---

## 7. Comments (`/api/comments` & Nested)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/posts/:id/comments` | Get comments for a post or reel |
| `POST` | `/api/posts/:id/comments` | Add a comment to a post or reel |
| `POST` | `/api/comments/:commentId/like` | Like / Unlike a comment |
| `PUT` | `/api/comments/:commentId` | Edit comment text |
| `DELETE` | `/api/comments/:commentId` | Delete a comment |

---

## 8. Direct Messaging & Chat (`/api/messages`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/messages/conversations` | Get list of active chat conversations |
| `GET` | `/api/messages/:userId` | Get message history with a peer user |
| `POST` | `/api/messages/upload` | Upload media attachment for chat |

---

## 9. Explore & Search (`/api/search`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/search/users` | Search users by username or name (`?q=...`) |
| `GET` | `/api/explore` | Get trending / discover feed media |

---

## 10. Notifications (`/api/notifications`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/notifications` | Get user notifications (likes, comments, mentions, follows) |
| `PUT` | `/api/notifications/:id/read` | Mark notification as read |

---

## 11. Saved / Bookmarked Items (`/api/saved`)
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/saved` | Get all saved items (posts, reels, messages) |
| `POST` | `/api/saved/posts/:postId` | Save a post |
| `DELETE` | `/api/saved/posts/:postId` | Remove post from saved |
| `POST` | `/api/saved/reels/:reelId` | Save a reel |
| `DELETE` | `/api/saved/reels/:reelId` | Remove reel from saved |
| `POST` | `/api/saved/messages/:msgId` | Save a message |
| `DELETE` | `/api/saved/messages/:msgId` | Remove message from saved |

---

## 12. WebSocket Events (Socket.io)
| Event Name | Direction | Description |
| :--- | :--- | :--- |
| `connection` / `disconnect` | Bidirectional | Client connects / disconnects |
| `presence:online` / `presence:offline` | Client -> Server | Broadcast online/offline status |
| `presence:update` | Server -> Client | Broadcast peer status change |
| `presence:snapshot` | Server -> Client | Send initial online user IDs list |
| `presence:ping` | Client -> Server | Heartbeat ping (every 30s) |
| `chat:join` | Client -> Server | Join active chat room |
| `chat:send` | Client -> Server | Send realtime message with ack |
| `chat:message` | Server -> Client | Deliver incoming message |
| `chat:typing` | Bidirectional | Typing indicator (isTyping true/false) |
| `chat:read` | Bidirectional | Mark messages as read |
