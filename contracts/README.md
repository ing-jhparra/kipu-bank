## Mejoras para el contrato KipuBank

## Estructura General del Código

El código de Solidity que presentas define una estructura de tres contratos interconectados (RoleContract, BolivaresFuertesContract, y KipuBankContract) que, en conjunto, implementan un sistema de banca o depósito descentralizado que soporta roles de usuario, un token ERC-20 personalizado y la gestión de depósitos/retiros de múltiples tokens (incluido Ether).

A continuación, se detalla la lógica y estructura de cada contrato:

<div align="center">
  <img src="..\img\contratos.png" alt="Permisos">
</div>


### Roles Jerárquicos y su Lógica de Acceso en el sistema de contratos

<div align="center">
  <img src="..\img\roles.png" alt="Permisos">
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



