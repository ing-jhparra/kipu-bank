## Mejoras para el contrato KipuBank

## Estructura General del Código

### Sistema de Roles

- Propietario: Creador del contrato, puede agregar/eliminar administradores
- Administradores: Pueden agregar/eliminar operadores
- Operadores: Pueden ejecutar retiros de emergencia
- Usuarios: Se registran automáticamente al hacer su primer depósito

### Jerarquía

PROPIETARIO : Nombrar y remover administradores, Transferir la propiedad completa del sistema, Crear nuevos tokens BsF (aumentar supply), Retirar todo el ETH acumulado en el contrato

    ↓

ADMINISTRADORES :   Gestionar el equipo operativo, Modificar la tasa ETH ↔ BsF, 

    ↓

OPERADORES : Realizar retiros sin límites normales, Consultar estados internos del sistema, Depositar y retirar ETH con límites, Convertir ETH a tokens BsF, Consultar sus propios balances y cálculos

    ↓

USUARIOS 

### Permisos por Rol

<div align="center">
  <img src="..\img\permisos.png" alt="Permisos">
</div>



### Los Contratos Inteligentes

- RoleContract: Este contrato establece un sistema de permisos jerárquico para controlar quién puede ejecutar funciones críticas.

- BolivaresFuertesContract: Este contrato crea un token ERC-20 y le da la capacidad de ser comprado con Ether.


- KipuBankContract: Este contrato extiende las funcionalidades del token para crear un sistema de depósito y retiro de ETH con límites.

### Estructura de Herencia

RoleContract (Base)

    ↑

BolivaresFuertesContract (ERC20 + RoleContract)  

    ↑

KipuBankContract (RoleContract + BolivaresFuertesContract)

