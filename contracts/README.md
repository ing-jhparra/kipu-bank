## Mejoras para el contrato KipuBank

Este proyecto implementa un sistema bancario descentralizado con tres contratos inteligentes interconectados que ofrecen:

- Sistema de Roles Jerárquico - Gestión de permisos para propietario, administradores y operadores
- Token Bolívar Fuerte (BSF) - Token ERC20 con mecanismo de conversión ETH/BSF
- Banco Multitoken - Plataforma bancaria con soporte para múltiples tokens y contabilidad interna

### Las principales mejoras incluyen:

- Arquitectura modular con herencia de contratos para mejor mantenibilidad
- Sistema de seguridad robusto con modificadores de acceso y validaciones
- Integración con Chainlink para oráculos de precios en tiempo real
- Límites configurables para depósitos y retiros
- Soporte multi-token con conversión automática de decimales

## Decisiones de Diseño y Trade-offs

- Usar herencia de contratos (RoleContract → BolivaresFuertesContract → KipuBankContract)
- Implementar roles jerárquicos (Propietario → Administradores → Operadores)
- Implementar múltiples capas de límites (total, por retiro, bank cap USD)
- Usar oráculos descentralizados para precios
- Función automática para convertir entre diferentes decimales de tokens
- Tasa de cambio fija administrable vs oráculo en tiempo real
- Incluir función de retiro de emergencia para operadores

## Estructura General del Código

El código de Solidity que presentas define una estructura de tres contratos interconectados (RoleContract, BolivaresFuertesContract, y KipuBankContract) que, en conjunto, implementan un sistema de banca o depósito descentralizado que soporta roles de usuario, un token ERC-20 personalizado y la gestión de depósitos/retiros de múltiples tokens (incluido Ether).

A continuación, se detalla la lógica y estructura de cada contrato:


<table style="border: 2px solid black; border-collapse: collapse; width: 100%;">
  <thead>
    <tr>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Contrato</th>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Propósito</th>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Funcionalidades Principales</th>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Herencia</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="border: 2px solid black; padding: 8px;"><strong>RoleContract</strong></td>
      <td style="border: 2px solid black; padding: 8px;">Control de Acceso (ACL).</td>
      <td style="border: 2px solid black; padding: 8px;">
        Define Propietario, Administradores y Operadores. Establece modificadores (soloPropietario, etc.) para restringir el acceso a funciones.
      </td>
      <td style="border: 2px solid black; padding: 8px;">Ninguna</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;"><strong>BolivaresFuertesContract</strong></td>
      <td style="border: 2px solid black; padding: 8px;">Token (ERC-20) y Conversión ETH.</td>
      <td style="border: 2px solid black; padding: 8px;">
        Crea un token "Bolivares Fuerte" (BSF). Permite a los usuarios enviar ETH y recibir BSF a una tasa fija (Inicialmente 3500 BSF / 1 ETH).
      </td>
      <td style="border: 2px solid black; padding: 8px;">Hereda de ERC20 y RoleContract.</td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;"><strong>KipuBankContract</strong></td>
      <td style="border: 2px solid black; padding: 8px;">Banca Multi-Token y Oráculo.</td>
      <td style="border: 2px solid black; padding: 8px;">
        Permite depósitos y retiros de ETH y cualquier token ERC-20. Almacena balances internos. Usa Chainlink para obtener el precio ETH/USD e imponer un límite de seguridad (limiteBancoUSD).
      </td>
      <td style="border: 2px solid black; padding: 8px;">Hereda de BolivaresFuertesContract.</td>
    </tr>
  </tbody>
</table>


### Roles Jerárquicos y su Lógica de Acceso en el sistema de contratos

El sistema utiliza tres roles jerárquicos (Propietario, Administrador y Operador) para controlar el acceso a funciones sensibles del contrato mediante modificadores de acceso (ej., soloPropietario, soloAdministrador, soloOperador), asegurando que solo el personal autorizado pueda gestionar parámetros, crear tokens o manejar emergencias.

<table style="border: 2px solid black; border-collapse: collapse; width: 100%;">
  <thead>
    <tr>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Rol</th>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Modificador de Acceso</th>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Lógica y Permisos</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="border: 2px solid black; padding: 8px;"><strong>Propietario</strong></td>
      <td style="border: 2px solid black; padding: 8px;">soloPropietario</td>
      <td style="border: 2px solid black; padding: 8px;">
        Controla la administración, la propiedad del contrato y los fondos de emergencia.<br>
        Gestionar Administradores: Agregar/Eliminar Administradores.<br>
        Transferir Propiedad del contrato.<br>
        Crear (mint) nuevos tokens BSF.<br>
        Retirar ETH acumulado de conversiones.
      </td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;"><strong>Administrador</strong></td>
      <td style="border: 2px solid black; padding: 8px;">soloAdministrador</td>
      <td style="border: 2px solid black; padding: 8px;">
        Controla parámetros económicos y la operativa de seguridad.<br>
        Gestionar Operadores: Agregar/Eliminar Operadores.<br>
        Actualizar Tasa de cambio (ETH a BSF).<br>
        Establecer Límite total del banco en USD (limiteBancoUSD).
      </td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;"><strong>Operador</strong></td>
      <td style="border: 2px solid black; padding: 8px;">soloOperador</td>
      <td style="border: 2px solid black; padding: 8px;">
        Enfocado en la seguridad y el manejo de fondos críticos.<br>
        Ejecutar Retiro de Emergencia de ETH.
      </td>
    </tr>
    <tr>
      <td style="border: 2px solid black; padding: 8px;"><strong>Usuario/Cliente</strong></td>
      <td style="border: 2px solid black; padding: 8px;"></td>
      <td style="border: 2px solid black; padding: 8px;">
        Su propósito es interactuar con los servicios financieros del contrato.<br>
        Depositar ETH o tokens ERC-20.<br>
        Retirar sus propios balances depositados.<br>
        Convertir ETH a BSF (el token del contrato).
      </td>
    </tr>
  </tbody>
</table>                                                           


Funciones de los contratos

Las funciones en Solidity son bloques de código ejecutables que encapsulan una lógica específica, siendo el medio principal para interactuar y modificar el estado de un contrato inteligente. Permiten definir las acciones que los usuarios o contratos pueden invocar, aplicando modificadores para controlar el acceso y la seguridad.
      |
<table style="border: 2px solid black; border-collapse: collapse; width: 100%;">
  <thead>
    <tr>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Contrato</th>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Función</th>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Rol de Acceso</th>
      <th style="border: 2px solid black; padding: 8px; background-color: #f2f2f2;">Propósito</th>
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
      <td style="border: 2px solid black; padding: 8px;">Crea nuevos tokens BSF y los asigna a una dirección.</td>
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