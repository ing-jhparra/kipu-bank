## Mejoras para el contrato KipuBank

## Estructura General del Código

### Sistema de Roles

- Propietario: Creador del contrato, puede agregar/eliminar administradores
- Administradores: Pueden agregar/eliminar operadores
- Operadores: Pueden ejecutar retiros de emergencia
- Usuarios: Se registran automáticamente al hacer su primer depósito

### Jerarquía

PROPIETARIO 
    ↓
ADMINISTRADORES  
    ↓
OPERADORES 
    ↓
USUARIOS 

### Los Contratos Inteligentes

- RoleContract: 

Este contrato establece un sistema de permisos jerárquico para controlar quién puede ejecutar funciones críticas.

- BolivaresFuertesContract:

Este contrato crea un token ERC-20 y le da la capacidad de ser comprado con Ether.


- KipuBankContract:

Este contrato extiende las funcionalidades del token para crear un sistema de depósito y retiro de ETH con límites.

### Estructura de Herencia

RoleContract (Base)
    ↑
BolivaresFuertesContract (ERC20 + RoleContract)  
    ↑
KipuBankContract (RoleContract + BolivaresFuertesContract)

## Funcionalidades Principales

### Depositos
Los usuarios pueden depositar ETH de 3 formas:

- Función deposito()
- Enviando ETH directamente (función receive())
- Cualquier transacción (función fallback())

### Retiros
- Los usuarios pueden retirar hasta el límite establecido
- Deben tener balance suficiente

### Límites de Seguridad
limiteTotalDeposito: Máximo total que puede haber en el contrato
limiteRetiro: Máximo que un usuario puede retirar por transacción

## Pruebas 
### Propietario Inicial
### Propietario gestiona los Administradores
### Administradores gestiona los Operadores
### Registro Automático de Usuarios
