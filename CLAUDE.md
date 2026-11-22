# CONTEXTO DEL PROYECTO: mini-crud

## Qué es y para qué
Mini proyecto de DEMOSTRACIÓN para una exposición del SENA (programa ADSO). La tarea del profesor: **montar un servidor y demostrar desde Postman que los endpoints funcionan**.
El usuario es principiante: todo debe ser sencillo, explicable línea por línea y con comentarios para principiantes.
Es una versión mínima inspirada en el proyecto grande `C:\AppServ\www\facturApp` (repositorio https://github.com/DaniWapp/factuApp). **No se modifica facturApp desde aquí.**

- Repositorio: https://github.com/DaniWapp/mini-crud (rama `main`).
- Carpeta: `C:\AppServ\www\mini-crud`.

## Stack
- Python 3.12.10, FastAPI 0.165.0, Uvicorn 0.54.0, PyMySQL 1.2.4, python-dotenv 1.2.4 (versiones fijas en `requirements.txt`).
- MySQL 8.0.17 de AppServ (`C:\AppServ\MySQL`). También debe funcionar con la MariaDB de XAMPP.
- Sin capas, sin login, sin roles, sin ORM: SQL directo con parámetros `%s`.

## Base de datos
- Base `mini_crud`, tabla `usuarios`: `id` (INT UNSIGNED, AUTO_INCREMENT, PK), `nombre` (VARCHAR 100, NOT NULL), `correo` (VARCHAR 150, NOT NULL, UNIQUE), `creado_en` (DATETIME, DEFAULT CURRENT_TIMESTAMP).
- `database.sql` crea la base, BORRA y crea la tabla, e inserta 3 usuarios de ejemplo (Laura Gómez, Andrés Muñoz, Marta Rincón). Ejecutarlo de nuevo deja la base limpia y los id empiezan otra vez en 4.
- Usuario de MySQL del proyecto: `mini_crud` (en `localhost` y `127.0.0.1`, `mysql_native_password`), con permisos SOLO sobre la base `mini_crud`. Su contraseña está en `.env` (no se sube a GitHub). `root` no tiene contraseña en AppServ y solo se usa para crear la base y el usuario.

## Archivos
```
mini-crud/
├── main.py            Servidor FastAPI con los 6 endpoints
├── conexion.py        obtener_conexion(): lee .env y conecta con PyMySQL (DictCursor, autocommit)
├── database.sql       Crea la base, la tabla y 3 usuarios de ejemplo
├── requirements.txt   4 librerías con versión fija
├── .env.example       Plantilla sin valores reales (sí se sube)
├── .env               Valores reales (NO se sube; .gitignore lo excluye)
├── .gitignore         .env, .venv/, __pycache__/, *.pyc, .pytest_cache/
├── TUTORIAL.md        Guía paso a paso para que el usuario repita todo desde cero
└── .venv/             Entorno virtual (no se sube)
```

## Endpoints (main.py)
| Método | Ruta | Respuestas |
|---|---|---|
| GET | `/salud` | 200 `{"estado": "ok"}` |
| GET | `/usuarios` | 200 (lista, ordenada por id) |
| GET | `/usuarios/{id}` | 200, 404 "El usuario no existe." |
| POST | `/usuarios` | 201, 409 "Ya existe un usuario con ese correo.", 422 datos incompletos |
| PUT | `/usuarios/{id}` | 200, 404, 409, 422 |
| DELETE | `/usuarios/{id}` | 204, 404 — BORRA DE VERDAD (decisión del usuario) |
- El correo se guarda en minúsculas y sin espacios en los extremos.
- Los errores usan el formato por defecto de FastAPI: `{"detail": "..."}` (a propósito, para que sea sencillo).

## Cómo arrancar
1. Encender MySQL (ventana aparte, dejarla abierta):
   `& "C:\AppServ\MySQL\bin\mysqld.exe" --defaults-file="C:\AppServ\MySQL\my.ini" --console`
   Apagarlo bien: `& "C:\AppServ\MySQL\bin\mysqladmin.exe" -u root shutdown`
2. Servidor, desde `C:\AppServ\www\mini-crud`:
   `.\.venv\Scripts\python.exe -m uvicorn main:app --reload --port 8000`
3. Probar: http://localhost:8000/salud y http://localhost:8000/docs (plan B si Postman falla).
4. Dejar la base limpia antes de demostrar:
   `cmd /c "C:\AppServ\MySQL\bin\mysql.exe -u root --default-character-set=utf8mb4 < database.sql"`

## Estado actual (2026-11-22)
- Etapa 1 (base de datos): TERMINADA y probada.
- Etapa 2 (servidor): TERMINADA y probada con el servidor encendido (los 6 endpoints, incluidos 404, 409 y 422).
- TUTORIAL.md: etapas 1 y 2 escritas (con el código completo de los archivos).
- La base `mini_crud` está limpia (3 usuarios de ejemplo).
- Postman: NO estaba instalado en este equipo (descarga: https://www.postman.com/downloads/). Confirmar con el usuario si ya lo instaló.

## Pendiente
### Etapa 3: colección de Postman (siguiente)
Crear `mini-crud.postman_collection.json` (formato Postman v2.1) con:
- Variable de colección `base_url` = `http://localhost:8000` y variable `usuario_id`.
- 9 peticiones en este orden, cada una con una prueba (`pm.test`) del código esperado:
  1. GET `/salud` → 200
  2. GET `/usuarios` → 200 (3 usuarios)
  3. POST `/usuarios` → 201; guarda el `id` de la respuesta en `usuario_id` (`pm.collectionVariables.set`)
  4. GET `/usuarios/{{usuario_id}}` → 200
  5. PUT `/usuarios/{{usuario_id}}` → 200
  6. POST `/usuarios` con un correo existente → 409
  7. POST `/usuarios` sin nombre → 422
  8. DELETE `/usuarios/{{usuario_id}}` → 204
  9. GET `/usuarios/{{usuario_id}}` → 404
- Debe poder ejecutarse completa con "Run collection" y quedar todo en verde.
- Agregar al TUTORIAL.md la etapa 3: instalar Postman, importar la colección, enviar cada petición y usar Run collection.

### Etapa 4: pruebas y exposición
- `test_usuarios.py` con pytest (opcional para la exposición; agregar pytest y httpx a requirements.txt con versión fija). Si toca la base, usar una base aparte o dejarla limpia.
- `README.md`: qué es, cómo instalar y arrancar.
- Guion de la exposición (unos 5 minutos): qué decir en cada paso de Postman, mostrar en phpMyAdmin que los datos cambian, y preguntas probables del profesor con respuestas sencillas.
- TUTORIAL.md: etapa 4.

## Forma de trabajar con este usuario
- Todo en español sencillo; mensajes y comentarios para principiantes (cabecera en cada archivo, docstring en cada función).
- Un paso (una etapa) a la vez: hacer la etapa, mostrar el resultado y esperar su confirmación.
- El TUTORIAL.md se actualiza EN PARALELO con cada etapa (comandos para copiar en bloques aparte, "Qué hacemos", "Salió bien si").
- Al terminar cada tarea: commit y push a `main` sin preguntar. Nunca subir `.env` ni secretos.
- Nunca pedir ni mostrar contraseñas en el chat; usar `.env`.
- No eliminar archivos sin su aprobación explícita (mostrar la lista antes).
