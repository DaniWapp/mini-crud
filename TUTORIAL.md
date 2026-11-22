# Tutorial: Mini CRUD de usuarios desde cero

Guía para construir y probar, paso a paso, un servidor muy sencillo con FastAPI y MySQL que permite **crear, listar, ver, editar y borrar** usuarios (un "CRUD"), y demostrarlo con **Postman**.

Cada paso tiene:

- **Qué vamos a hacer**, en pocas palabras.
- **El comando o el código** para copiar, en un bloque aparte.
- **Cómo saber que salió bien**.

Los comandos son para **PowerShell** en Windows, salvo que se diga otra cosa.

---

## Etapas

1. **Base de datos:** crear la base `mini_crud`, la tabla `usuarios` y un usuario de MySQL para el proyecto.
2. **Servidor:** el código de FastAPI con los 6 endpoints.
3. **Postman:** importar la colección y probar los endpoints.
4. **Pruebas automáticas y exposición:** pruebas con pytest, README y guion *(en curso)*.

---

## Antes de empezar

Necesita tener instalado:

| Programa | Para qué | Cómo comprobarlo |
|---|---|---|
| **MySQL** (de AppServ o de XAMPP) | Guardar los datos | Ver el paso 1.1 |
| **Python 3.12** | Ejecutar el servidor | `py -3.12 --version` |
| **Postman** | Probar los endpoints | Descarga: [postman.com/downloads](https://www.postman.com/downloads/) |
| **VS Code** (opcional) | Escribir el código | — |

Comprobar Python:

```
py -3.12 --version
```

Debe responder algo como `Python 3.12.10`.

---

## Etapa 1: Base de datos

### 1.1 Encender MySQL

**Qué hacemos:** el servidor de MySQL debe estar encendido para poder crear la base y para que el servidor de Python se conecte.

**Con AppServ:** abra una ventana de PowerShell **nueva**, pegue este comando y **deje la ventana abierta** mientras trabaja:

```
& "C:\AppServ\MySQL\bin\mysqld.exe" --defaults-file="C:\AppServ\MySQL\my.ini" --console
```

**Con XAMPP:** abra el panel de XAMPP y pulse **Start** en la fila de **MySQL**.

**Salió bien si:** aparece una línea con `ready for connections` y `port: 3306` (AppServ), o MySQL se pone en verde (XAMPP).

> Para apagarlo bien en AppServ (en otra ventana), en lugar de cerrar la ventana:
> ```
> & "C:\AppServ\MySQL\bin\mysqladmin.exe" -u root shutdown
> ```

### 1.2 Crear la carpeta del proyecto

**Qué hacemos:** una carpeta para todos los archivos del mini proyecto.

```
New-Item -ItemType Directory -Force C:\AppServ\www\mini-crud
cd C:\AppServ\www\mini-crud
```

**Salió bien si:** la terminal queda en la carpeta `mini-crud`.

### 1.3 Crear el archivo `database.sql`

**Qué hacemos:** un archivo con las instrucciones SQL que crean la base, la tabla y 3 usuarios de ejemplo.

**Conceptos:**

- **Base de datos:** el "archivador" donde se guardan las tablas.
- **Tabla:** como una hoja de cálculo: columnas (los datos) y filas (cada usuario).
- **PRIMARY KEY:** la columna que identifica cada fila; no se repite.
- **AUTO_INCREMENT:** MySQL numera solo (1, 2, 3...).
- **UNIQUE:** el valor no se repite (dos usuarios no pueden tener el mismo correo).
- **NOT NULL:** el dato es obligatorio.

Cree el archivo `database.sql` dentro de `mini-crud` con este contenido:

```sql
-- Crea la base de datos si no existe. utf8mb4 guarda bien tildes y ñ.
CREATE DATABASE IF NOT EXISTS mini_crud
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mini_crud;

-- Borra la tabla si ya existía, para poder ejecutar el archivo varias veces.
DROP TABLE IF EXISTS usuarios;

CREATE TABLE usuarios (
    id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre    VARCHAR(100) NOT NULL,
    correo    VARCHAR(150) NOT NULL,
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_usuarios PRIMARY KEY (id),
    CONSTRAINT uq_usuarios_correo UNIQUE (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Datos de ejemplo para la demostración.
INSERT INTO usuarios (nombre, correo) VALUES
    ('Laura Gómez',  'laura.gomez@ejemplo.test'),
    ('Andrés Muñoz', 'andres.munoz@ejemplo.test'),
    ('Marta Rincón', 'marta.rincon@ejemplo.test');

-- Comprobación: debe mostrar los 3 usuarios.
SELECT id, nombre, correo, creado_en FROM usuarios;
```

> El archivo `database.sql` del proyecto tiene además comentarios explicando cada línea.

### 1.4 Ejecutar `database.sql`

**Qué hacemos:** le pedimos a MySQL que ejecute el archivo. Usamos el usuario `root`, el administrador de MySQL.

PowerShell no acepta el símbolo `<`, por eso se usa `cmd /c`:

```
cmd /c "C:\AppServ\MySQL\bin\mysql.exe -u root -t --default-character-set=utf8mb4 < database.sql"
```

- Con **XAMPP**, cambie la ruta por `C:\xampp\mysql\bin\mysql.exe`.
- Si su `root` tiene contraseña, agregue `-p` después de `-u root` y escríbala cuando la pida.
- `--default-character-set=utf8mb4` evita que las tildes se guarden dañadas.

**Salió bien si:** aparece una tabla con Laura Gómez, Andrés Muñoz y Marta Rincón.

> Otra forma: en **phpMyAdmin**, pestaña **Importar**, elegir `database.sql` y pulsar **Continuar**.

### 1.5 Crear un usuario de MySQL para el proyecto

**Qué hacemos:** en lugar de usar `root` (que puede hacer todo en todas las bases), creamos un usuario `mini_crud` que **solo** puede trabajar en la base `mini_crud`. Es una buena práctica de seguridad: si alguien conoce esa contraseña, no puede tocar otras bases.

1. Elija una contraseña (letras y números, sin comillas). En el ejemplo se llama `MiClaveSegura2026`: **cámbiela por la suya**.
2. Abra la consola de MySQL:

```
& "C:\AppServ\MySQL\bin\mysql.exe" -u root
```

3. Dentro de la consola (`mysql>`), pegue esto **con su contraseña**:

```sql
CREATE USER 'mini_crud'@'localhost' IDENTIFIED WITH mysql_native_password BY 'MiClaveSegura2026';
CREATE USER 'mini_crud'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'MiClaveSegura2026';
GRANT ALL PRIVILEGES ON mini_crud.* TO 'mini_crud'@'localhost';
GRANT ALL PRIVILEGES ON mini_crud.* TO 'mini_crud'@'127.0.0.1';
FLUSH PRIVILEGES;
EXIT;
```

**Conceptos:**

- `'mini_crud'@'localhost'` y `'mini_crud'@'127.0.0.1'`: el mismo usuario, para las dos formas en que un programa se conecta desde este equipo.
- `mysql_native_password`: el tipo de contraseña que entienden PyMySQL y phpMyAdmin sin configuración extra.
- `GRANT ALL PRIVILEGES ON mini_crud.*`: todos los permisos, pero **solo** en la base `mini_crud`.

**Salió bien si:** cada línea responde `Query OK`.

### 1.6 Crear los archivos `.env.example` y `.env`

**Qué hacemos:** los datos de conexión (y sobre todo la contraseña) **nunca** se escriben dentro del código. Se guardan en un archivo `.env`, que **no se sube a GitHub**. Y se sube una plantilla, `.env.example`, sin la contraseña real.

Cree `.env.example` con este contenido:

```
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=mini_crud
DB_USER=mini_crud
DB_PASSWORD=cambia-esto
```

Cree una copia llamada `.env`:

```
Copy-Item .env.example .env
```

Abra `.env` y cambie `cambia-esto` por la contraseña que eligió en el paso 1.5.

**Muy importante:** para que Git nunca suba el `.env`, cree en la carpeta `mini-crud` un archivo llamado `.gitignore` con este contenido:

```
# Datos de conexión reales (contienen la contraseña).
.env

# Entorno virtual de Python: cada persona lo crea en su equipo.
.venv/

# Archivos que Python genera solo.
__pycache__/
*.pyc
.pytest_cache/
```

Después, inicie el repositorio de Git y compruebe que el `.env` queda ignorado:

```
git init
git check-ignore -v .env
```

**Salió bien si:** la respuesta menciona `.gitignore` (eso significa que Git lo ignora).

> Para subirlo a GitHub (con un repositorio vacío ya creado en github.com):
> ```
> git add .
> git commit -m "Primer commit del mini CRUD"
> git branch -M main
> git remote add origin https://github.com/SU-USUARIO/mini-crud.git
> git push -u origin main
> ```

### 1.7 Comprobar que el usuario del proyecto puede entrar

**Qué hacemos:** nos conectamos con el usuario `mini_crud` (no con `root`) y contamos los usuarios de la tabla.

```
& "C:\AppServ\MySQL\bin\mysql.exe" -u mini_crud -p -h 127.0.0.1 -e "SHOW DATABASES; SELECT COUNT(*) FROM mini_crud.usuarios;"
```

Escriba la contraseña cuando la pida (no se ve mientras se escribe).

**Salió bien si:** solo aparecen las bases `information_schema` y `mini_crud` (no ve las demás) y el conteo es `3`.

### Fin de la etapa 1

Ya tiene:

- La base `mini_crud` con la tabla `usuarios` y 3 usuarios de ejemplo.
- Un usuario de MySQL con permisos solo sobre esa base.
- Los archivos `database.sql`, `.env.example` y `.env` (este último sin subir a GitHub).

**Siguiente etapa:** el servidor con FastAPI.

---

## Etapa 2: Servidor

### 2.1 Crear el entorno virtual

**Qué hacemos:** un entorno virtual es una carpeta (`.venv`) con un Python propio del proyecto. Las librerías se instalan ahí y no en todo el equipo, así cada proyecto tiene las suyas sin mezclarse.

Desde la carpeta `mini-crud`:

```
cd C:\AppServ\www\mini-crud
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe --version
```

**Salió bien si:** aparece `Python 3.12.x` y existe la carpeta `.venv`.

> La carpeta `.venv` **no se sube a GitHub** (el `.gitignore` la excluye): cada persona la crea en su equipo.

### 2.2 Crear `requirements.txt` e instalar las librerías

**Qué hacemos:** `requirements.txt` es la lista de librerías que necesita el proyecto. Con un solo comando se instalan todas.

| Librería | Para qué |
|---|---|
| `fastapi` | Crear la API (los endpoints) |
| `uvicorn` | El servidor que pone a funcionar la API en un puerto |
| `pymysql` | Conectar Python con MySQL |
| `python-dotenv` | Leer el archivo `.env` |

Cree `requirements.txt` con este contenido (el `==` fija la versión exacta, para que todos instalen las mismas):

```
# Librerías del mini CRUD, con su versión exacta para que todos instalen las mismas.
# Se instalan con:
#   .venv\Scripts\python.exe -m pip install -r requirements.txt

# FastAPI: el framework para crear la API (los endpoints).
fastapi==0.165.0

# Uvicorn: el servidor que pone a funcionar la API en un puerto.
uvicorn==0.54.0

# PyMySQL: conecta Python con MySQL.
pymysql==1.2.4

# python-dotenv: lee el archivo .env con los datos de conexión.
python-dotenv==1.2.4
```

Actualice el instalador `pip` e instale:

```
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

**Salió bien si:** termina sin errores en rojo. Compruébelo con:

```
.\.venv\Scripts\python.exe -m pip show fastapi
```

### 2.3 Crear `conexion.py`

**Qué hacemos:** una función que abre la conexión con MySQL usando los datos del `.env`. Así la contraseña nunca aparece en el código.

Cree `conexion.py` con este contenido:

```python
"""
Archivo:  mini-crud/conexion.py
Proyecto: Mini CRUD de usuarios

Qué hace:
    Abre la conexión con la base de datos MySQL "mini_crud", leyendo los
    datos (servidor, usuario, contraseña...) del archivo .env.

Por qué los datos están en .env y no aquí:
    La contraseña nunca se escribe en el código. Así el código se puede
    subir a GitHub sin exponerla.

Conceptos:
    - load_dotenv(): lee el archivo .env y deja sus valores disponibles
      con os.getenv("NOMBRE").
    - DictCursor: cada fila llega como diccionario, por ejemplo
      {"id": 1, "nombre": "Laura Gómez"}, en lugar de (1, "Laura Gómez").
    - autocommit=True: cada cambio (INSERT, UPDATE, DELETE) se guarda en
      cuanto se ejecuta. En este proyecto cada endpoint hace un solo
      cambio, así que no hace falta manejar transacciones.
"""

import os
from pathlib import Path

import pymysql
from dotenv import load_dotenv
from pymysql.cursors import DictCursor

# Carga el .env que está en la misma carpeta que este archivo.
load_dotenv(Path(__file__).parent / ".env")


def obtener_conexion() -> pymysql.connections.Connection:
    """Abre y devuelve una conexión nueva a la base de datos.

    Se usa con "with", que la cierra sola al terminar:
        with obtener_conexion() as conexion:
            ...
    """
    return pymysql.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "mini_crud"),
        charset="utf8mb4",        # guarda bien las tildes y la ñ
        cursorclass=DictCursor,
        autocommit=True,
    )
```

### 2.4 Crear `main.py` (el servidor y los endpoints)

**Qué hacemos:** el corazón del proyecto. Define la forma de los datos (con Pydantic) y los 6 endpoints.

| Método | Ruta | Qué hace | Respuestas |
|---|---|---|---|
| GET | `/salud` | Comprobar que el servidor está encendido | 200 |
| GET | `/usuarios` | Listar todos | 200 |
| GET | `/usuarios/{id}` | Ver uno | 200, 404 |
| POST | `/usuarios` | Crear | 201, 409 (correo repetido), 422 (datos incompletos) |
| PUT | `/usuarios/{id}` | Editar | 200, 404, 409, 422 |
| DELETE | `/usuarios/{id}` | Borrar de verdad | 204, 404 |

**Códigos de respuesta que va a ver:**

| Código | Significa |
|---|---|
| 200 OK | Salió bien y devuelve datos |
| 201 Created | Se creó un registro |
| 204 No Content | Salió bien y no hay nada que devolver (al borrar) |
| 404 Not Found | El registro no existe |
| 409 Conflict | Choca con una regla (el correo ya existe) |
| 422 Unprocessable Entity | Los datos enviados están incompletos o mal escritos |

Cree `main.py` con este contenido:

```python
"""
Archivo:  mini-crud/main.py
Proyecto: Mini CRUD de usuarios

Qué hace:
    Es el servidor. Crea la API con FastAPI y define 6 endpoints:

        GET    /salud            comprobar que el servidor está encendido
        GET    /usuarios         listar todos los usuarios
        GET    /usuarios/{id}    ver un usuario
        POST   /usuarios         crear un usuario
        PUT    /usuarios/{id}    editar un usuario
        DELETE /usuarios/{id}    borrar un usuario

Cómo se ejecuta (desde la carpeta mini-crud, con el entorno virtual):
    .venv\\Scripts\\python.exe -m uvicorn main:app --reload --port 8000

    Después:
        http://localhost:8000/salud   responde {"estado": "ok"}
        http://localhost:8000/docs    página para probar la API desde el navegador

Conceptos:
    - Endpoint: una dirección + un método HTTP (GET, POST, PUT, DELETE).
    - CRUD: Create (crear, POST), Read (leer, GET), Update (editar, PUT),
      Delete (borrar, DELETE).
    - Pydantic (BaseModel): define la forma de los datos. Si llega un dato
      que no cumple (por ejemplo, sin nombre), FastAPI responde 422 solo.
    - HTTPException: detiene el endpoint y responde con un código de error
      (404 no existe, 409 conflicto) y un mensaje.
    - %s en el SQL: el lugar donde PyMySQL pone cada valor de forma
      segura. NUNCA se pega el texto del usuario dentro del SQL, porque
      eso permitiría "inyección SQL".
"""

from datetime import datetime

import pymysql
from fastapi import FastAPI, HTTPException, Response, status
from pydantic import BaseModel, Field

from conexion import obtener_conexion

# La aplicación. El título aparece en la página /docs.
app = FastAPI(title="Mini CRUD de usuarios",
              description="Demostración: crear, listar, ver, editar y borrar usuarios en MySQL.")


# ---------------------------------------------------------------- forma de los datos

class UsuarioEntrada(BaseModel):
    """Los datos que se envían para crear o editar un usuario."""
    # Obligatorio, de 1 a 100 caracteres.
    nombre: str = Field(min_length=1, max_length=100, examples=["Carlos Pérez"])
    # Obligatorio, con forma de correo: algo@algo.algo
    correo: str = Field(max_length=150, pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                        examples=["carlos.perez@ejemplo.test"])


class Usuario(BaseModel):
    """Un usuario tal como lo devuelve la API."""
    id: int
    nombre: str
    correo: str
    creado_en: datetime


# Mensaje que se repite en varios endpoints.
NO_EXISTE = "El usuario no existe."
CORREO_REPETIDO = "Ya existe un usuario con ese correo."


# ---------------------------------------------------------------- endpoints

@app.get("/salud")
def salud() -> dict:
    """Responde que el servidor está encendido. No usa la base de datos."""
    return {"estado": "ok"}


@app.get("/usuarios", response_model=list[Usuario])
def listar_usuarios():
    """READ: devuelve todos los usuarios, del más antiguo al más nuevo."""
    with obtener_conexion() as conexion, conexion.cursor() as cursor:
        cursor.execute("SELECT id, nombre, correo, creado_en FROM usuarios ORDER BY id")
        return cursor.fetchall()


@app.get("/usuarios/{usuario_id}", response_model=Usuario)
def ver_usuario(usuario_id: int):
    """READ: devuelve un usuario por su id, o 404 si no existe."""
    with obtener_conexion() as conexion, conexion.cursor() as cursor:
        cursor.execute("SELECT id, nombre, correo, creado_en FROM usuarios WHERE id = %s", (usuario_id,))
        usuario = cursor.fetchone()
    if usuario is None:
        raise HTTPException(status_code=404, detail=NO_EXISTE)
    return usuario


@app.post("/usuarios", response_model=Usuario, status_code=status.HTTP_201_CREATED)
def crear_usuario(datos: UsuarioEntrada):
    """CREATE: crea un usuario y lo devuelve con su id. 409 si el correo ya existe."""
    with obtener_conexion() as conexion, conexion.cursor() as cursor:
        try:
            cursor.execute("INSERT INTO usuarios (nombre, correo) VALUES (%s, %s)",
                           (datos.nombre.strip(), datos.correo.strip().lower()))
        except pymysql.err.IntegrityError:
            # La base de datos rechaza el correo repetido (restricción UNIQUE).
            raise HTTPException(status_code=409, detail=CORREO_REPETIDO)
        nuevo_id = cursor.lastrowid  # el id que MySQL le asignó
        cursor.execute("SELECT id, nombre, correo, creado_en FROM usuarios WHERE id = %s", (nuevo_id,))
        return cursor.fetchone()


@app.put("/usuarios/{usuario_id}", response_model=Usuario)
def editar_usuario(usuario_id: int, datos: UsuarioEntrada):
    """UPDATE: cambia el nombre y el correo. 404 si no existe, 409 si el correo es de otro usuario."""
    with obtener_conexion() as conexion, conexion.cursor() as cursor:
        cursor.execute("SELECT id FROM usuarios WHERE id = %s", (usuario_id,))
        if cursor.fetchone() is None:
            raise HTTPException(status_code=404, detail=NO_EXISTE)
        try:
            cursor.execute("UPDATE usuarios SET nombre = %s, correo = %s WHERE id = %s",
                           (datos.nombre.strip(), datos.correo.strip().lower(), usuario_id))
        except pymysql.err.IntegrityError:
            raise HTTPException(status_code=409, detail=CORREO_REPETIDO)
        cursor.execute("SELECT id, nombre, correo, creado_en FROM usuarios WHERE id = %s", (usuario_id,))
        return cursor.fetchone()


@app.delete("/usuarios/{usuario_id}", status_code=status.HTTP_204_NO_CONTENT)
def borrar_usuario(usuario_id: int):
    """DELETE: borra el usuario de verdad. Responde 204 (sin contenido) o 404 si no existe."""
    with obtener_conexion() as conexion, conexion.cursor() as cursor:
        cursor.execute("DELETE FROM usuarios WHERE id = %s", (usuario_id,))
        if cursor.rowcount == 0:  # rowcount: cuántas filas se borraron
            raise HTTPException(status_code=404, detail=NO_EXISTE)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
```

### 2.5 Encender el servidor

**Qué hacemos:** Uvicorn pone a funcionar la API en el puerto 8000. **MySQL debe estar encendido** (paso 1.1).

```
.\.venv\Scripts\python.exe -m uvicorn main:app --reload --port 8000
```

- `main:app` significa "en el archivo `main.py`, usa la variable `app`".
- `--reload` reinicia el servidor solo cada vez que se guarda un cambio en el código.
- Deje esta ventana abierta mientras prueba. Para apagar el servidor: **Ctrl + C**.

**Salió bien si:** aparece `Uvicorn running on http://127.0.0.1:8000`.

### 2.6 Comprobar desde el navegador

Abra estas direcciones:

- [http://localhost:8000/salud](http://localhost:8000/salud): debe mostrar `{"estado":"ok"}`.
- [http://localhost:8000/usuarios](http://localhost:8000/usuarios): debe mostrar los 3 usuarios de ejemplo.
- [http://localhost:8000/docs](http://localhost:8000/docs): una página que FastAPI crea sola, con todos los endpoints. Sirve de **plan B** si Postman falla: en cada endpoint, **Try it out** y **Execute**.

### 2.7 Dejar la base limpia antes de demostrar

Si hizo pruebas y quiere volver a los 3 usuarios de ejemplo (y que los id empiecen otra vez en 4), ejecute de nuevo `database.sql` (paso 1.4).

### Fin de la etapa 2

Ya tiene un servidor funcionando con los 6 endpoints, conectado a MySQL con el usuario del proyecto.

**Siguiente etapa:** probar los endpoints con Postman.

---

## Etapa 3: Postman

**Conceptos:**

- **Postman:** un programa para enviar peticiones a una API (GET, POST, PUT, DELETE) y ver la respuesta, sin necesidad de una página web.
- **Colección:** un archivo con un grupo de peticiones ya preparadas. La del proyecto es `mini-crud.postman_collection.json`.
- **Variable:** un valor con nombre que se escribe entre llaves dobles, por ejemplo `{{base_url}}`. Postman lo cambia por su valor antes de enviar la petición.
- **Prueba (test):** un pequeño código en JavaScript que Postman ejecuta al recibir la respuesta y que dice si salió como se esperaba (verde) o no (rojo).

### 3.1 Instalar Postman

**Qué hacemos:** descargar e instalar la aplicación de escritorio.

1. Entre a [postman.com/downloads](https://www.postman.com/downloads/) y descargue la versión para **Windows**.
2. Ejecute el instalador.
3. Al abrir, puede crear una cuenta gratuita o entrar con Google.

**Salió bien si:** se abre la ventana principal de Postman.

### 3.2 La colección del proyecto

**Qué hacemos:** la colección ya está en la carpeta del proyecto, en el archivo `mini-crud.postman_collection.json`. Tiene:

- **2 variables:**
  - `base_url` = `http://localhost:8000` (la dirección del servidor; si cambia el puerto, se cambia solo aquí).
  - `usuario_id`: empieza vacía y se llena sola al crear un usuario.
- **9 peticiones**, en este orden:

| # | Petición | Qué demuestra | Esperado |
|---|---|---|---|
| 1 | GET `/salud` | El servidor está encendido | 200 |
| 2 | GET `/usuarios` | Listar (READ) | 200 |
| 3 | POST `/usuarios` | Crear (CREATE); guarda el `id` en `usuario_id` | 201 |
| 4 | GET `/usuarios/{{usuario_id}}` | Ver uno (READ) | 200 |
| 5 | PUT `/usuarios/{{usuario_id}}` | Editar (UPDATE) | 200 |
| 6 | POST `/usuarios` con el correo de Laura | Correo repetido | 409 |
| 7 | POST `/usuarios` sin nombre | Datos incompletos | 422 |
| 8 | DELETE `/usuarios/{{usuario_id}}` | Borrar (DELETE) | 204 |
| 9 | GET `/usuarios/{{usuario_id}}` | Ya no existe | 404 |

**Cómo pasa el id de una petición a otra:** la prueba de la petición 3 tiene esta línea, que toma el `id` de la respuesta y lo guarda en la variable:

```javascript
pm.collectionVariables.set("usuario_id", usuario.id);
```

**Por qué el correo dice `{{$timestamp}}`:** es una variable especial de Postman que pone un número distinto cada vez (la hora en segundos). Así el correo nunca se repite y la colección se puede ejecutar muchas veces sin error 409.

Ejemplo de una prueba (petición 1):

```javascript
pm.test("Responde 200 OK", function () {
    pm.response.to.have.status(200);
});
```

### 3.3 Importar la colección

**Qué hacemos:** cargar el archivo en Postman.

1. En Postman, abra la ventana de importar de una de estas dos formas:
   - Con el teclado: **Ctrl + O**.
   - Con el ícono del panel izquierdo, arriba, a la derecha del **+** (una flecha que entra en un cuadro). En las versiones nuevas de Postman el botón ya no dice "Import".
2. Arrastre el archivo `C:\AppServ\www\mini-crud\mini-crud.postman_collection.json` (o pulse **files** y búsquelo).
3. Pulse **Import**.

**Salió bien si:** en el panel izquierdo, en **Collections**, aparece **Mini CRUD de usuarios** con las 9 peticiones.

### 3.4 Encender todo y dejar la base limpia

**Qué hacemos:** antes de probar deben estar encendidos MySQL (paso 1.1) y el servidor (paso 2.5). Y conviene dejar la base con los 3 usuarios de ejemplo.

Encender el servidor (en su propia ventana, desde `mini-crud`):

```
.\.venv\Scripts\python.exe -m uvicorn main:app --reload --port 8000
```

Dejar la base limpia (en otra ventana, desde `mini-crud`):

```
cmd /c "C:\AppServ\MySQL\bin\mysql.exe -u root -t --default-character-set=utf8mb4 < database.sql"
```

**Salió bien si:** aparecen los 3 usuarios de ejemplo y el servidor dice `Uvicorn running on http://127.0.0.1:8000`.

### 3.5 Enviar las peticiones una por una

**Qué hacemos:** así se hace en la exposición, para explicar cada endpoint.

1. Abra la petición **1. Salud del servidor** y pulse **Send**.
2. Abajo verá la respuesta: el **código** (por ejemplo `200 OK`), el **cuerpo** (Body) y la pestaña **Test Results** con las pruebas en verde.
3. Repita con las peticiones 2 a 9, **en orden** (la 4, 5, 8 y 9 necesitan el id que guarda la 3).
4. En las peticiones POST y PUT, abra la pestaña **Body** para mostrar los datos que se envían.

**Salió bien si:** cada petición responde el código de la tabla del paso 3.2 y **Test Results** está en verde.

> Si la petición 4 responde 404 o la URL muestra `/usuarios/` sin número, es porque no se ha enviado la 3 todavía.

### 3.6 Ejecutar toda la colección de una vez (Run collection)

**Qué hacemos:** Postman envía las 9 peticiones seguidas y muestra el resultado de todas las pruebas.

1. En el panel izquierdo, pase el ratón sobre **Mini CRUD de usuarios** y pulse los **tres puntos (...)**.
2. Elija **Run** (en algunas versiones dice **Run collection**).
3. Deje las 9 peticiones marcadas y en orden, con **Functional** y **Local** seleccionados.
4. Pulse el botón naranja **Start run** (en versiones antiguas: **Run Mini CRUD de usuarios**).

**Salió bien si:** arriba aparece **Passed 16** y **Failed 0**.

> La opción **Stop run if an error occurs** puede quedar marcada: las respuestas 409, 422 y 404 son esperadas, no errores de la ejecución.

> Al final de la colección el usuario creado se borra, así que la base queda otra vez con los 3 usuarios de ejemplo (aunque el próximo id ya no será 4; para eso, repetir el paso 3.4).

### Fin de la etapa 3

Ya tiene:

- La colección `mini-crud.postman_collection.json` con 9 peticiones y sus pruebas.
- La demostración de los 6 endpoints, incluidos los errores 404, 409 y 422.

**Siguiente etapa:** pruebas automáticas y preparación de la exposición.

---

## Etapa 4: Pruebas automáticas y exposición

Partes de esta etapa:

1. Pruebas automáticas con pytest.
2. `README.md` del proyecto.
3. Guion de la exposición.

### 4.1 Pruebas automáticas con pytest

**Qué hacemos:** un archivo de Python que prueba los 6 endpoints solo, con un comando. Es lo mismo que hace la colección de Postman, pero sin abrir Postman. Es **opcional** para la exposición.

**Conceptos:**

- **pytest:** busca las funciones que empiezan con `test_` y las ejecuta.
- **assert:** comprueba que algo es verdad. Si no lo es, la prueba falla.
- **TestClient:** envía peticiones a la API desde Python, sin encender el servidor.
- **fixture:** algo que pytest prepara antes de una prueba y limpia después (aquí: crea un usuario de prueba y lo borra al final).

**1. Agregar las librerías al final de `requirements.txt`:**

```
# ---- Solo para las pruebas automáticas (test_usuarios.py) ----

# pytest: ejecuta las pruebas automáticas.
pytest==9.2.0

# httpx2: lo usa el TestClient de FastAPI para enviar peticiones a la API.
httpx2==2.16.2
```

**2. Instalarlas:**

```
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

**3. Crear `test_usuarios.py`** con este contenido:

```python
"""
Archivo:  mini-crud/test_usuarios.py
Proyecto: Mini CRUD de usuarios

Qué hace:
    Pruebas automáticas de los 6 endpoints. Hacen lo mismo que la colección
    de Postman, pero desde Python y con un solo comando.

Cómo se ejecuta (desde la carpeta mini-crud, con MySQL encendido):
    .venv\\Scripts\\python.exe -m pytest -v

    No hace falta encender el servidor: TestClient llama a la API
    directamente, sin usar el puerto 8000.

Cuidado con la base de datos:
    Las pruebas usan la base real "mini_crud". Cada prueba borra el usuario
    que crea, así que al final quedan los mismos usuarios que había. Lo único
    que cambia es el contador de id (el próximo id ya no será 4). Para
    dejarla como nueva, ejecute otra vez database.sql.

Conceptos:
    - pytest: busca las funciones que empiezan con "test_" y las ejecuta.
    - assert: comprueba que algo es verdad. Si no lo es, la prueba falla.
    - TestClient: un "Postman de mentiras" dentro de Python: envía
      peticiones a la API y devuelve la respuesta.
    - fixture: algo que pytest prepara antes de una prueba y limpia después.
"""

import time

import pytest
from fastapi.testclient import TestClient

from main import app

# El cliente que envía las peticiones a la API.
cliente = TestClient(app)


def correo_unico(prefijo: str) -> str:
    """Devuelve un correo que no se repite, usando la hora actual en nanosegundos."""
    return f"{prefijo}.{time.time_ns()}@ejemplo.test"


@pytest.fixture
def usuario_creado():
    """Crea un usuario de prueba antes de la prueba y lo borra después.

    "yield" entrega el usuario a la prueba. Cuando la prueba termina
    (salga bien o mal), se ejecuta lo que está después del yield.
    """
    respuesta = cliente.post("/usuarios", json={"nombre": "Usuario de Prueba",
                                                "correo": correo_unico("prueba")})
    usuario = respuesta.json()
    yield usuario
    cliente.delete(f"/usuarios/{usuario['id']}")  # limpieza (si ya se borró, responde 404 y no pasa nada)


# ---------------------------------------------------------------- pruebas

def test_salud():
    """GET /salud responde 200 y {"estado": "ok"}."""
    respuesta = cliente.get("/salud")
    assert respuesta.status_code == 200
    assert respuesta.json() == {"estado": "ok"}


def test_listar_usuarios():
    """GET /usuarios responde 200 y una lista."""
    respuesta = cliente.get("/usuarios")
    assert respuesta.status_code == 200
    assert isinstance(respuesta.json(), list)


def test_crear_usuario():
    """POST /usuarios responde 201, guarda el correo en minúsculas y devuelve el id."""
    correo = correo_unico("Nuevo.Usuario")  # con mayúsculas a propósito
    respuesta = cliente.post("/usuarios", json={"nombre": "Nuevo Usuario", "correo": correo})
    assert respuesta.status_code == 201
    usuario = respuesta.json()
    assert usuario["nombre"] == "Nuevo Usuario"
    assert usuario["correo"] == correo.lower()
    cliente.delete(f"/usuarios/{usuario['id']}")  # limpieza


def test_ver_usuario(usuario_creado):
    """GET /usuarios/{id} responde 200 con el usuario pedido."""
    respuesta = cliente.get(f"/usuarios/{usuario_creado['id']}")
    assert respuesta.status_code == 200
    assert respuesta.json()["id"] == usuario_creado["id"]


def test_editar_usuario(usuario_creado):
    """PUT /usuarios/{id} responde 200 y cambia el nombre."""
    respuesta = cliente.put(f"/usuarios/{usuario_creado['id']}",
                            json={"nombre": "Nombre Editado", "correo": correo_unico("editado")})
    assert respuesta.status_code == 200
    assert respuesta.json()["nombre"] == "Nombre Editado"


def test_crear_con_correo_repetido_da_409(usuario_creado):
    """POST /usuarios con un correo que ya existe responde 409."""
    respuesta = cliente.post("/usuarios", json={"nombre": "Otro", "correo": usuario_creado["correo"]})
    assert respuesta.status_code == 409
    assert respuesta.json()["detail"] == "Ya existe un usuario con ese correo."


def test_crear_sin_nombre_da_422():
    """POST /usuarios sin nombre responde 422 (FastAPI lo rechaza antes de llegar a la base)."""
    respuesta = cliente.post("/usuarios", json={"correo": correo_unico("sin.nombre")})
    assert respuesta.status_code == 422


def test_borrar_usuario(usuario_creado):
    """DELETE /usuarios/{id} responde 204 y después el usuario ya no existe (404)."""
    respuesta = cliente.delete(f"/usuarios/{usuario_creado['id']}")
    assert respuesta.status_code == 204
    respuesta = cliente.get(f"/usuarios/{usuario_creado['id']}")
    assert respuesta.status_code == 404
    assert respuesta.json()["detail"] == "El usuario no existe."


def test_editar_usuario_que_no_existe_da_404():
    """PUT /usuarios/{id} con un id que no existe responde 404."""
    respuesta = cliente.put("/usuarios/999999", json={"nombre": "Nadie", "correo": correo_unico("nadie")})
    assert respuesta.status_code == 404
```

**4. Ejecutar las pruebas** (MySQL encendido; el servidor no hace falta):

```
.\.venv\Scripts\python.exe -m pytest -v
```

**Salió bien si:** al final dice `9 passed` y cada prueba aparece con `PASSED`.

> Las pruebas borran los usuarios que crean, pero el contador de id avanza. Antes de exponer, deje la base limpia (paso 3.4).

### 4.2 Crear el `README.md`

**Qué hacemos:** el `README.md` es la "portada" del proyecto: GitHub lo muestra al abrir el repositorio. Explica en pocas líneas qué es, qué archivos tiene, cuáles son los endpoints, cómo instalarlo, cómo arrancarlo y cómo probarlo. Este tutorial, en cambio, explica todo paso a paso.

Cree `README.md` en la carpeta `mini-crud`. Puede copiar el del proyecto: [README.md](README.md). Sus secciones son:

1. Qué es el proyecto.
2. Qué tiene (tabla de archivos).
3. Endpoints (tabla con métodos, rutas y respuestas).
4. Requisitos.
5. Instalación.
6. Cómo arrancar.
7. Cómo probar (Postman y pytest).
8. Tecnologías.

**Salió bien si:** al subirlo a GitHub, la página del repositorio muestra el README debajo de la lista de archivos.

### 4.3 Preparar la exposición

**Qué hacemos:** el archivo [GUION.md](GUION.md) tiene todo lo necesario para exponer en unos 5 minutos:

1. **Antes de la exposición:** encender MySQL, dejar la base limpia, encender el servidor y dejar abiertos Postman, phpMyAdmin y VS Code.
2. **Guion:** qué decir en la presentación, en el código, en cada petición de Postman y en el cierre.
3. **phpMyAdmin:** en qué momentos mostrar que los datos cambian de verdad en la base (después de crear, editar y borrar).
4. **Plan B:** qué hacer si algo falla.
5. **Preguntas probables** del profesor, con respuestas sencillas.

phpMyAdmin está en [http://localhost/phpMyAdmin/](http://localhost/phpMyAdmin/) (necesita Apache encendido). Puede entrar con el usuario `mini_crud` y su contraseña: así solo verá la base del proyecto.

**Salió bien si:** puede hacer un ensayo completo siguiendo el guion, de principio a fin, en unos 5 minutos.

### Fin de la etapa 4

Ya tiene:

- Pruebas automáticas con pytest (`test_usuarios.py`).
- El `README.md` del proyecto.
- El guion de la exposición (`GUION.md`).

**El proyecto está completo.** 🎉
