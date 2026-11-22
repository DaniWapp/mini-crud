# Guion de la exposición: Mini CRUD de usuarios

Duración aproximada: **5 minutos**.

Las frases entre comillas son una guía de qué decir: no hay que memorizarlas palabra por palabra.

---

## Antes de la exposición (10 minutos antes)

Deje todo listo y abierto, para no perder tiempo delante del profesor.

1. **Encender MySQL** (en una ventana de PowerShell que queda abierta):

```
& "C:\AppServ\MySQL\bin\mysqld.exe" --defaults-file="C:\AppServ\MySQL\my.ini" --console
```

2. **Dejar la base limpia** (otra ventana, desde `C:\AppServ\www\mini-crud`). Así el usuario nuevo tendrá el id 4:

```
cmd /c "C:\AppServ\MySQL\bin\mysql.exe -u root -t --default-character-set=utf8mb4 < database.sql"
```

3. **Encender el servidor** (otra ventana que queda abierta, desde `C:\AppServ\www\mini-crud`):

```
.\.venv\Scripts\python.exe -m uvicorn main:app --reload --port 8000
```

4. **Abrir y dejar listo:**
   - **Postman**, con la colección **Mini CRUD de usuarios** desplegada.
   - **phpMyAdmin**: [http://localhost/phpMyAdmin/](http://localhost/phpMyAdmin/), dentro de la base `mini_crud`, tabla `usuarios`, pestaña **Examinar**.
   - **VS Code** con `main.py` abierto.
   - El navegador con [http://localhost:8000/docs](http://localhost:8000/docs) en otra pestaña (plan B).

5. **Comprobar** que [http://localhost:8000/salud](http://localhost:8000/salud) responde `{"estado":"ok"}`.

> No ejecute Run collection ni pytest antes de exponer: el usuario nuevo ya no tendría el id 4. Si lo hizo, repita el paso 2.

---

## Guion

### 1. Presentación (30 segundos)

> "Mi proyecto es un mini CRUD de usuarios. CRUD significa Crear, Leer, Actualizar y Borrar, que son las cuatro operaciones básicas con datos.
> Hice un servidor con Python y FastAPI, que guarda los datos en MySQL. Voy a demostrar con Postman que los endpoints funcionan."

### 2. El código, muy rápido (1 minuto)

En VS Code, con `main.py` abierto:

> "Este es el servidor. Cada función con `@app.get`, `@app.post`, `@app.put` o `@app.delete` es un endpoint: una dirección más un método HTTP. Son 6 endpoints."

Señale la clase `UsuarioEntrada`:

> "Aquí defino qué datos debe traer un usuario: nombre y correo. Si falta un dato, FastAPI responde error 422 automáticamente."

Señale un `cursor.execute(... %s ...)`:

> "Las consultas SQL usan `%s`: así los datos del usuario nunca se pegan dentro del SQL, y se evita la inyección SQL."

Opcional, si hay tiempo:

> "La contraseña de la base de datos no está en el código: está en un archivo `.env` que no se sube a GitHub."

### 3. Las peticiones en Postman (2 minutos y medio)

Envíe cada petición con **Send**, en orden. En cada una, muestre el **código de respuesta** y el **Body**.

| # | Petición | Qué decir |
|---|---|---|
| 1 | Salud del servidor | "Primero compruebo que el servidor está encendido: responde 200, que significa OK." |
| 2 | Listar usuarios | "Este GET trae todos los usuarios de la base de datos. Hay 3 de ejemplo." |
| 3 | Crear usuario | Muestre la pestaña **Body** de arriba. "Con POST envío un usuario nuevo en formato JSON. Responde **201 Created** y me devuelve el usuario con su id, que lo pone MySQL." |
| — | **phpMyAdmin** | Recargue la tabla. "Aquí se ve que el usuario quedó guardado de verdad en la base de datos." |
| 4 | Ver el usuario creado | "Con GET y el id traigo solo ese usuario. Postman guardó el id en una variable, por eso la URL dice `usuario_id`." |
| 5 | Editar el usuario | "Con PUT cambio el nombre y el correo. Responde 200 con los datos nuevos." |
| — | **phpMyAdmin** | Recargue. "El nombre ya cambió en la base." |
| 6 | Correo repetido | "Ahora pruebo errores. Si intento crear un usuario con un correo que ya existe, responde **409 Conflict**, porque el correo es único." |
| 7 | Sin nombre | "Si falta el nombre, responde **422**: los datos están incompletos. FastAPI lo rechaza antes de llegar a la base." |
| 8 | Borrar el usuario | "Con DELETE borro el usuario. Responde **204 No Content**: salió bien y no devuelve nada." |
| — | **phpMyAdmin** | Recargue. "Ya no está en la base." |
| 9 | Ver el usuario borrado | "Si lo busco otra vez, responde **404 Not Found**: el usuario no existe." |

### 4. Run collection (30 segundos)

Pulse **...** sobre la colección → **Run** → **Start run**.

> "Cada petición tiene pruebas automáticas que revisan el código de respuesta. Con Run collection se ejecutan las 9 peticiones seguidas: salen 16 pruebas en verde y ninguna en rojo."

### 5. Cierre (20 segundos)

> "En resumen: monté un servidor con FastAPI, conectado a MySQL, con los 6 endpoints del CRUD, y demostré con Postman que funcionan, tanto cuando todo sale bien como cuando hay errores. El código está en GitHub, con un tutorial paso a paso."

---

## Plan B (si algo falla)

| Problema | Qué hacer |
|---|---|
| Postman no abre o no responde | Usar [http://localhost:8000/docs](http://localhost:8000/docs): en cada endpoint, **Try it out** y **Execute**. |
| Postman dice "Could not send request" / "ECONNREFUSED" | El servidor está apagado: revisar la ventana de Uvicorn y encenderlo otra vez. |
| La petición 2 responde 500 | MySQL está apagado: revisar su ventana y encenderlo otra vez. |
| La petición 4 responde 404 o la URL no tiene número | No se envió la petición 3: enviarla primero. |
| El usuario nuevo no tiene el id 4 | No importa, funciona igual. Para la próxima, dejar la base limpia antes (paso 2). |

---

## Preguntas probables del profesor

**¿Qué es un endpoint?**
Una dirección del servidor más un método HTTP. Por ejemplo, `GET /usuarios` y `POST /usuarios` tienen la misma dirección, pero son endpoints distintos.

**¿Qué diferencia hay entre GET, POST, PUT y DELETE?**
GET trae datos, POST crea, PUT edita y DELETE borra.

**¿Qué es FastAPI?**
Un framework de Python para crear APIs. Revisa los datos que llegan y crea sola la página de documentación `/docs`.

**¿Qué es Uvicorn?**
El servidor que pone a funcionar la API en un puerto, en este caso el 8000.

**¿Qué es JSON?**
El formato de texto con el que se envían y reciben los datos: `{"nombre": "Carlos", "correo": "..."}`.

**¿Por qué 201 y no 200 al crear?**
Porque 201 significa "Created": indica que se creó un registro nuevo.

**¿Qué pasa si envío un correo repetido?**
La base de datos tiene el correo como `UNIQUE` y lo rechaza; el servidor responde 409 Conflict.

**¿Cómo evita la inyección SQL?**
Las consultas usan `%s` y PyMySQL coloca cada valor de forma segura. Nunca se pega el texto del usuario dentro del SQL.

**¿Dónde está la contraseña de la base de datos?**
En un archivo `.env` que no se sube a GitHub (está en el `.gitignore`). El servidor usa un usuario de MySQL que solo tiene permisos sobre la base `mini_crud`.

**¿El DELETE borra de verdad?**
Sí, borra la fila de la tabla. En un proyecto real a veces se marca como "inactivo" en lugar de borrar, pero aquí se eligió borrar para que sea sencillo.

**¿Cómo pasa el id de una petición a otra en Postman?**
La prueba de la petición 3 guarda el `id` de la respuesta en la variable `usuario_id` con `pm.collectionVariables.set`, y las demás peticiones la usan como `{{usuario_id}}`.

**¿Hay pruebas automáticas aparte de Postman?**
Sí, en `test_usuarios.py` con pytest: 9 pruebas que se ejecutan con un solo comando.
