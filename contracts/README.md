## Mejoras para el contrato KipuBank

## Estructura General del Código

El código de Solidity que presentas define una estructura de tres contratos interconectados (RoleContract, BolivaresFuertesContract, y KipuBankContract) que, en conjunto, implementan un sistema de banca o depósito descentralizado que soporta roles de usuario, un token ERC-20 personalizado y la gestión de depósitos/retiros de múltiples tokens (incluido Ether).

A continuación, se detalla la lógica y estructura de cada contrato:


| **Contrato**             | **Propósito**                    | **Funcionalidades Principales**                                                                                                                                                          | **Herencia**                        |
|--------------------------|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| RoleContract             | Control de Acceso (ACL).         | Define Propietario, Administradores y Operadores. Establece modificadores (soloPropietario, etc.) para restringir el acceso a funciones.                                                 | Ninguna                             |
| BolivaresFuertesContract | Token (ERC-20) y Conversión ETH. | Crea un token "Bolivares Fuerte" (BSF). Permite a los usuarios enviar ETH y recibir BSF a una tasa fija (Inicialmente 3500 BSF / 1 ETH).                                                 | Hereda de ERC20 y RoleContract.     |
| KipuBankContract         | Banca Multi-Token y Oráculo.     | Permite depósitos y retiros de ETH y cualquier token ERC-20. Almacena balances internos. Usa Chainlink para obtener el precio ETH/USD e imponer un límite de seguridad (limiteBancoUSD). | Hereda de BolivaresFuertesContract. |


### Roles Jerárquicos y su Lógica de Acceso en el sistema de contratos

| **Rol**         | **Modificador de Acceso** | **Lógica y Permisos**                                                                                                                                                           |
|-----------------|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Propietario     | soloPropietario           | Máxima autoridad. Controla la administración, la propiedad del contrato y los fondos de emergencia.                                                                             |
|                 |                           | Gestionar Administradores: Agregar/Eliminar Administradores.<br>Transferir Propiedad del contrato.<br>Crear (mint) nuevos tokens BSF.<br>Retirar ETH acumulado de conversiones. |
|                 |                           |                                                                                                                                                                                 |
|                 |                           |                                                                                                                                                                                 |
|                 |                           |                                                                                                                                                                                 |
| Administrador   | soloAdministrador         | Autoridad de gestión. Controla parámetros económicos y la operativa de seguridad.                                                                                               |
|                 |                           | Gestionar Operadores: Agregar/Eliminar Operadores.<br>Actualizar Tasa de cambio (ETH a BSF).<br>Establecer Límite total del banco en USD (limiteBancoUSD).                      |
|                 |                           |                                                                                                                                                                                 |
|                 |                           |                                                                                                                                                                                 |
| Operador        | soloOperador              | Autoridad de emergencia. Enfocado en la seguridad y el manejo de fondos críticos.                                                                                               |
|                 |                           | Ejecutar Retiro de Emergencia de ETH.                                                                                                                                           |
| Usuario/Cliente |                           | Cliente del banco. Su propósito es interactuar con los servicios financieros del contrato.                                                                                      |
|                 |                           | Depositar ETH o tokens ERC-20.<br>Retirar sus propios balances depositados.<br>Convertir ETH a BSF (el token del contrato).                                                     |



| **Rol**         | **Modificador de Acceso** | **Lógica y Permisos**                                                                                                                                                           |
|-----------------|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Propietario     | soloPropietario           | Máxima autoridad. Controla la administración, la propiedad del contrato y los fondos de emergencia.                                                                             |
|                 |                           | Gestionar Administradores: Agregar/Eliminar Administradores.<br>Transferir Propiedad del contrato.<br>Crear (mint) nuevos tokens BSF.<br>Retirar ETH acumulado de conversiones. |
| Administrador   | soloAdministrador         | Autoridad de gestión. Controla parámetros económicos y la operativa de seguridad.                                                                                               |
|                 |                           | Gestionar Operadores: Agregar/Eliminar Operadores.<br>Actualizar Tasa de cambio (ETH a BSF).<br>Establecer Límite total del banco en USD (limiteBancoUSD).                      |
| Operador        | soloOperador              | Autoridad de emergencia. Enfocado en la seguridad y el manejo de fondos críticos.                                                                                               |
|                 |                           | Ejecutar Retiro de Emergencia de ETH.                                                                                                                                           |
| Usuario/Cliente |                           | Cliente del banco. Su propósito es interactuar con los servicios financieros del contrato.                                                                                      |
|                 |                           | Depositar ETH o tokens ERC-20.<br>Retirar sus propios balances depositados.<br>Convertir ETH a BSF (el token del contrato).                                                     |
