-- =====================================================================
-- Archivo:  mini-crud/database.sql
-- Proyecto: Mini CRUD de usuarios (demostración basada en FacturApp)
--
-- Qué hace:
--   1. Crea la base de datos "mini_crud" si no existe.
--   2. Crea la tabla "usuarios" (la borra antes si ya existía).
--   3. Inserta 3 usuarios de ejemplo para la demostración.
--
-- ¡ATENCIÓN! Ejecutarlo de nuevo BORRA la tabla y deja solo los 3
-- usuarios de ejemplo. Sirve para empezar la demostración "limpia".
--
-- Cómo se ejecuta:
--   - phpMyAdmin: pestaña "Importar" y elegir este archivo.
--   - Consola (CMD), desde la carpeta mini-crud:
--       C:\AppServ\MySQL\bin\mysql.exe -u root --default-character-set=utf8mb4 < database.sql
--
-- Conceptos:
--   - PRIMARY KEY: identifica cada fila; no se repite.
--   - AUTO_INCREMENT: MySQL le pone el número solo (1, 2, 3...).
--   - UNIQUE: el valor no se puede repetir (dos usuarios no pueden tener el mismo correo).
--   - NOT NULL: el dato es obligatorio.
--   - DEFAULT CURRENT_TIMESTAMP: si no se envía la fecha, MySQL pone la actual.
-- =====================================================================

-- 1. La base de datos. utf8mb4 guarda bien las tildes y la ñ.
CREATE DATABASE IF NOT EXISTS mini_crud
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mini_crud;

-- 2. La tabla. Se borra primero para poder ejecutar el archivo varias veces.
DROP TABLE IF EXISTS usuarios;

CREATE TABLE usuarios (
    -- Número que identifica a cada usuario; lo pone MySQL.
    id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Nombre de la persona; obligatorio.
    nombre    VARCHAR(100) NOT NULL,
    -- Correo; obligatorio y sin repetirse.
    correo    VARCHAR(150) NOT NULL,
    -- Fecha y hora en que se creó; la pone MySQL.
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_usuarios PRIMARY KEY (id),
    CONSTRAINT uq_usuarios_correo UNIQUE (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Datos de ejemplo para la demostración (nombres y correos ficticios).
INSERT INTO usuarios (nombre, correo) VALUES
    ('Laura Gómez',  'laura.gomez@ejemplo.test'),
    ('Andrés Muñoz', 'andres.munoz@ejemplo.test'),
    ('Marta Rincón', 'marta.rincon@ejemplo.test');

-- Comprobación: debe mostrar los 3 usuarios.
SELECT id, nombre, correo, creado_en FROM usuarios;
