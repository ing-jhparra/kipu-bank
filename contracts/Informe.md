# Informe de Auditoria al contrato KipuBank

## 1. Breve descripción general de cómo funciona KipuBankV3

Es un protocolo bancario on-chain que combina servicios financieros tradicionales con la innovación DeFi, permitiendo a los usuarios depositar activos digitales para generar rendimientos a través de múltiples estrategias de yield farming, proporcionar liquidez en pools automatizados, acceder a productos de crédito colateralizados, y participar en gobernanza descentralizada, todo mientras mantiene la seguridad de fondos mediante contratos inteligentes auditados y mecanismos de control de riesgos en tiempo real.

### Token ERC20 (BSF Token)

* Implementado en BolivaresFuertesContract.
* Administra un suministro de BSF con acuñación centralizada.
* Permite convertir ETH a BSF usando una tasa fija o actualizable.
* El propietario mantiene la reserva desde donde se envían los BSF al usuario.

### Sistema de Roles

* El contrato RoleContract define:

| Rol               | Permisos principales                                                       |
| ----------------- | -------------------------------------------------------------------------- |
| **Propietario**   | Mint, retirar ETH, agregar/eliminar administradores, transferir propiedad. |
| **Administrador** | Actualizar tasa, agregar/eliminar operadores, modificar límites del banco. |
| **Operador**      | Ejecutar retiros de emergencia.                                            |

### Plataforma bancaria multiactivo

* El contrato KipuBankContract implementa:
* Depósitos y retiros para cualquier token ERC20 o ETH.
* Contabilidad interna por usuario y token.
* Límites globales de depósito y retiro.
* Bank cap en USD usando un oráculo Chainlink ETH/USD.
* Lógica de emergencia para operadores.

### Flujo general del sistema

* Usuarios depositan ETH o tokens.
* El sistema suma los valores al balance interno.
* Los retiros se permiten solo si cumplen límites e invariantes.
* Se monitorea que el total de depósitos no exceda el límite global ni el bank cap en USD.
* En emergencia, un operador puede retirar ETH hacia un destino.

## 2. Evaluar la madurez del protocolo

A continuación se analiza qué tan preparado está el protocolo para una auditoría formal o uso en producción.

## 2.1 Cobertura de pruebas

<div align="center">
  <img src="..\img\testcovertura.png" alt="Deploy TestNet">
</div>

Resumen global de la ejecución de pruebas

La suite completa ejecutó 21 pruebas, distribuidas en tres módulos principales:

| Suite                         | Pruebas ejecutadas | Pasadas | Fallidas |
| ----------------------------- | ------------------ | ------- | -------- |
| TestIntercambioSimple         | 1                  | 0       | **1**    |
| KipuBankTest                  | 6                  | **6**   | 0        |
| MockUniswapV2RouterSimpleTest | 14                 | **14**  | 0        |
| **Total**                     | **21**             | **20**  | **1**    |

El resultado general muestra que la mayor parte del protocolo funciona como se espera, excepto un caso específico en el módulo de intercambio cuya falla podría estar revelando:

* una inconsistencia lógica,
* un caso no contemplado, o
* condiciones de balance insuficientes por un error en setup o en la lógica de negocio.

### Detalles por suite

TestIntercambioSimple – 1 test, 1 fallido
testIntercambioClienteEspecifico(): FAILED — "Insufficient balance"

* Este caso falla por insuficiencia de balance, lo que puede deberse a:
* Un setup incorrecto del estado inicial
* El usuario no recibió tokens antes del intercambio
* Error en la lógica _transfer del ERC20 heredado
* El contrato no tenía liquidez suficiente en el test
* Un error en el cálculo previo al swap

Una prueba fallida en la capa de intercambio puede indicar un riesgo económico directo si el protocolo permite swaps sin liquidez o con saldos inconsistentes.

KipuBankTest – 6 pruebas pasadas

Todos los casos pasaron exitosamente.

Se probaron:

* Límites del Bank Cap (USD)
* Independencia entre instancias
* Interacciones con depósitos y retiros
* Independencia de tasas de cambio
* Tokens BSF independientes por instancia

La lógica bancaria/multi-token presenta buen aislamiento y correcta contabilidad interna.

MockUniswapV2RouterSimpleTest – 14 pruebas pasadas

Se probaron funciones básicas y avanzadas del router simulado:

* Fuzzing con 256 iteraciones
* Manejo de swaps múltiples
* Diferentes paths
* Casos límite: zero input, insuficiente liquidez, insuficiente balance
* Verificación de ratios y consistencia matemática

El módulo de swaps está bien testeado a nivel unitario, incluso con fuzzing, lo cual es una señal fuerte de madurez.

### Evaluación global de la madurez del protocolo basada en cobertura

| Área                                | Evaluación                                                                                  |
| ----------------------------------- | ------------------------------------------------------------------------------------------- |
| **Cobertura de funciones críticas** | Alta en Router y KipuBank; baja en Intercambios específicos                                 |
| **Casos límite probados**           | Bastante completos en el Router y Bank                                                      |
| **Uso de fuzz testing**             | Correcto (en router), agrega robustez                                                       |
| **Errores detectados**              | 1 falla importante relacionada con balances                                                 |
| **Advertencias del compilador**     | No afectan la seguridad pero requieren limpieza                                             |
| **Madurez general**                 | **Media — el protocolo está bien encaminado, pero aún no está listo para auditoría formal** |

* El protocolo muestra alta robustez en módulos fundamentales como el Router (14/14) y la banca multi-token (6/6).
* Existe un punto débil detectado en la prueba de intercambio específico, lo cual debe analizarse antes de avanzar a producción.
* Las advertencias del compilador deben corregirse para cumplir con estándares de código profesional.
* Es necesario agregar más pruebas unitarias y de integración para los módulos más críticos:
  Contabilidad interna, Manejo de límites, Escenarios de fallos del oráculo y Manipulación de tasas de cambio.
* La presencia de fuzz testing es un indicador positivo de madurez técnica.

## Métodos de Prueba

### Métodos que deberían aplicarse:

* Unit testing con Foundry / Hardhat
Validación de límites, Validación de balances, Roles.
* Fuzzing / Property-based testing
Especialmente para: Invariantes en depósitos y retiros. Oráculo fluctuante. Datos inesperados del usuario.
* Tests de integración multi-contrato
Simular oráculo, tokens, roles. 
* Análisis estático y simbólico
Con herramientas como: Slither, MythX, Certora Rules (ideal para invariantes)

## Documentación

El código tiene comentarios pero falta documentación formal de:

* Arquitectura del protocolo.
* Modelos de Amenazas.
* Invariantes del sistema.
* Limitaciones conocidas.
* Especificación económica.

2.4 Roles y poderes
Se identifican posibles excesos de poder:

Propietario:
* Puede mint ilimitadamente.
* Puede retirar todo el ETH.
* Es fuente única del suministro (pool BSF).

Riesgo: sistema altamente centralizado.

Administrador:
* Puede modificar completamente límites del banco.
* Puede agregar operadores con poderes críticos.

Operador:
* Puede retirar fondos del contrato a una dirección arbitraria sin límite.

Riesgo grave: falta de límites sobre retiros de emergencia.

2.5 Invariantes

No están documentados ni implementados explícitamente. Se especifican en la sección 4.

## 3. Vectores de ataque y modelo de amenazas

A continuación se identifican 4 escenarios de riesgo realista que un auditor reportaría.

* Ataque 1 – Falta de protección contra Reentrancy en depósitos/ emergencias
Superficie afectada: depositoETH, retiroETH, retiroToken, emergenciaRetiro

Un atacante deposita ETH vía contrato malicioso y en el fallback vuelve a llamar a depositoETH() múltiples veces, antes de que las estructuras del contrato cambien.

Riesgo:
* Inflado artificial de balances.
* Violación grave de invariantes.
* Retiros superiores al balance real.

* Ataque 2 – Riesgo por privilegios del Operador (Emergency Withdrawal Abuse)

El operador puede: emergenciaRetiro(destino, cantidad) sin límite.

Escenario:
* Un administrador comprometido agrega un operador malicioso.
* El operador retira todos los fondos del banco.
* Fin del sistema.

Riesgo: Pérdida total de fondos.

* Ataque 3 – Manipulación del oráculo (Oracle Manipulation)

Dependencias:
* Chainlink ETH/USD

Riesgo:
* Si el oráculo falla, se atranca el sistema:
* El bank cap USD puede bloquear depósitos.
* Depósitos de ETH pueden permitir inflar el sistema si el oráculo envía 0 o valores extremos.
* No hay temporizador ni validación de “stale price”.

Escenario
* Un atacante provoca error en el oráculo.
* El protocolo sigue aceptando depósitos a un precio incorrecto.
* Se supera el límite USD.
* Se colapsa la contabilidad interna.

* Ataque 4 – Lógica de conversión BSF mal planteada (Bank Run BSF)

La función: _transfer(propietario, msg.sender, cantidadBSF); requiere que el propietario tenga suficientes BSF. No hay una validacion.

Riesgo:
Propietario sin fondos tiene conversiones fallidas llevando a errores DoS. Un atacante puede provocar DoS haciendo drain de BSF.

## 4. Impacto de las violaciones de invariantes

* Violación Invariante 1
Impacto: pérdida total de reservas, insolvencia permanente.
* Violación Invariante 2
Impacto: extracción indebida de fondos → bancarrota del protocolo.
* Violación Invariante 3
Impacto: colapso económico por aceptar depósitos mayores al límite del banco.

## 5 Recomendaciones

Para cada invariante se proponen validaciones.

Implementar ReentrancyGuard
Usando OpenZeppelin:

```
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
```

Aplicar a:
* depósitos
* retiros
* emergenciaRetiro

Implementar Validaciones Internas (assert)

Ejemplo para Invariante 1:

```
assert(sumUserBalances(token) <= IERC20(token).balanceOf(address(this)));
```

Implementar oráculo seguro : 
* Verificación de que price > 0
* Verificar timestamp fresh (answeredInRound >= roundId)
* Agregar mecanismo de fallback si Chainlink falla.

Limitar emergenciaRetiro
* Solo retiro hasta máximo 5% de fondos.
* Debe emitirse timelock.
* Debe ser confirmada por dos roles (multisig o Propietario+Admin).

Pruebas de invariantes con Foundry (forge invariant)
Ejemplo:

```
forge test --via-ir --match-test invariant_
```

## 6. Conclusión y próximos pasos

KipuBankV3 presenta una arquitectura sólida conceptualmente, pero no está listo para un entorno de producción. Los puntos críticos son:

Riesgos técnicos

* Falta de protección contra reentrancy.
* Falta de límites para emergenciaRetiro.
* Dependencia excesiva del propietario para BSF mint/transfer.
* Dependencia del oráculo sin validación adicional.

Riesgos de gobernanza
* Roles altamente centralizados.
* No existe timelock para cambios críticos.

Riesgos de implementación
* Falta de pruebas y documentación formal.
* Falta de invariantes implementados directamente en el código.

Próximos pasos recomendados

* Implementar slither, foundry fuzzing, pruebas de invariantes.
* Añadir ReentrancyGuard.
* Reestructurar roles para limitar poderes peligrosos.
* Añadir validaciones al oráculo.
* Implementar auditoría externa con informes independiente.
* Generar documentación completa del protocolo.
* Añadir diagramas de arquitectura y flujo.
* Considerar migrar lógica de emergencia a Gnosis Safe o multisig.