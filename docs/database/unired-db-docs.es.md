# Documentación de la Base de Datos Unired

> **Base de datos:** `unired_DB`  
> **Motor:** InnoDB  
> **Charset:** `utf8mb4` / Collation: `utf8mb4_unicode_ci`

---

## Diagrama Entidad-Relación

```
┌──────────────┐       ┌──────────────┐       ┌────────────────────┐
│    users     │       │    posts     │       │     comments       │
│──────────────│       │──────────────│       │────────────────────│
│ PK user_id   │──┐    │ PK post_id   │──┐    │ PK comment_id      │
│ full_name    │  │    │ FK user_id ──┘  │    │ FK post_id ────────┘
│ biography    │  │    │ content        │    │ FK user_id ────────┐
│ profile_pic  │  │    │ image          │    │ content            │
│ email        │  │    │ created_at     │    │ created_at         │
│ password     │  │    │ updated_at     │    │ active (borrado    │
│ role         │  │    │ active         │    │   lógico)          │
│ active       │  │    └────────────────┘    └────────┬───────────┘
│ reg_date     │  │              │                    │
│ updated_at   │  │              │                    │
└──────┬───────┘  │              │                    │
       │          │              │                    │
       ├──────────┼──────────────┼────────────────────┘
       │          │              │
       ▼          ▼              ▼
┌──────────────┐ ┌──────────┐ ┌──────────────────┐
│    likes     │ │ sol_amist│ │ hidden_comments  │
│──────────────│ │──────────│ │──────────────────│
│ PK like_id   │ │ PK sol_id│ │ PK hidden_id     │
│ FK post_id ──┘ │ sende... │ │ FK user_id       │
│ FK user_id ────││ receive..│ │ FK comment_id ───┘
│ liked_at      │ │ estado   │ │ ocultado_en      │
│ UNIQUE(post,  │ │ fec_solic│ │ UNIQUE(usuario,  │
│   usuario)    │ │ fec_resp │ │   comentario)    │
└──────────────┘ └──────────┘ └──────────────────┘

┌──────────────────┐  ┌──────────────┐
│ comment_likes    │  │   replies    │
│──────────────────│  │──────────────│
│ PK like_id       │  │ PK reply_id  │
│ FK comment_id ───┤  │ FK comment_id│
│ FK user_id ──────┤  │ FK user_id   │
│ liked_at         │  │ content      │
│ UNIQUE(comment,  │  │ created_at   │
│   usuario)       │  │ active       │
└──────────────────┘  └──────────────┘

┌──────────────┐   ┌────────────────────┐
│   friends    │   │ user_update_log    │
│──────────────│   │────────────────────│
│ PK amistad_id│   │ PK log_id          │
│ FK user_id1 ─┼───│ FK user_id         │
│ FK user_id2 ─┼───│ nom_anterior/nuevo │
│ fec_amistad  │   │ biog_anterior/nuevo│
│ UNIQUE(u1,u2)│   │ fec_cambio         │
└──────────────┘   └────────────────────┘

Leyenda:
  PK = Clave Primaria
  FK = Clave Foránea
  ── = referencia
```

---

## Tablas

### 1. `users` (Usuarios)

Almacena la información de cuentas y perfiles de usuario.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `user_id` | INT | PK, AUTO_INCREMENT | — | Identificador único del usuario |
| `full_name` | VARCHAR(100) | NOT NULL | — | Nombre completo para mostrar |
| `biography` | TEXT | — | NULL | Biografía o texto de perfil |
| `profile_picture` | VARCHAR(255) | — | `'default_avatar.png'` | Ruta/nombre de la imagen de perfil |
| `email` | VARCHAR(100) | UNIQUE, NOT NULL | — | Correo electrónico del usuario |
| `password` | VARCHAR(255) | NOT NULL | — | Contraseña hasheada |
| `registration_date` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha de creación de la cuenta |
| `role` | VARCHAR(20) | — | `'user'` | Rol del usuario (ej. user, admin) |
| `active` | BOOLEAN | — | `TRUE` | Estado activo de la cuenta |
| `updated_at` | DATETIME | — | `CURRENT_TIMESTAMP ON UPDATE` | Fecha de última modificación |

**Índices:** PK en `user_id`, UNIQUE en `email`.

---

### 2. `posts` (Publicaciones)

Publicaciones creadas por los usuarios, con texto y opcionalmente una imagen.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `post_id` | INT | PK, AUTO_INCREMENT | — | Identificador único de la publicación |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Autor de la publicación |
| `content` | TEXT | NOT NULL | — | Contenido de texto de la publicación |
| `image` | VARCHAR(255) | — | NULL | Ruta/nombre de imagen opcional |
| `created_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha de creación |
| `updated_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha de última edición |
| `active` | BOOLEAN | — | `TRUE` | Bandera de borrado lógico |

**Claves foráneas:** `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Índices:** PK en `post_id`.

---

### 3. `comments` (Comentarios)

Comentarios en las publicaciones. Soporta borrado lógico mediante la bandera `active`.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `comment_id` | INT | PK, AUTO_INCREMENT | — | Identificador único del comentario |
| `post_id` | INT | FK → posts(post_id), NOT NULL | — | Publicación destino |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Autor del comentario |
| `content` | TEXT | NOT NULL | — | Texto del comentario |
| `created_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha de creación |
| `active` | BOOLEAN | — | `TRUE` | Bandera de borrado lógico (0 = eliminado) |

**Claves foráneas:** `post_id` → `posts(post_id)` ON DELETE CASCADE, `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Índices:** PK en `comment_id`.

---

### 4. `hidden_comments` (Comentarios ocultos)

Registra qué comentarios ha ocultado un usuario específico de su vista.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `hidden_id` | INT | PK, AUTO_INCREMENT | — | Identificador único del registro |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Usuario que ocultó el comentario |
| `comment_id` | INT | FK → comments(comment_id), NOT NULL | — | Comentario ocultado |
| `hidden_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha en que se ocultó |

**Claves foráneas:**  
`user_id` → `users(user_id)` ON DELETE CASCADE,  
`comment_id` → `comments(comment_id)` ON DELETE CASCADE.  
**Restricción única:** `(user_id, comment_id)` — un usuario solo puede ocultar un comentario una vez.  
**Índices:** PK en `hidden_id`, UNIQUE en `(user_id, comment_id)`.

---

### 5. `likes` (Me gusta)

Registra los "me gusta" (reacciones) en publicaciones. Impone un like por usuario por publicación.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `like_id` | INT | PK, AUTO_INCREMENT | — | Identificador único del like |
| `post_id` | INT | FK → posts(post_id), NOT NULL | — | Publicación a la que se dio like |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Usuario que dio like |
| `liked_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha del like |

**Claves foráneas:** `post_id` → `posts(post_id)` ON DELETE CASCADE, `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Restricción única:** `(post_id, user_id)` — evita likes duplicados.  
**Índices:** PK en `like_id`, UNIQUE en `(post_id, user_id)`.

---

### 6. `comment_likes` (Me gusta en comentarios)

Registra los "me gusta" (reacciones) en comentarios. Impone un like por usuario por comentario.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `like_id` | INT | PK, AUTO_INCREMENT | — | Identificador único del like |
| `comment_id` | INT | FK → comments(comment_id), NOT NULL | — | Comentario al que se dio like |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Usuario que dio like |
| `liked_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha del like |

**Claves foráneas:** `comment_id` → `comments(comment_id)` ON DELETE CASCADE, `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Restricción única:** `(comment_id, user_id)` — evita likes duplicados en el mismo comentario.  
**Índices:** PK en `like_id`, UNIQUE en `(comment_id, user_id)`.

---

### 7. `replies` (Respuestas)

Respuestas a comentarios. Cada respuesta pertenece a un comentario padre. Soporta borrado lógico mediante la bandera `active`.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `reply_id` | INT | PK, AUTO_INCREMENT | — | Identificador único de la respuesta |
| `comment_id` | INT | FK → comments(comment_id), NOT NULL | — | Comentario padre |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Autor de la respuesta |
| `content` | TEXT | NOT NULL | — | Texto de la respuesta |
| `created_at` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha de creación |
| `active` | BOOLEAN | — | `TRUE` | Bandera de borrado lógico (0 = eliminado) |

**Claves foráneas:** `comment_id` → `comments(comment_id)` ON DELETE CASCADE, `user_id` → `users(user_id)` ON DELETE CASCADE.  
**Índices:** PK en `reply_id`.

---

### 8. `friend_requests` (Solicitudes de amistad)

Gestiona el flujo de solicitudes de amistad entre dos usuarios.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `request_id` | INT | PK, AUTO_INCREMENT | — | Identificador único de la solicitud |
| `sender_id` | INT | FK → users(user_id), NOT NULL | — | Usuario que envió la solicitud |
| `receiver_id` | INT | FK → users(user_id), NOT NULL | — | Usuario que recibió la solicitud |
| `status` | VARCHAR(20) | — | `'pending'` | Estado: pending, accepted, rejected |
| `request_date` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha de envío |
| `response_date` | DATETIME | — | NULL | Fecha de aceptación/rechazo |

**Claves foráneas:** `sender_id` → `users(user_id)` ON DELETE CASCADE, `receiver_id` → `users(user_id)` ON DELETE CASCADE.  
**Índices:** PK en `request_id`.

---

### 9. `friends` (Amistades)

Representa los pares de amistad confirmada entre dos usuarios.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `friendship_id` | INT | PK, AUTO_INCREMENT | — | Identificador único de la amistad |
| `user_id1` | INT | FK → users(user_id), NOT NULL | — | Primer usuario del par |
| `user_id2` | INT | FK → users(user_id), NOT NULL | — | Segundo usuario del par |
| `friendship_date` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha en que se estableció la amistad |

**Claves foráneas:** `user_id1` → `users(user_id)` ON DELETE CASCADE, `user_id2` → `users(user_id)` ON DELETE CASCADE.  
**Restricción única:** `(user_id1, user_id2)` — evita pares de amistad duplicados.  
**Índices:** PK en `friendship_id`, UNIQUE en `(user_id1, user_id2)`.

---

### 10. `user_update_log` (Registro de cambios de usuario)

Bitácora de auditoría que registra los cambios en los campos de perfil cada vez que se actualiza un usuario.

| Columna | Tipo | Restricciones | Valor por defecto | Descripción |
|---------|------|---------------|-------------------|-------------|
| `log_id` | INT | PK, AUTO_INCREMENT | — | Identificador único del registro |
| `user_id` | INT | FK → users(user_id), NOT NULL | — | Usuario cuyo perfil cambió |
| `old_full_name` | VARCHAR(100) | — | NULL | Nombre antes de la actualización |
| `new_full_name` | VARCHAR(100) | — | NULL | Nombre después de la actualización |
| `old_biography` | TEXT | — | NULL | Biografía antes de la actualización |
| `new_biography` | TEXT | — | NULL | Biografía después de la actualización |
| `change_date` | DATETIME | — | `CURRENT_TIMESTAMP` | Fecha del cambio |

**Claves foráneas:** `user_id` → `users(user_id)` (SIN borrado en cascada — se preserva el historial).  
**Índices:** PK en `log_id`.

---

## Vistas

### `v_posts_stats`

Vista agregada de publicaciones que une información de autor desde `users` y calcula conteos de likes y comentarios.

| Columna | Origen | Descripción |
|---------|--------|-------------|
| `post_id` | posts.post_id | Identificador de la publicación |
| `user_id` | posts.user_id | Identificador del autor |
| `content` | posts.content | Texto de la publicación |
| `image` | posts.image | Imagen de la publicación |
| `created_at` | posts.created_at | Fecha de creación |
| `updated_at` | posts.updated_at | Fecha de última edición |
| `author_name` | users.full_name | Nombre del autor |
| `author_picture` | users.profile_picture | Avatar del autor |
| `author_email` | users.email | Correo del autor |
| `likes_count` | subconsulta (likes) | Total de likes (0 si ninguno) |
| `comments_count` | subconsulta (comments) | Total de comentarios activos (0 si ninguno) |

Filtros: Solo publicaciones activas (`p.active = 1`). Ordenado por `created_at DESC` (más recientes primero).

---

## Triggers (Disparadores)

### `trg_user_update_log`

**Evento:** `BEFORE UPDATE ON users`  
**Propósito:** Inserta automáticamente una fila en `user_update_log` capturando los valores anteriores y nuevos de `full_name` y `biography` cada vez que se actualiza un registro de usuario.

---

## Procedimientos Almacenados

### Autenticación

| Procedimiento | Parámetros | Descripción |
|---------------|------------|-------------|
| `sp_register_user` | `p_full_name`, `p_email`, `p_password`, `p_role` | Registra un nuevo usuario. Lanza error si el correo ya existe. |
| `sp_login_user` | `p_email` | Devuelve los datos del usuario para el correo dado. Lanza error si no se encuentra. |

### Publicaciones

| Procedimiento | Parámetros | Descripción |
|---------------|------------|-------------|
| `sp_create_post` | `p_user_id`, `p_content`, `p_image` | Crea una nueva publicación. `p_image` puede ser NULL. Retorna el `post_id` generado. |

### Likes (Me gusta)

| Procedimiento | Parámetros | Descripción |
|---------------|------------|-------------|
| `sp_add_like` | `p_post_id`, `p_user_id` | Agrega un like (INSERT IGNORE — seguro si ya existe). Retorna filas afectadas. |
| `sp_remove_like` | `p_post_id`, `p_user_id` | Elimina un like. Retorna filas afectadas. |
| `sp_get_like_count` | `p_post_id` | Retorna el conteo total de likes de una publicación. |
| `sp_has_liked` | `p_post_id`, `p_user_id` | Verifica si un usuario ya dio like a una publicación. Retorna booleano `has_liked`. |
| `sp_get_user_likes` | `p_user_id` | Retorna todos los likes de un usuario, con el contenido de las publicaciones. |
| `sp_get_post_likers` | `p_post_id` | Retorna todos los usuarios que dieron like a una publicación, con info de perfil. |

### Comentarios

| Procedimiento | Parámetros | Descripción |
|---------------|------------|-------------|
| `sp_create_comment` | `p_post_id`, `p_user_id`, `p_content` | Crea un nuevo comentario. Retorna el `comment_id` generado. |
| `sp_get_comments_by_post` | `p_post_id` | Retorna todos los comentarios activos de una publicación, con datos del autor. |
| `sp_delete_comment` | `p_comment_id`, `p_user_id` | Borrado lógico de un comentario (`active = 0`). Solo si el usuario solicitante es el autor. |
| `sp_get_comment_count` | `p_post_id` | Retorna el conteo de comentarios activos en una publicación. |
| `sp_get_comment_by_id` | `p_comment_id` | Retorna un comentario específico activo con datos del autor. |

---

## Resumen de Restricciones

| Tipo | Tabla | Columnas | Notas |
|------|-------|----------|-------|
| UNIQUE | `users` | `email` | Sin correos duplicados |
| UNIQUE | `likes` | `(post_id, user_id)` | Un like por usuario por publicación |
| UNIQUE | `comment_likes` | `(comment_id, user_id)` | Un like por usuario por comentario |
| UNIQUE | `hidden_comments` | `(user_id, comment_id)` | Un ocultamiento por usuario por comentario |
| UNIQUE | `friends` | `(user_id1, user_id2)` | Sin pares de amistad duplicados |

Todas las claves foráneas usan `ON DELETE CASCADE` excepto `user_update_log.user_id → users(user_id)` que preserva el historial de auditoría al eliminar usuarios.

---

## Notas de Seguridad

- Las contraseñas se almacenan como cadenas hasheadas (VARCHAR(255)). El hashing debe realizarse en la capa de aplicación antes de llamar a `sp_register_user`.
- `sp_login_user` retorna el registro del usuario incluyendo la contraseña hasheada; la verificación de contraseña debe manejarse en la aplicación.
- El trigger `trg_user_update_log` se dispara en **cada** actualización de `users` — la aplicación debe ser consciente de este comportamiento de auditoría.
