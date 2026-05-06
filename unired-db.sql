CREATE DATABASE IF NOT EXISTS unired_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE unired_DB;

-- TABLA users
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    biography TEXT,
    profile_picture VARCHAR(255) DEFAULT 'default_avatar.png',
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    role VARCHAR(20) DEFAULT 'user',
    active BOOLEAN DEFAULT TRUE,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- TABLA posts
CREATE TABLE IF NOT EXISTS posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    image VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABLA comments
CREATE TABLE IF NOT EXISTS comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABLA hidden_comments
CREATE TABLE IF NOT EXISTS hidden_comments (
    hidden_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    comment_id INT NOT NULL,
    hidden_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE,
    UNIQUE (user_id, comment_id)
) ENGINE=InnoDB;

-- TABLA likes
CREATE TABLE IF NOT EXISTS likes (
    like_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    liked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE (post_id, user_id)
) ENGINE=InnoDB;

-- TABLA friend_requests
CREATE TABLE IF NOT EXISTS friend_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    request_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    response_date DATETIME,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABLA friends (parejas de amistad)
CREATE TABLE IF NOT EXISTS friends (
    friendship_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id1 INT NOT NULL,
    user_id2 INT NOT NULL,
    friendship_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id1) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id2) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE (user_id1, user_id2)
) ENGINE=InnoDB;

-- TABLA user_update_log
CREATE TABLE IF NOT EXISTS user_update_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    old_full_name VARCHAR(100),
    new_full_name VARCHAR(100),
    old_biography TEXT,
    new_biography TEXT,
    change_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- Comprobaciones básicas (puedes descomentar si deseas ver resultados)
-- SELECT * FROM users;
-- SELECT * FROM posts;
-- SELECT * FROM comments;
-- SELECT * FROM likes;
-- SELECT * FROM hidden_comments;
-- SELECT * FROM friend_requests;
-- SELECT * FROM friends;
-- SELECT * FROM user_update_log;

-- ---------------------------------------------------
-- Procedimientos almacenados (2 ejemplos)
DELIMITER $$
CREATE PROCEDURE sp_register_user(
    IN p_full_name VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(255),
    IN p_role VARCHAR(20)
)
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El correo ya está registrado';
    ELSE
        INSERT INTO users (full_name, email, password, role)
        VALUES (p_full_name, p_email, p_password, p_role);
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_login_user(
    IN p_email VARCHAR(100)
)
BEGIN
    DECLARE user_exists INT;
    SELECT COUNT(*) INTO user_exists FROM users WHERE email = p_email;
    IF user_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo no encontrado';
    ELSE
        SELECT user_id, full_name, email, role, registration_date, active FROM users WHERE email = p_email;
    END IF;
END$$
DELIMITER ;

-- -------------------store procedure of likes-------------------------------

-- Procedimiento para agregar un like
DELIMITER $$
CREATE PROCEDURE sp_add_like(
    IN p_post_id INT,
    IN p_user_id INT
)
BEGIN
    INSERT IGNORE INTO likes (post_id, user_id, liked_at) 
    VALUES (p_post_id, p_user_id, NOW());
    
    SELECT ROW_COUNT() AS affected_rows;
END$$
DELIMITER ;

-- Procedimiento para eliminar un like
DELIMITER $$
CREATE PROCEDURE sp_remove_like(
    IN p_post_id INT,
    IN p_user_id INT
)
BEGIN
    DELETE FROM likes 
    WHERE post_id = p_post_id AND user_id = p_user_id;
    
    SELECT ROW_COUNT() AS affected_rows;
END$$
DELIMITER ;

-- Procedimiento para obtener el conteo de likes de un post
DELIMITER $$
CREATE PROCEDURE sp_get_like_count(
    IN p_post_id INT
)
BEGIN
    SELECT COUNT(*) as like_count 
    FROM likes 
    WHERE post_id = p_post_id;
END$$
DELIMITER ;

-- Procedimiento para verificar si un usuario ya dio like a un post
DELIMITER $$
CREATE PROCEDURE sp_has_liked(
    IN p_post_id INT,
    IN p_user_id INT
)
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM likes 
        WHERE post_id = p_post_id AND user_id = p_user_id
    ) as has_liked;
END$$
DELIMITER ;

-- Procedimiento para obtener todos los likes de un usuario
DELIMITER $$
CREATE PROCEDURE sp_get_user_likes(
    IN p_user_id INT
)
BEGIN
    SELECT l.*, p.content as post_content
    FROM likes l
    JOIN posts p ON l.post_id = p.post_id
    WHERE l.user_id = p_user_id
    ORDER BY l.liked_at DESC;
END$$
DELIMITER ;

-- Procedimiento para obtener los usuarios que dieron like a un post
DELIMITER $$
CREATE PROCEDURE sp_get_post_likers(
    IN p_post_id INT
)
BEGIN
    SELECT u.user_id, u.full_name, u.profile_picture, l.liked_at
    FROM likes l
    JOIN users u ON l.user_id = u.user_id
    WHERE l.post_id = p_post_id
    ORDER BY l.liked_at DESC;
END$$
DELIMITER ;

-- ---------------------------store procedure of comments-------------------------------

-- Procedimiento para crear un comentario
DELIMITER $$
CREATE PROCEDURE sp_create_comment(
    IN p_post_id INT,
    IN p_user_id INT,
    IN p_content TEXT
)
BEGIN
    INSERT INTO comments (post_id, user_id, content, created_at) 
    VALUES (p_post_id, p_user_id, p_content, NOW());
    
    SELECT LAST_INSERT_ID() as comment_id;
END$$
DELIMITER ;

-- Procedimiento para obtener comentarios de un post
DELIMITER $$
CREATE PROCEDURE sp_get_comments_by_post(
    IN p_post_id INT
)
BEGIN
    SELECT c.*, u.full_name, u.profile_picture 
    FROM comments c 
    JOIN users u ON c.user_id = u.user_id 
    WHERE c.post_id = p_post_id AND c.active = 1 
    ORDER BY c.created_at ASC;
END$$
DELIMITER ;

-- Procedimiento para eliminar (soft delete) un comentario
DELIMITER $$
CREATE PROCEDURE sp_delete_comment(
    IN p_comment_id INT,
    IN p_user_id INT
)
BEGIN
    UPDATE comments 
    SET active = 0 
    WHERE comment_id = p_comment_id AND user_id = p_user_id;
    
    SELECT ROW_COUNT() AS affected_rows;
END$$
DELIMITER ;

-- Procedimiento para obtener el conteo de comentarios de un post
DELIMITER $$
CREATE PROCEDURE sp_get_comment_count(
    IN p_post_id INT
)
BEGIN
    SELECT COUNT(*) as comment_count 
    FROM comments 
    WHERE post_id = p_post_id AND active = 1;
END$$
DELIMITER ;

-- Procedimiento para obtener un comentario específico
DELIMITER $$
CREATE PROCEDURE sp_get_comment_by_id(
    IN p_comment_id INT
)
BEGIN
    SELECT c.*, u.full_name, u.profile_picture 
    FROM comments c 
    JOIN users u ON c.user_id = u.user_id 
    WHERE c.comment_id = p_comment_id AND c.active = 1;
END$$
DELIMITER ;

-- --------------------------------store procedure of posts-----------------------------------------------

-- Procedimiento para crear post (con o sin imagen)
DELIMITER $$
CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT,
    IN p_image VARCHAR(255)
)
BEGIN
    INSERT INTO posts (user_id, content, image, created_at, updated_at) 
    VALUES (p_user_id, p_content, p_image, NOW(), NOW());
    
    SELECT LAST_INSERT_ID() as post_id;
END$$
DELIMITER ;



-- ---------------------------------------------------
-- Trigger: registrar historial antes de update en users
DELIMITER $$
CREATE TRIGGER trg_user_update_log
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    INSERT INTO user_update_log (
        user_id,
        old_full_name, new_full_name,
        old_biography, new_biography
    ) VALUES (
        OLD.user_id,
        OLD.full_name, NEW.full_name,
        OLD.biography, NEW.biography
    );
END$$
DELIMITER ;

-- ---------------------------------------------------
-- Vista: posts con información
CREATE OR REPLACE VIEW v_posts_stats AS
SELECT 
    p.post_id,
    p.user_id,
    p.content,
    p.image,
    p.created_at,
    p.updated_at,
    u.full_name AS author_name,
    u.profile_picture AS author_picture,
    u.email AS author_email,
    IFNULL(l.likes_count, 0) AS likes_count,
    IFNULL(c.comments_count, 0) AS comments_count
FROM posts p
INNER JOIN users u ON p.user_id = u.user_id
LEFT JOIN (
    SELECT post_id, COUNT(*) AS likes_count
    FROM likes
    GROUP BY post_id
) l ON p.post_id = l.post_id
LEFT JOIN (
    SELECT post_id, COUNT(*) AS comments_count
    FROM comments
    WHERE active = 1
    GROUP BY post_id
) c ON p.post_id = c.post_id
WHERE p.active = 1
ORDER BY p.created_at DESC;
