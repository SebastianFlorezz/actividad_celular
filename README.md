# Nexo Inventario

Aplicación Flutter para que un pequeño negocio administre su catálogo de
productos y proveedores. Esta versión conserva las pantallas y relaciones del
proyecto previo y sincroniza los registros con Supabase en lugar de guardar el
inventario en SQLite local.

## Persistencia y estructura

La persistencia es el almacenamiento que permite conservar información después
de cerrar la aplicación. El almacenamiento local queda en un dispositivo; la
base de datos remota se aloja en un servidor y permite recuperar los mismos
datos desde cualquier dispositivo autorizado con conexión a internet.

El servicio elegido es **Supabase**, que proporciona PostgreSQL remoto, API
REST, conexión HTTPS, autenticación de correo/contraseña y políticas Row Level
Security (RLS). `supabase_flutter` envía las operaciones desde la aplicación.
Las consultas y cambios se ejecutan en PostgreSQL; no se simulan en una lista
local. Al volver a abrir o actualizar las pantallas, la app vuelve a consultar
el servicio central.

El esquema `supabase/schema.sql` crea estas entidades:

- `perfiles`: cuenta relacionada con `auth.users`; se crea mediante un trigger
  al registrar al usuario.
- `proveedores`: nombre, teléfono, correo y `owner_id`.
- `productos`: nombre, precio, existencias, `proveedor_id` y `owner_id`.

Cada producto pertenece a un proveedor y cada fila de negocio pertenece al
usuario que la creó. Los índices, claves foráneas y restricciones de precio y
existencias se aplican en PostgreSQL. La eliminación de un proveedor con
productos reasigna primero los productos en una función SQL atómica.

## Configuración de Supabase

1. Crea un proyecto en Supabase.
2. En **SQL Editor**, ejecuta el contenido de `supabase/schema.sql`.
3. En **Authentication → Providers → Email**, habilita correo/contraseña.
   Para una demostración controlada puedes desactivar temporalmente la
   confirmación por correo; en producción debe mantenerse habilitada.
4. Copia la **Project URL** y la clave **Publishable** (o `anon/public`) desde
   la configuración de API. Nunca uses la clave `Secret`/`service_role` en la
   app.
5. Crea `supabase_config.json` en la raíz del proyecto (está excluido de Git)
   con las dos variables:

```json
{
  "SUPABASE_URL": "https://TU-PROYECTO.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "TU-CLAVE-PUBLICA"
}
```

6. Obtén dependencias y ejecuta desde la raíz del proyecto:

```shell
flutter pub get
flutter run --dart-define-from-file=supabase_config.json
```

La app también acepta `SUPABASE_ANON_KEY` para proyectos que todavía usan esa
clave. Muestra una pantalla de configuración si faltan la URL o la clave
pública. La clave pública no concede acceso por sí sola: las reglas RLS y el
token de sesión son los que autorizan las operaciones.

## Autenticación y seguridad

La primera pantalla permite crear cuenta o iniciar sesión con correo y
contraseña. Supabase valida las credenciales y administra los tokens de sesión;
la contraseña se gestiona de forma segura en el servicio y la aplicación nunca
la guarda ni la compara localmente. El tráfico usa HTTPS. Los errores de
credenciales se muestran al usuario y el menú de cuenta permite cerrar sesión.

Las políticas RLS de `schema.sql` permiten a un usuario autenticado leer,
crear, modificar y borrar únicamente sus propios proveedores y productos.
También validan que un producto solo se asocie a un proveedor del mismo dueño.
Una persona sin sesión no satisface el rol `authenticated` ni puede leer o
modificar registros. La función para eliminar proveedores se ejecuta con los
permisos del usuario, comprueba propietario y reasigna productos dentro de una
sola transacción de PostgreSQL.

## Funcionalidades

- Inicio con resumen remoto y accesos a productos y proveedores.
- Inicio/cierre de sesión y registro de cuentas.
- Consulta de productos con búsqueda y consulta de proveedores.
- Registro, detalle, edición y eliminación confirmada de productos.
- Registro, edición y eliminación de proveedores; sus productos se transfieren
  de forma segura antes de borrar el proveedor.
- Mensajes de error y opción para volver a intentar consultas.

Los cambios se escriben directamente en Supabase; las pantallas consultan de
nuevo los registros al actualizar, de modo que el flujo de sincronización es
aplicación → PostgreSQL y PostgreSQL → aplicación.

## Prueba de sincronización para la sustentación

1. Ejecuta la aplicación con las variables de Supabase y registra una cuenta o
   inicia sesión.
2. Registra un proveedor y luego un producto relacionado.
3. Comprueba los registros en las tablas `proveedores` y `productos` del Table
   Editor de Supabase.
4. Abre el detalle del producto, edítalo y verifica el nuevo valor en
   PostgreSQL.
5. Elimina el producto desde la aplicación y comprueba que ya no aparece en la
   tabla remota.
6. Cierra sesión e intenta entrar con credenciales inválidas. Debe mostrarse un
   error y no aparecer el inventario.
7. Para probar aislamiento, registra otro usuario; sus consultas no deben
   revelar los registros del usuario anterior.

Las capturas de la aplicación y del Table Editor deben tomarse en el proyecto
Supabase configurado por quien realiza la actividad. No se incluyen capturas ni
credenciales ficticias en el repositorio.

## Validación

```shell
flutter analyze
flutter test
```
