# Nexo Inventario

Aplicación móvil Flutter para administrar productos y proveedores con una base de
datos SQLite local. Los registros se crean desde la aplicación y permanecen en
el dispositivo al cerrar la app.

## Ejecutar

```shell
flutter pub get
flutter run
```

La aplicación está preparada para Android e iOS. Para validar el proyecto:

```shell
flutter analyze
flutter test
```

## Funcionalidades

- Panel de inicio con totales y accesos a productos y proveedores.
- CRUD completo de productos y proveedores.
- Búsqueda de productos por nombre.
- Formularios con validación de campos, precio, existencias y correo electrónico.
- Selección de proveedor al registrar o editar productos.
- Mensajes de confirmación, errores y estados vacíos.
- Bloqueo de eliminación de proveedores que tengan productos asociados.
- Transferencia transaccional de sus productos a otro proveedor antes de eliminarlo.

## Organización

- `lib/models/`: modelos `Product` y `Supplier`.
- `lib/services/database_service.dart`: inicialización de SQLite y operaciones CRUD.
- `lib/screens/`: panel, listados y formularios.
- `test/`: pruebas de serialización y lectura de los modelos.

## Base de datos

La base de datos `nexo_inventario.db` se crea en el almacenamiento local de la
aplicación. Contiene:

- `proveedores(id, nombre, telefono, correo)`.
- `productos(id, nombre, precio, stock, proveedor_id)`.

`productos.proveedor_id` referencia `proveedores.id` en una relación uno a
varios. Las claves foráneas se activan al abrir SQLite; la relación usa
`ON DELETE RESTRICT` para evitar registros huérfanos. El servicio también
comprueba si existen productos antes de eliminar un proveedor.
Si el proveedor tiene productos, la aplicación permite transferirlos a otro
proveedor en la misma transacción; si no hay otro proveedor disponible, informa
qué debe hacerse antes de poder eliminarlo.

El listado de productos obtiene el nombre del proveedor con un `INNER JOIN`
entre `productos.proveedor_id` y `proveedores.id`.
