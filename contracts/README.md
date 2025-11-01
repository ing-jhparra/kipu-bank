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

El sistema utiliza tres roles jerárquicos (Propietario, Administrador y Operador) para controlar el acceso a funciones sensibles del contrato mediante modificadores de acceso (ej., soloPropietario, soloAdministrador, soloOperador), asegurando que solo el personal autorizado pueda gestionar parámetros, crear tokens o manejar emergencias.

| **Rol**         | **Modificador de Acceso** | **Lógica y Permisos**                                                                                                                                                                                                                                                                  |
|-----------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Propietario     | soloPropietario           | Controla la administración, la propiedad del contrato y los fondos de emergencia.<br>Gestionar Administradores: Agregar/Eliminar Administradores.<br>Transferir Propiedad del contrato.<br>Crear (mint) nuevos tokens BSF.<br>Retirar ETH acumulado de conversiones. |
| Administrador   | soloAdministrador         | Controla parámetros económicos y la operativa de seguridad.<br>Gestionar Operadores: Agregar/Eliminar Operadores.<br>Actualizar Tasa de cambio (ETH a BSF).<br>Establecer Límite total del banco en USD (limiteBancoUSD).                                        |
| Operador        | soloOperador              | Enfocado en la seguridad y el manejo de fondos críticos.<br>Ejecutar Retiro de Emergencia de ETH.                                                                                                                                                             |
| Usuario/Cliente |                           | Su propósito es interactuar con los servicios financieros del contrato.<br>Depositar ETH o tokens ERC-20.<br>Retirar sus propios balances depositados.<br>Convertir ETH a BSF (el token del contrato).                                                              |


Funciones de los contratos

Las funciones en Solidity son bloques de código ejecutables que encapsulan una lógica específica, siendo el medio principal para interactuar y modificar el estado de un contrato inteligente. Permiten definir las acciones que los usuarios o contratos pueden invocar, aplicando modificadores para controlar el acceso y la seguridad.

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


<table style="border: 2px solid black; border-collapse: collapse; width: 100%;">
  <thead>
    <tr>
      <th style="border: 2px solid black; padding: 8px;">Contrato</th>
      <th style="border: 2px solid black; padding: 8px;">Función</th>
      <th style="border: 2px solid black; padding: 8px;">Rol de Acceso</th>
      <th style="border: 2px solid black; padding: 8px;">Propósito</th>
    </tr>
  </thead>
  <tbody>
    <!-- RoleContract -->
    <tr>
      <td style="border: 2px solid black; padding: 8px;" rowspan="8">RoleContract</td>
      <td style="border: 2px solid black; padding: 8px;">agregarAdministrador</td>
      <td style="border: 2px solid black; padding: 8px;">Propietario</td>
      <td style="border: 2px solid black; padding: 8px;">Otorga el rol de Administrador a una dirección.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">eliminarAdministrador</td>
      <td style="border: 2px solid black; padding: 8px;">Propietario</td>
      <td style="border: 2px solid black; padding: 8px;">Revoca el rol de Administrador a una dirección.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">agregarOperador</td>
      <td style="border: 2px solid black; padding: 8px;">Administrador</td>
      <td style="border: 2px solid black; padding: 8px;">Otorga el rol de Operador a una dirección.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">eliminarOperador</td>
      <td style="border: 2px solid black; padding: 8px;">Administrador</td>
      <td style="border: 2px solid black; padding: 8px;">Revoca el rol de Operador a una dirección.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">transferirPropiedad</td>
      <td style="border: 2px solid black; padding: 8px;">Propietario</td>
      <td style="border: 2px solid black; padding: 8px;">Cambia la dirección del Propietario del contrato.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">esPropietario</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Consulta si una dirección tiene el rol de Propietario.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">esAdministrador</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Consulta si una dirección tiene el rol de Administrador.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">esOperador</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Consulta si una dirección tiene el rol de Operador.</td>
    </tr>    
    <!-- BolivaresFuertesContract -->
    <tr>
      <td style="border: 2px solid black; padding: 8px;" rowspan="6">BolivaresFuertesContract</td>
      <td style="border: 2px solid black; padding: 8px;">previsualizarConversion</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Calcula cuántos BSF se obtendrían por una cantidad de ETH, sin ejecutar la transacción.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">convertirETHaBSF</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (Payable)</td>
      <td style="border: 2px solid black; padding: 8px;">Permite a los usuarios enviar ETH al contrato y recibir la cantidad equivalente de tokens BSF.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">actualizarTasa</td>
      <td style="border: 2px solid black; padding: 8px;">Administrador</td>
      <td style="border: 2px solid black; padding: 8px;">Modifica la tasa de cambio de BSF por ETH.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">calcularBolivares</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Idéntica a previsualizarConversion, calcula BSF por ETH.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">mint</td>
      <td style="border: 2px solid black; padding: 8px;">Propietario</td>
      <td style="border: 2px solid black; padding: 8px;">Acuña (crea) nuevos tokens BSF y los asigna a una dirección.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">retirarETH</td>
      <td style="border: 2px solid black; padding: 8px;">Propietario</td>
      <td style="border: 2px solid black; padding: 8px;">Retira el saldo total de ETH del contrato (acumulado de las conversiones) hacia el Propietario.</td>
    </tr>    
    <!-- KipuBankContract -->
    <tr>
      <td style="border: 2px solid black; padding: 8px;" rowspan="11">KipuBankContract</td>
      <td style="border: 2px solid black; padding: 8px;">depositoETH</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (Payable)</td>
      <td style="border: 2px solid black; padding: 8px;">Permite depositar ETH en el banco interno. Sujeto a límites de seguridad en USD (dentroBankCap).</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">depositoToken</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera</td>
      <td style="border: 2px solid black; padding: 8px;">Permite depositar un token ERC-20 específico en el banco. Requiere aprobación previa (approve).</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">retiroETH</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera</td>
      <td style="border: 2px solid black; padding: 8px;">Permite al usuario retirar su saldo de ETH depositado. Sujeto a límite por retiro.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">retiroToken</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera</td>
      <td style="border: 2px solid black; padding: 8px;">Permite al usuario retirar su saldo de tokens depositado. Sujeto a límite por retiro.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">emergenciaRetiro</td>
      <td style="border: 2px solid black; padding: 8px;">Operador</td>
      <td style="border: 2px solid black; padding: 8px;">Permite retirar ETH de forma manual a una dirección en casos de emergencia.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">obtenerBalance</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Consulta el balance interno de un usuario para un token específico (incluyendo ETH).</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">obtenerBalanceContrato</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Retorna la cantidad total de ETH que tiene el contrato.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">obtenerPrecioETHUSD</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Consulta el precio actual de ETH en USD usando el oráculo de Chainlink.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">convertirETHaUSD</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Convierte una cantidad de ETH (en wei) a su valor equivalente en USD utilizando el oráculo.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">establecerLimiteBancoUSD</td>
      <td style="border: 2px solid black; padding: 8px;">Administrador</td>
      <td style="border: 2px solid black; padding: 8px;">Actualiza el límite máximo de valor que el banco puede contener, medido en USD.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;">convertirDecimalesUSDC</td>
      <td style="border: 2px solid black; padding: 8px;">Cualquiera (View)</td>
      <td style="border: 2px solid black; padding: 8px;">Función auxiliar para escalar la cantidad de un token a 6 decimales (formato USDC).</td>
    </tr>
  </tbody>
</table>