## Mejoras para el contrato KipuBank

## Estructura General del Código

El código de Solidity que presentas define una estructura de tres contratos interconectados (RoleContract, BolivaresFuertesContract, y KipuBankContract) que, en conjunto, implementan un sistema de banca o depósito descentralizado que soporta roles de usuario, un token ERC-20 personalizado y la gestión de depósitos/retiros de múltiples tokens (incluido Ether).

A continuación, se detalla la lógica y estructura de cada contrato:


| **Contrato**             | **Propósito**                    | **Funcionalidades Principales**                                                                                                                                                          | **Herencia**                        |
|--------------------------|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| RoleContract             | Control de Acceso (ACL).         | Define Propietario, Administradores y Operadores. Establece modificadores (soloPropietario, etc.) para restringir el acceso a funciones.                                                 | Ninguna                             |
| BolivaresFuertesContract | Token (ERC-20) y Conversión ETH. | Crea un token "Bolivares Fuerte" (BSF). Permite a los usuarios enviar ETH y recibir BSF a una tasa fija (Inicialmente 3500 BSF / 1 ETH).                                                 | Hereda de ERC20 y RoleContract.     |
| KipuBankContract         | Banca Multi-Token y Oráculo.     | Permite depósitos y retiros de ETH y cualquier token ERC-20. Almacena balances internos. Usa Chainlink para obtener el precio ETH/USD e imponer un límite de seguridad (limiteBancoUSD). | Hereda de BolivaresFuertesContract. |


<div align="center">
  <img src="..\img\contratos.png" alt="Permisos">
</div>


### Roles Jerárquicos y su Lógica de Acceso en el sistema de contratos

<div align="center">
  <img src="..\img\roles.png" alt="Permisos">
</div>