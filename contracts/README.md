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

| **Rol**         | **Modificador de Acceso** | **Lógica y Permisos**                                                                                                                                                                                                                                                                  |
|-----------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Propietario     | soloPropietario           | Máxima autoridad. Controla la administración, la propiedad del contrato y los fondos de emergencia.<br>Gestionar Administradores: Agregar/Eliminar Administradores.<br>Transferir Propiedad del contrato.<br>Crear (mint) nuevos tokens BSF.<br>Retirar ETH acumulado de conversiones. |
| Administrador   | soloAdministrador         | Autoridad de gestión. Controla parámetros económicos y la operativa de seguridad.<br>Gestionar Operadores: Agregar/Eliminar Operadores.<br>Actualizar Tasa de cambio (ETH a BSF).<br>Establecer Límite total del banco en USD (limiteBancoUSD).                                        |
| Operador        | soloOperador              | Autoridad de emergencia. Enfocado en la seguridad y el manejo de fondos críticos.<br>Ejecutar Retiro de Emergencia de ETH.                                                                                                                                                             |
| Usuario/Cliente |                           | Cliente del banco. Su propósito es interactuar con los servicios financieros del contrato.<br>Depositar ETH o tokens ERC-20.<br>Retirar sus propios balances depositados.<br>Convertir ETH a BSF (el token del contrato).                                                              |


Funciones de los contratos

| **Contrato**             | **Función**              | **Rol de Acceso**    | **Propósito**                                                                                    |
|--------------------------|--------------------------|----------------------|--------------------------------------------------------------------------------------------------|
| RoleContract             | agregarAdministrador     | Propietario          | Otorga el rol de Administrador a una dirección.                                                  |
|                          | eliminarAdministrador    | Propietario          | Revoca el rol de Administrador a una dirección.                                                  |
|                          | agregarOperador          | Administrador        | Otorga el rol de Operador a una dirección.                                                       |
|                          | eliminarOperador         | Administrador        | Revoca el rol de Operador a una dirección.                                                       |
|                          | transferirPropiedad      | Propietario          | Cambia la dirección del Propietario del contrato.                                                |
|                          | esPropietario            | Cualquiera (View)    | Consulta si una dirección tiene el rol de Propietario.                                           |
|                          | esAdministrador          | Cualquiera (View)    | Consulta si una dirección tiene el rol de Administrador.                                         |
|                          | esOperador               | Cualquiera (View)    | Consulta si una dirección tiene el rol de Operador.                                              |
| BolivaresFuertesContract | previsualizarConversion  | Cualquiera (View)    | Calcula cuántos BSF se obtendrían por una cantidad de ETH, sin ejecutar la transacción.          |
|                          | convertirETHaBSF         | Cualquiera (Payable) | Permite a los usuarios enviar ETH al contrato y recibir la cantidad equivalente de tokens BSF.   |
|                          | actualizarTasa           | Administrador        | Modifica la tasa de cambio de BSF por ETH.                                                       |
|                          | calcularBolivares        | Cualquiera (View)    | Idéntica a previsualizarConversion, calcula BSF por ETH.                                         |
|                          | mint                     | Propietario          | Acuña (crea) nuevos tokens BSF y los asigna a una dirección.                                     |
|                          | retirarETH               | Propietario          | Retira el saldo total de ETH del contrato (acumulado de las conversiones) hacia el Propietario.  |
| KipuBankContract         | depositoETH              | Cualquiera (Payable) | Permite depositar ETH en el banco interno. Sujeto a límites de seguridad en USD (dentroBankCap). |
|                          | depositoToken            | Cualquiera           | Permite depositar un token ERC-20 específico en el banco. Requiere aprobación previa (approve).  |
|                          | retiroETH                | Cualquiera           | Permite al usuario retirar su saldo de ETH depositado. Sujeto a límite por retiro.               |
|                          | retiroToken              | Cualquiera           | Permite al usuario retirar su saldo de tokens depositado. Sujeto a límite por retiro.            |
|                          | emergenciaRetiro         | Operador             | Permite retirar ETH de forma manual a una dirección en casos de emergencia.                      |
|                          | obtenerBalance           | Cualquiera (View)    | Consulta el balance interno de un usuario para un token específico (incluyendo ETH).             |
|                          | obtenerBalanceContrato   | Cualquiera (View)    | Retorna la cantidad total de ETH que tiene el contrato.                                          |
|                          | obtenerPrecioETHUSD      | Cualquiera (View)    | Consulta el precio actual de ETH en USD usando el oráculo de Chainlink.                          |
|                          | convertirETHaUSD         | Cualquiera (View)    | Convierte una cantidad de ETH (en wei) a su valor equivalente en USD utilizando el oráculo.      |
|                          | establecerLimiteBancoUSD | Administrador        | Actualiza el límite máximo de valor que el banco puede contener, medido en USD.                  |
|                          | convertirDecimalesUSDC   | Cualquiera (View)    | Función auxiliar para escalar la cantidad de un token a 6 decimales (formato USDC).              |
