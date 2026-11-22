# Diagramas del Mini CRUD de usuarios

Diagramas sencillos para entender **cómo funciona** el proyecto. GitHub los dibuja solo (están escritos en **Mermaid**, un lenguaje de texto para hacer diagramas).

1. [Las piezas del proyecto](#1-las-piezas-del-proyecto)
2. [La tabla `usuarios`](#2-la-tabla-usuarios)
3. [Los endpoints y sus respuestas](#3-los-endpoints-y-sus-respuestas)
4. [El viaje de una petición: crear un usuario](#4-el-viaje-de-una-petición-crear-un-usuario)
5. [La colección de Postman](#5-la-colección-de-postman)
6. [Los archivos y GitHub](#6-los-archivos-y-github)

---

## 1. Las piezas del proyecto

Quién habla con quién cuando se envía una petición.

```mermaid
flowchart TD
    P["🧑‍💻 Postman<br/>o el navegador (/docs)"]
    U["⚙️ Uvicorn<br/>servidor en el puerto 8000"]
    F["🐍 main.py<br/>FastAPI: los 6 endpoints"]
    C["🔌 conexion.py<br/>abre la conexión"]
    E["🔒 .env<br/>usuario y contraseña"]
    M[("🗄️ MySQL<br/>base mini_crud")]

    P -- "1. petición HTTP<br/>(GET, POST, PUT, DELETE)" --> U
    U -- "2. se la pasa a" --> F
    F -- "3. pide una conexión" --> C
    E -. "lee los datos" .-> C
    C -- "4. consulta SQL" --> M
    M -- "5. filas" --> F
    F -- "6. respuesta JSON<br/>+ código (200, 404...)" --> P
```

**Cómo leerlo:**

- **Postman** es el "cliente": el que pregunta.
- **Uvicorn** recibe la petición en el puerto 8000 y se la entrega a **FastAPI**.
- **FastAPI** (`main.py`) decide qué endpoint la atiende y revisa los datos.
- **conexion.py** se conecta a **MySQL** con los datos del **`.env`**.
- La respuesta vuelve a Postman en formato **JSON**, con un **código** que dice cómo salió.

---

## 2. La tabla `usuarios`

La única tabla de la base `mini_crud`.

```mermaid
erDiagram
    USUARIOS {
        int id PK "AUTO_INCREMENT: MySQL lo numera solo"
        varchar nombre "100 caracteres, obligatorio"
        varchar correo UK "150 caracteres, obligatorio, no se repite"
        datetime creado_en "fecha y hora, la pone MySQL"
    }
```

| Marca | Significa |
|---|---|
| **PK** (Primary Key) | Identifica cada fila. No se repite. |
| **UK** (Unique Key) | No se repite: dos usuarios no pueden tener el mismo correo. Por eso existe el error **409**. |

---

## 3. Los endpoints y sus respuestas

Cada endpoint es **un método + una ruta**. Corresponden a las 4 letras de CRUD:

```mermaid
flowchart LR
    API(["🐍 API<br/>/usuarios"])
    API --> C["<b>C</b>reate · Crear<br/>POST /usuarios"]
    API --> R["<b>R</b>ead · Leer<br/>GET /usuarios<br/>GET /usuarios/{id}"]
    API --> U["<b>U</b>pdate · Editar<br/>PUT /usuarios/{id}"]
    API --> D["<b>D</b>elete · Borrar<br/>DELETE /usuarios/{id}"]
```

Además está `GET /salud`, que solo dice si el servidor está encendido.

**¿Cómo decide la API qué código responder?** Hace estas preguntas, en este orden:

```mermaid
flowchart TD
    INI(["📨 Llega una petición"])
    Q1{"¿Trae datos completos y bien escritos?<br/><i>solo POST y PUT</i>"}
    Q2{"¿Existe un usuario con ese id?<br/><i>solo rutas con /{id}</i>"}
    Q3{"¿El correo ya es de otro usuario?<br/><i>solo POST y PUT</i>"}
    E422(["❌ 422<br/>Datos incompletos"])
    E404(["❌ 404<br/>El usuario no existe"])
    E409(["❌ 409<br/>Correo repetido"])
    OK(["✅ Salió bien<br/>GET y PUT: 200 OK<br/>POST: 201 Created<br/>DELETE: 204 No Content"])

    INI --> Q1
    Q1 -- "No" --> E422
    Q1 -- "Sí" --> Q2
    Q2 -- "No" --> E404
    Q2 -- "Sí" --> Q3
    Q3 -- "Sí" --> E409
    Q3 -- "No" --> OK
```

| Endpoint | Posibles respuestas |
|---|---|
| `GET /salud` | 200 |
| `GET /usuarios` | 200 |
| `GET /usuarios/{id}` | 200, 404 |
| `POST /usuarios` | 201, 409, 422 |
| `PUT /usuarios/{id}` | 200, 404, 409, 422 |
| `DELETE /usuarios/{id}` | 204, 404 |

**Regla fácil para recordar los códigos:**

- **2xx** (200, 201, 204): salió bien.
- **4xx** (404, 409, 422): el error está en lo que se pidió (no existe, está repetido o faltan datos).

---

## 4. El viaje de una petición: crear un usuario

Qué pasa, paso a paso, al enviar `POST /usuarios`, y en qué momento aparece cada posible respuesta.

```mermaid
sequenceDiagram
    autonumber
    actor P as Postman
    participant F as FastAPI (main.py)
    participant M as MySQL

    P->>F: POST /usuarios con nombre y correo (JSON)
    F->>F: Pydantic revisa los datos

    alt Falta el nombre o el correo está mal escrito
        F-->>P: 422 Unprocessable Entity
    else Los datos están bien
        F->>M: INSERT INTO usuarios ... VALUES (%s, %s)
        alt El correo ya existe (UNIQUE)
            M-->>F: Error de integridad
            F-->>P: 409 Ya existe un usuario con ese correo
        else El correo es nuevo
            M-->>F: Guardado, id nuevo
            F->>M: SELECT del usuario recién creado
            M-->>F: La fila completa
            F-->>P: 201 Created con el usuario y su id
        end
    end
```

**Detalles importantes:**

- El **422** lo responde FastAPI **sin llegar a MySQL**: los datos se rechazan antes.
- El **409** lo provoca **MySQL**, porque el correo es `UNIQUE`; FastAPI lo traduce a un mensaje claro.
- Los `%s` del SQL son los lugares donde PyMySQL pone los datos **de forma segura** (así se evita la inyección SQL).

---

## 5. La colección de Postman

Las 9 peticiones van en orden. La petición 3 guarda el `id` del usuario nuevo en la variable `usuario_id`, y las peticiones 4, 5, 8 y 9 la usan.

```mermaid
flowchart TD
    R1["1. GET /salud<br/>✅ 200"]
    R2["2. GET /usuarios<br/>✅ 200"]
    R3["3. POST /usuarios<br/>✅ 201"]
    R4["4. GET /usuarios/{{usuario_id}}<br/>✅ 200"]
    R5["5. PUT /usuarios/{{usuario_id}}<br/>✅ 200"]
    R6["6. POST con correo repetido<br/>❌ 409"]
    R7["7. POST sin nombre<br/>❌ 422"]
    R8["8. DELETE /usuarios/{{usuario_id}}<br/>✅ 204"]
    R9["9. GET /usuarios/{{usuario_id}}<br/>❌ 404"]
    V[("📦 variable<br/>usuario_id")]

    R1 --> R2 --> R3 --> R4 --> R5 --> R6 --> R7 --> R8 --> R9
    R3 -. "guarda el id" .-> V
    V -. "usa el id" .-> R4
    V -. "usa el id" .-> R5
    V -. "usa el id" .-> R8
    V -. "usa el id" .-> R9
```

- Los ❌ son **errores a propósito**: demuestran que la API responde bien cuando algo está mal. Sus pruebas también salen en verde.
- Al final, el usuario creado queda borrado: la base vuelve a tener los 3 usuarios de ejemplo.

---

## 6. Los archivos y GitHub

Qué archivos se suben a GitHub y cuáles se quedan solo en el equipo.

```mermaid
flowchart TD
    subgraph GITHUB["☁️ Se suben a GitHub"]
        EX["📄 .env.example<br/>plantilla sin contraseña"]
        REQ["📄 requirements.txt<br/>lista de librerías"]
        GI["📄 .gitignore<br/>lo que Git ignora"]
        CODE["📄 main.py · conexion.py · database.sql<br/>test_usuarios.py · colección de Postman<br/>README · TUTORIAL · GUION · DIAGRAMAS"]
    end

    subgraph EQUIPO["💻 Solo en su equipo (no se suben)"]
        ENV["🔒 .env<br/>contraseña real"]
        VENV["📁 .venv/<br/>librerías instaladas"]
    end

    EX -- "se copia y se escribe la contraseña" --> ENV
    REQ -- "pip install -r requirements.txt" --> VENV
    GI -. "impide subirlos" .-> EQUIPO
```

- **`.env`** tiene la contraseña: por seguridad **nunca** se sube. Se sube **`.env.example`**, que es la plantilla.
- **`.venv/`** se crea en cada equipo con `requirements.txt`.
- **`.gitignore`** es la lista de lo que Git debe ignorar.
