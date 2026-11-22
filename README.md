# Mini CRUD de usuarios

Servidor muy sencillo hecho con **FastAPI** y **MySQL** que permite **crear, listar, ver, editar y borrar** usuarios (un "CRUD"). Los endpoints se prueban con **Postman**.

Proyecto de demostración para una exposición del **SENA, programa ADSO**.

---

## Qué tiene

| Archivo | Para qué |
|---|---|
| `main.py` | El servidor: los 6 endpoints |
| `conexion.py` | Conecta con MySQL usando los datos del `.env` |
| `database.sql` | Crea la base `mini_crud`, la tabla `usuarios` y 3 usuarios de ejemplo |
| `requirements.txt` | Las librerías de Python, con versión fija |
| `.env.example` | Plantilla de los datos de conexión (sin la contraseña real) |
| `mini-crud.postman_collection.json` | Colección de Postman con 9 peticiones y sus pruebas |
| `test_usuarios.py` | Pruebas automáticas con pytest |
| `TUTORIAL.md` | Guía paso a paso para hacer todo desde cero |

## Endpoints

| Método | Ruta | Qué hace | Respuestas |
|---|---|---|---|
| GET | `/salud` | Comprobar que el servidor está encendido | 200 |
| GET | `/usuarios` | Listar todos | 200 |
| GET | `/usuarios/{id}` | Ver uno | 200, 404 |
| POST | `/usuarios` | Crear | 201, 409, 422 |
| PUT | `/usuarios/{id}` | Editar | 200, 404, 409, 422 |
| DELETE | `/usuarios/{id}` | Borrar | 204, 404 |

Ejemplo de datos para crear o editar:

```json
{
    "nombre": "Carlos Pérez",
    "correo": "carlos.perez@ejemplo.test"
}
```

## Requisitos

- **Python 3.12**
- **MySQL** (de AppServ o de XAMPP)
- **Postman**: [postman.com/downloads](https://www.postman.com/downloads/)

## Instalación

Los comandos son para **PowerShell**, desde la carpeta del proyecto.

**1. Crear la base de datos** (con MySQL encendido):

```
cmd /c "C:\AppServ\MySQL\bin\mysql.exe -u root -t --default-character-set=utf8mb4 < database.sql"
```

Con XAMPP, cambie la ruta por `C:\xampp\mysql\bin\mysql.exe`.

**2. Crear el usuario de MySQL del proyecto:** ver el paso 1.5 de [TUTORIAL.md](TUTORIAL.md).

**3. Crear el archivo `.env`** a partir de la plantilla, y después escribir en él la contraseña del usuario de MySQL:

```
Copy-Item .env.example .env
```

**4. Crear el entorno virtual e instalar las librerías:**

```
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

## Cómo arrancar

```
.\.venv\Scripts\python.exe -m uvicorn main:app --reload --port 8000
```

Después abra:

- [http://localhost:8000/salud](http://localhost:8000/salud): debe responder `{"estado":"ok"}`.
- [http://localhost:8000/docs](http://localhost:8000/docs): página para probar la API desde el navegador.

## Cómo probar

**Con Postman:** importe `mini-crud.postman_collection.json` (**Ctrl + O**) y use **Run** → **Start run**. Deben salir 16 pruebas en verde.

**Con pytest** (no hace falta encender el servidor):

```
.\.venv\Scripts\python.exe -m pytest -v
```

Deben salir `9 passed`.

**Dejar la base limpia** (otra vez con los 3 usuarios de ejemplo): repita el paso 1 de la instalación.

## Para exponer o hacer una demostración

Siga [GUION.md](GUION.md). En resumen:

1. **Ensaye una vez** la exposición completa con el guion y mida el tiempo (unos 5 minutos).
2. **Al terminar el ensayo, deje la base limpia** (paso 1 de la instalación). Cada usuario creado avanza el contador de id aunque después se borre; así el usuario nuevo de la demostración vuelve a tener el id 4.
3. **El día de la exposición**, siga la lista "Antes de la exposición" del guion: encender MySQL, dejar la base limpia, encender el servidor y abrir Postman y phpMyAdmin.

> No ejecute Run collection ni pytest justo antes de exponer, o el usuario nuevo ya no tendrá el id 4.

## Tecnologías

- Python 3.12, FastAPI, Uvicorn
- PyMySQL (SQL directo, con parámetros `%s` para evitar inyección SQL)
- MySQL 8
- Postman y pytest para las pruebas
