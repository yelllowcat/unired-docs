# Unired Database Documentation

> **Database:** `unired_DB`  
> **Engine:** InnoDB  
> **Charset:** `utf8mb4` / Collation: `utf8mb4_unicode_ci`

---

## Entity-Relationship Diagram

```
┌──────────────┐       ┌──────────────┐       ┌────────────────────┐
│    users     │       │    posts     │       │     comments       │
│──────────────│       │──────────────│       │────────────────────│
│ PK user_id   │──┐    │ PK post_id   │──┐    │ PK comment_id      │
│ full_name    │  │    │ FK user_id ──┘  │    │ FK post_id ────────┘
│ biography    │  │    │ content        │    │ FK user_id ────────┐
│ profile_pic  │  │    │ image          │    │ content            │
│ email        │  │    │ created_at     │    │ created_at         │
│ password     │  │    │ updated_at     │    │ active (soft del)  │
│ role         │  │    │ active         │    └────────┬───────────┘
│ active       │  │    └────────────────┘             │
│ reg_date     │  │              │                    │
│ updated_at   │  │              │                    │
└──────┬───────┘  │              │                    │
       │          │              │                    │
       ├──────────┼──────────────┼────────────────────┘
       │          │              │
       ▼          ▼              ▼
┌──────────────┐ ┌──────────┐ ┌──────────────────┐
│    likes     │ │ frien... │ │ hidden_comments  │
│──────────────│ │──────────│ │──────────────────│
│ PK like_id   │ │ PK req_id│ │ PK hidden_id     │
│ FK post_id ──┘ │ sende... │ │ FK user_id       │
│ FK user_id ────││ receive..│ │ FK comment_id ───┘
│ liked_at      │ │ status   │ │ hidden_at        │
│ UNIQUE(post,  │ │ req_date │ │ UNIQUE(user,     │
│   user)       │ │ resp_date│ │   comment)       │
└──────────────┘ └──────────┘ └──────────────────┘

┌──────────────────┐  ┌──────────────┐
│ comment_likes    │  │   replies    │
│──────────────────│  │──────────────│
│ PK like_id       │  │ PK reply_id  │
│ FK comment_id ───┤  │ FK comment_id│
│ FK user_id ──────┤  │ FK user_id   │
│ liked_at         │  │ content      │
│ UNIQUE(comment,  │  │ created_at   │
│   user)          │  │ active       │
└──────────────────┘  └──────────────┘

┌──────────────┐   ┌────────────────────┐
│   friends    │   │ user_update_log    │
│──────────────│   │────────────────────│
│ PK fship_id  │   │ PK log_id          │
│ FK user_id1 ─┼───│ FK user_id         │
│ FK user_id2 ─┼───│ old/new full_name  │
│ fship_date   │   │ old/new biography  │
│ UNIQUE(u1,u2)│   │ change_date        │
└──────────────┘   └────────────────────┘

Legend:
  PK = Primary Key
  FK = Foreign Key
  ── = references
```

---

## Tables

### 1. `users`

Stores user account and profile information.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `user_id` | INT | PK, AUTO_INCREMENT | — | Unique user identifier |
| `full_name` | VARCHAR(100) | NOT NULL | — | User's full display name |
| `biography` | TEXT | — | NULL | User biography/profile text |
| `profile_picture` | VARCHAR(255) | — | `'default_avatar.png'` | Path/filename of profile image |
| `email` | VARCHAR(100) | UNIQUE, NOT NULL | — | User email address |
| `password` | VARCHAR(255) | NOT NULL | — | Hashed password |
| `registration_date` | DATETIME | — | `CURRENT_TIMESTAMP` | Account creation date |
| `role` | VARCHAR(20) | — | `'user'` | User role (e.g. user, admin) |
| `active` | BOOLEAN | — | `TRUE` | Account active status |
| `updated_at` | DATETIME | — | `CURRENT_TIMESTAMP ON UPDATE` | Last modification timestamp |

**Indexes:** PK on `user_id`, UNIQUE on `email`.

---

### 2. `posts`

User-created posts containing text and optional image.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `post_id` | INT | PK, AUTO_INCREMENT | — | Unique post identifier |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Author of the post |
| `content` | TEXT | NOT NULL | — | Post text content |
| `image` | VARCHAR(255) | — | NULL | Optional image path/filename |
| `created_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Post creation timestamp |
| `updated_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Last edit timestamp |
| `active` | BOOLEAN | — | `TRUE` | Soft delete flag |

**Foreign Keys:** `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Indexes:** PK on `post_id`.

---

### 3. `comments`

Comments left on posts. Supports soft delete via `active` flag.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `comment_id` | INT | PK, AUTO_INCREMENT | — | Unique comment identifier |
| `post_id` | INT | FK → posts(post_id), NOT NULL | — | Target post |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Comment author |
| `content` | TEXT | NOT NULL | — | Comment text |
| `created_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Comment creation timestamp |
| `active` | BOOLEAN | — | `TRUE` | Soft delete flag (0 = deleted) |

**Foreign Keys:** `post_id` → `posts(post_id)` ON DELETE CASCADE, `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Indexes:** PK on `comment_id`.

---

### 4. `hidden_comments`

Tracks which comments a specific user has hidden from their view.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `hidden_id` | INT | PK, AUTO_INCREMENT | — | Unique record identifier |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | User who hid the comment |
| `comment_id` | INT | FK → comments(comment_id), NOT NULL | — | Hidden comment |
| `hidden_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Timestamp of hide action |

**Foreign Keys:**  
`user_id` → `users(user_id)` ON DELETE CASCADE,  
`comment_id` → `comments(comment_id)` ON DELETE CASCADE.  
**Unique Constraint:** `(user_id, comment_id)` — a user can hide a given comment only once.  
**Indexes:** PK on `hidden_id`, UNIQUE on `(user_id, comment_id)`.

---

### 5. `likes`

Records likes (reactions) on posts by users. Enforces one like per user per post.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `like_id` | INT | PK, AUTO_INCREMENT | — | Unique like identifier |
| `post_id` | INT | FK → posts(post_id), NOT NULL | — | Liked post |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | User who liked |
| `liked_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Like timestamp |

**Foreign Keys:** `post_id` → `posts(post_id)` ON DELETE CASCADE, `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Unique Constraint:** `(post_id, user_id)` — prevents duplicate likes.  
**Indexes:** PK on `like_id`, UNIQUE on `(post_id, user_id)`.

---

### 6. `comment_likes`

Records likes (reactions) on comments by users. Enforces one like per user per comment.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `like_id` | INT | PK, AUTO_INCREMENT | — | Unique like identifier |
| `comment_id` | INT | FK → comments(comment_id), NOT NULL | — | Liked comment |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | User who liked |
| `liked_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Like timestamp |

**Foreign Keys:** `comment_id` → `comments(comment_id)` ON DELETE CASCADE, `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Unique Constraint:** `(comment_id, user_id)` — prevents duplicate likes on the same comment.  
**Indexes:** PK on `like_id`, UNIQUE on `(comment_id, user_id)`.

---

### 7. `replies`

Replies to comments. Each reply belongs to a parent comment. Supports soft delete via `active` flag.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `reply_id` | INT | PK, AUTO_INCREMENT | — | Unique reply identifier |
| `comment_id` | INT | FK → comments(comment_id), NOT NULL | — | Parent comment |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Reply author |
| `content` | TEXT | NOT NULL | — | Reply text |
| `created_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Reply creation timestamp |
| `active` | BOOLEAN | — | `TRUE` | Soft delete flag (0 = deleted) |

**Foreign Keys:** `comment_id` → `comments(comment_id)` ON DELETE CASCADE, `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Indexes:** PK on `reply_id`.

---

### 8. `friend_requests`

Manages the friend request workflow between two users.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `request_id` | INT | PK, AUTO_INCREMENT | — | Unique request identifier |
| `sender_id` | INT | FK → users(user_id), NOT NULL | — | User who sent the request |
| `receiver_id` | INT | FK → users(user_id), NOT NULL | — | User who received the request |
| `status` | VARCHAR(20) | — | `'pending'` | Request status: pending, accepted, rejected |
| `request_date` | DATETIME | — | `CURRENT_TIMESTAMP` | When request was sent |
| `response_date` | DATETIME | — | NULL | When request was accepted/rejected |

**Foreign Keys:** `sender_id` → `users(user_id)` ON DELETE CASCADE, `receiver_id` → `users(user_id)` ON DELETE CASCADE.  
**Indexes:** PK on `request_id`.

---

### 9. `friends`

Represents confirmed friendship pairs between two users.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `friendship_id` | INT | PK, AUTO_INCREMENT | — | Unique friendship identifier |
| `user_id1` | INT | FK → users(user_id), NOT NULL | — | First user in pair |
| `user_id2` | INT | FK → users(user_id), NOT NULL | — | Second user in pair |
| `friendship_date` | DATETIME | — | `CURRENT_TIMESTAMP` | When friendship was established |

**Foreign Keys:** `user_id1` → `users(user_id)` ON DELETE CASCADE, `user_id2` → `users(user_id)` ON DELETE CASCADE.  
**Unique Constraint:** `(user_id1, user_id2)` — prevents duplicate friendship pairs.  
**Indexes:** PK on `friendship_id`, UNIQUE on `(user_id1, user_id2)`.

---

### 10. `user_update_log`

Audit trail that records changes to user profile fields on every update.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `log_id` | INT | PK, AUTO_INCREMENT | — | Unique log entry identifier |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | User whose profile changed |
| `old_full_name` | VARCHAR(100) | — | NULL | Name before the update |
| `new_full_name` | VARCHAR(100) | — | NULL | Name after the update |
| `old_biography` | TEXT | — | NULL | Biography before the update |
| `new_biography` | TEXT | — | NULL | Biography after the update |
| `change_date` | DATETIME | — | `CURRENT_TIMESTAMP` | When the change occurred |

**Foreign Keys:** `user_id` → `users(user_id)` (NO cascading delete — history is preserved).  
**Indexes:** PK on `log_id`.

---

## Views

### `v_posts_stats`

Aggregated post view that joins author info from `users` and computes like/comment counts.

| Column | Source | Description |
|--------|--------|-------------|
| `post_id` | posts.post_id | Post identifier |
| `user_id` | posts.user_id | Author identifier |
| `content` | posts.content | Post text |
| `image` | posts.image | Post image |
| `created_at` | posts.created_at | Creation timestamp |
| `updated_at` | posts.updated_at | Last edit timestamp |
| `author_name` | users.full_name | Author display name |
| `author_picture` | users.profile_picture | Author avatar |
| `author_email` | users.email | Author email |
| `likes_count` | subquery (likes) | Total likes (0 if none) |
| `comments_count` | subquery (comments) | Total active comments (0 if none) |

Filters: Only active posts (`p.active = 1`). Ordered by `created_at DESC` (newest first).

---

## Triggers

### `trg_user_update_log`

**Event:** `BEFORE UPDATE ON users`  
**Purpose:** Automatically inserts a row into `user_update_log` capturing the old and new values of `full_name` and `biography` every time a user record is updated.

---

## Stored Procedures

### Authentication

| Procedure | Parameters | Description |
|-----------|------------|-------------|
| `sp_register_user` | `p_full_name`, `p_email`, `p_password`, `p_role` | Registers a new user. Raises error if email already exists. |
| `sp_login_user` | `p_email` | Returns user info for given email. Raises error if not found. |

### Posts

| Procedure | Parameters | Description |
|-----------|------------|-------------|
| `sp_create_post` | `p_user_id`, `p_content`, `p_image` | Creates a new post. `p_image` can be NULL. Returns the new `post_id`. |

### Likes

| Procedure | Parameters | Description |
|-----------|------------|-------------|
| `sp_add_like` | `p_post_id`, `p_user_id` | Adds a like (INSERT IGNORE — safe if already liked). Returns affected rows. |
| `sp_remove_like` | `p_post_id`, `p_user_id` | Removes a like. Returns affected rows. |
| `sp_get_like_count` | `p_post_id` | Returns total like count for a post. |
| `sp_has_liked` | `p_post_id`, `p_user_id` | Checks if a user has already liked a post. Returns boolean `has_liked`. |
| `sp_get_user_likes` | `p_user_id` | Returns all likes made by a user, joined with post content. |
| `sp_get_post_likers` | `p_post_id` | Returns all users who liked a given post with their profile info. |

### Comments

| Procedure | Parameters | Description |
|-----------|------------|-------------|
| `sp_create_comment` | `p_post_id`, `p_user_id`, `p_content` | Creates a new comment. Returns the new `comment_id`. |
| `sp_get_comments_by_post` | `p_post_id` | Returns all active comments on a post, with author info. |
| `sp_delete_comment` | `p_comment_id`, `p_user_id` | Soft-deletes a comment (sets `active = 0`). Only if the requesting user is the comment author. |
| `sp_get_comment_count` | `p_post_id` | Returns count of active comments on a post. |
| `sp_get_comment_by_id` | `p_comment_id` | Returns a single active comment with author info. |

---

## Constraints Summary

| Type | Table | Columns | Notes |
|------|-------|---------|-------|
| UNIQUE | `users` | `email` | No duplicate emails |
| UNIQUE | `likes` | `(post_id, user_id)` | One like per user per post |
| UNIQUE | `comment_likes` | `(comment_id, user_id)` | One like per user per comment |
| UNIQUE | `hidden_comments` | `(user_id, comment_id)` | One hide per user per comment |
| UNIQUE | `friends` | `(user_id1, user_id2)` | No duplicate friendship pairs |

All foreign keys use `ON DELETE CASCADE` except `user_update_log.user_id → users(user_id)` which preserves the audit history when users are deleted.

---

## Security Notes

- Passwords are stored as hashed strings (VARCHAR(255)). Hashing must be performed at the application layer before calling `sp_register_user`.
- `sp_login_user` returns the user record including the hashed password; password verification must be handled by the application.
- The trigger `trg_user_update_log` fires on **every** update to `users` — ensure the application is aware of this audit behavior.
