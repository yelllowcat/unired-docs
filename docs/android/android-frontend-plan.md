# 🧠 UniRed Android — Frontend Planning

## 1. Feature Map (from DB)

| Table | Feature it drives | Priority |
|---|---|---|
| `users` | Registration, login, profile view/edit, avatar | 🔴 Core |
| `posts` | Feed (timeline), create post (text + image) | 🔴 Core |
| `comments` | Comment on posts, view comment list | 🔴 Core |
| `replies` | Threaded replies under comments | 🟡 Nice-to-have |
| `likes` | Like/unlike a post, like count | 🔴 Core |
| `comment_likes` | Like/unlike a comment | 🟡 Nice-to-have |
| `hidden_comments` | Per-user hide a comment | 🟢 Stretch |
| `friend_requests` | Send / accept / reject friend request | 🟡 Nice-to-have |
| `friends` | Friends list, "is friend" badge | 🟡 Nice-to-have |
| `user_update_log` | Backend-only audit trail | ⚪ N/A on frontend |

---

## 2. Screens

### 🔴 MVP Screens (Phase 1)

| # | Screen | Description |
|---|---|---|
| 1 | **LoginScreen** | Email + password, calls `sp_login_user` |
| 2 | **RegisterScreen** | Name + email + password, calls `sp_register_user` |
| 3 | **FeedScreen** | Scrollable list of posts (from `v_posts_stats`), pull-to-refresh |
| 4 | **CreatePostScreen** | Text field + optional image picker |
| 5 | **PostDetailScreen** | Full post + comments list + add comment |
| 6 | **ProfileScreen** | User avatar, name, bio, their posts |

### 🟡 Phase 2 Screens

| # | Screen | Description |
|---|---|---|
| 7 | **EditProfileScreen** | Change name, bio, avatar |
| 8 | **FriendsScreen** | List friends, pending requests |
| 9 | **UserSearchScreen** | Find users, send friend request |

### 🟢 Stretch

| # | Screen | Description |
|---|---|---|
| 10 | **RepliesSheet** | Bottom sheet showing threaded replies |
| 11 | **NotificationsScreen** | Friend request + like notifications |

### Navigation Flow

```
Login ──→ success ──→ Feed
  │                    ├── tap post ──→ PostDetail ──→ tap avatar ──→ Profile
  │                    ├── FAB ──→ CreatePost
  │                    ├── bottom nav ──→ Profile ──→ EditProfile
  └── tap register     └── bottom nav ──→ Friends
      ──→ Register ──→ success ──→ Feed
```

---

## 3. Package Structure

```
com.unired/
├── MainActivity.kt              ← Single Activity, hosts NavHost
├── UniRedApp.kt                 ← @Composable entry (NavHost + Scaffold)
│
├── data/
│   ├── api/
│   │   ├── ApiClient.kt         ← Retrofit instance (base URL, interceptors)
│   │   ├── AuthApi.kt           ← login(), register()
│   │   ├── PostApi.kt           ← getFeed(), createPost(), likePost()…
│   │   ├── CommentApi.kt        ← getComments(), addComment(), deleteComment()
│   │   ├── UserApi.kt           ← getProfile(), updateProfile()
│   │   └── FriendApi.kt         ← sendRequest(), acceptRequest(), getFriends()
│   │
│   ├── model/                   ← Data classes matching API responses
│   │   ├── User.kt
│   │   ├── Post.kt
│   │   ├── Comment.kt
│   │   ├── Reply.kt
│   │   ├── FriendRequest.kt
│   │   └── AuthResponse.kt
│   │
│   └── repository/              ← Single source-of-truth per domain
│       ├── AuthRepository.kt
│       ├── PostRepository.kt
│       ├── CommentRepository.kt
│       ├── UserRepository.kt
│       └── FriendRepository.kt
│
├── ui/
│   ├── navigation/
│   │   ├── Screen.kt            ← Sealed class with routes
│   │   └── NavGraph.kt          ← NavHost wiring
│   │
│   ├── auth/
│   │   ├── LoginScreen.kt
│   │   ├── LoginViewModel.kt
│   │   ├── RegisterScreen.kt
│   │   └── RegisterViewModel.kt
│   │
│   ├── feed/
│   │   ├── FeedScreen.kt
│   │   ├── FeedViewModel.kt
│   │   └── PostCard.kt          ← Reusable post item composable
│   │
│   ├── post/
│   │   ├── CreatePostScreen.kt
│   │   ├── PostDetailScreen.kt
│   │   ├── PostDetailViewModel.kt
│   │   └── CommentItem.kt       ← Reusable comment composable
│   │
│   ├── profile/
│   │   ├── ProfileScreen.kt
│   │   ├── ProfileViewModel.kt
│   │   └── EditProfileScreen.kt
│   │
│   ├── friends/                  ← Phase 2
│   │   ├── FriendsScreen.kt
│   │   └── FriendsViewModel.kt
│   │
│   ├── components/               ← Shared composables
│   │   ├── LikeButton.kt
│   │   ├── AvatarImage.kt
│   │   ├── LoadingIndicator.kt
│   │   └── EmptyState.kt
│   │
│   └── theme/                    ← Already exists
│       ├── Color.kt
│       ├── Theme.kt
│       └── Type.kt
│
└── util/
    ├── SessionManager.kt        ← SharedPreferences wrapper (user token / id)
    └── DateFormatter.kt         ← "hace 2 horas" style formatting
```

---

## 4. Data Models

```kotlin
// Matches v_posts_stats view
data class Post(
    val postId: Int,
    val userId: Int,
    val content: String,
    val image: String?,           // nullable, maps to posts.image
    val createdAt: String,
    val authorName: String,       // from JOIN
    val authorPicture: String,    // from JOIN
    val likesCount: Int,
    val commentsCount: Int,
    val hasLiked: Boolean         // from sp_has_liked on client side
)

data class Comment(
    val commentId: Int,
    val postId: Int,
    val userId: Int,
    val content: String,
    val createdAt: String,
    val fullName: String,
    val profilePicture: String,
    val likesCount: Int = 0,      // from comment_likes
    val repliesCount: Int = 0
)

data class User(
    val userId: Int,
    val fullName: String,
    val biography: String?,
    val profilePicture: String,
    val email: String,
    val role: String,
    val registrationDate: String
)

data class FriendRequest(
    val requestId: Int,
    val senderId: Int,
    val receiverId: Int,
    val status: String,           // "pending" | "accepted" | "rejected"
    val requestDate: String,
    val responseDate: String?,
    val senderName: String?,      // populated by backend JOIN
    val senderPicture: String?
)

data class AuthResponse(
    val token: String,
    val user: User
)
```

---

## 5. Navigation Routes

```kotlin
sealed class Screen(val route: String) {
    object Login      : Screen("login")
    object Register   : Screen("register")
    object Feed       : Screen("feed")
    object CreatePost : Screen("create_post")
    object PostDetail : Screen("post/{postId}")
    object Profile    : Screen("profile/{userId}")
    object EditProfile: Screen("edit_profile")
    object Friends    : Screen("friends")
}
```

---

## 6. Dependencies to Add

```toml
# libs.versions.toml additions
[versions]
navigation = "2.8.9"
retrofit = "2.11.0"
okhttp = "4.12.0"
gson = "2.11.0"
coil = "2.7.0"

[libraries]
# Navigation
androidx-navigation-compose = { module = "androidx.navigation:navigation-compose", version.ref = "navigation" }

# Networking
retrofit-core = { module = "com.squareup.retrofit2:retrofit", version.ref = "retrofit" }
retrofit-gson = { module = "com.squareup.retrofit2:converter-gson", version.ref = "retrofit" }
okhttp-logging = { module = "com.squareup.okhttp3:logging-interceptor", version.ref = "okhttp" }

# Image loading
coil-compose = { module = "io.coil-kt:coil-compose", version.ref = "coil" }

# Serialization
gson = { module = "com.google.code.gson:gson", version.ref = "gson" }
```

---

## 7. Architecture

```
┌─────────────────────────────────────────────────┐
│                  UI Layer                       │
│  Screens (Composables) ← observe → ViewModels  │
└────────────────────┬────────────────────────────┘
                     │ calls
┌────────────────────▼────────────────────────────┐
│               Data Layer                        │
│  Repositories → Retrofit API interfaces         │
└────────────────────┬────────────────────────────┘
                     │ HTTP
┌────────────────────▼────────────────────────────┐
│           Express/Prisma Backend                │
│      (calls stored procedures in MySQL)         │
└─────────────────────────────────────────────────┘
```

- **MVVM** — each screen has its own ViewModel
- **Repository pattern** — ViewModels never touch Retrofit directly
- **StateFlow** — ViewModels expose `StateFlow<UiState>` consumed by Compose
- **Single Activity** — `MainActivity` only hosts the `NavHost`
- **No DI framework** — manual dependency injection via `ViewModelProvider.Factory` (school-project simple)
- **No Room** — all data comes from the backend API, no local caching

---

## 8. Open Questions

- **Backend**: Is the Express/Prisma backend already built, or do we need to define the REST API contract first?
- **Auth mechanism**: Simple JWT token returned on login and stored in SharedPreferences/DataStore? Or session-based?
- **Image uploads**: Will images be uploaded to the backend (multipart) or to a third-party service?
- **Scope for grading**: Which features are required for the school project deliverable vs. stretch goals?
