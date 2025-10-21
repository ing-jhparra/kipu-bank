#  Contrato Ineligente para KipuBank
<p align="center">
   <br />
   <img src="img\contracts.png" width="55%">
   <br />
</p>
<div align="center">
  <img src="https://img.shields.io/badge/Estado-En%20desarrollo-yellow" alt="Proyecto en desarrollo">
</div>

## Introducción

Un smart contract o "contrato inteligente" es un programa informático que se ejecuta de forma automática y autónoma en una blockchain (cadena de bloques).

A diferencia de un contrato tradicional, no depende de un intermediario (como un notario o un banco) para su cumplimiento. En su lugar, las reglas y cláusulas acordadas se escriben en código de programación. Cuando se cumplen las condiciones predefinidas, el contrato se ejecuta de inmediato, liberando los fondos o activos digitales involucrados de manera inmutable, transparente y segura.

Estos contratos son la base para aplicaciones descentralizadas (dApps), finanzas descentralizadas (DeFi) y muchos otros avances en el ecosistema Web3.

## Variables Immutable o Constant

* Establece el límite máximo total de depósitos que el contrato puede aceptar.
```
uint256 public immutable limiteTotalDeposito; 
```

* Define el límite máximo que se puede retirar en una sola transacción
```
uint256 public immutable limiteRetiro;
```

## Variables de almacenamiento (Storage)

* Llevar el registro del total acumulado de todos los depósitos realizados.
```
uint256 public totalDepositedo;
``` 

* Representar el monto de un depósito individual.
```
uint256 public cantidadDeposito;
```

* Representar el monto de un retiro individual.
```
uint256 public cantidadRetiro;
``` 

## Mapping

* Almacenar los balances de tokens/ETH por dirección
```
mapping(address => uint256) private balances;
```

## Eventos (events)

* Registrar cuando un usuario realiza un depósito en un contrato.
```
event Deposito(address indexed usuario, uint256 cantidad);
```

* Registrar cuando un usuario realiza un retiro del contrato.
```
event Retiro(address indexed usuario, uint256 cantidad); 
```

## Errores Personalizados (Custom Errors)

* Validar que los depósitos no superen los límites establecidos.
```
error ExcedeLimiteDeposito();
```

* Prevenir operaciones con montos inválidos. 
```
error CantidadCero();
``` 

* Verificar que el usuario tenga fondos suficientes.
```
error BalanceInsuficiente();
```

* Controlar los límites de retiro.
``` 
error ExcedeLimiteRetiro(); 
```

* Manejar fallas genéricas en transferencias.
```
error TransferenciaFallida();
``` 

## Constructor (Constructor)

* Inicializar el contrato con parámetros configurables que definen los límites operativos desde el momento del despliegue.

Para `_limiteTotalDeposito` (límite total de depósito):

Valores en wei: 1000000000000000000 (equivale a 1 ETH)
Valores en ether: Usando 1 ether, 10 ether, etc.

Ejemplo comunes
- 1000000000000000000  -> 1 ETH
- 5000000000000000000  -> 5 ETH
- 10000000000000000000 -> 10 ETH

Para `_limiteRetiro` (límite de retiro):

Valores en wei: Similar al límite de depósito

Ejemplos
- 100000000000000000   ->  0.1 ETH
- 500000000000000000   -> 0.5 ETH
- 1000000000000000000  -> 1 ETH


```
constructor(uint256 _limiteTotalDeposito, uint256 _limiteRetiro) {
        limiteTotalDeposito = _limiteTotalDeposito;
        limiteRetiro = _limiteRetiro;
}
```

Usando valores específicos en wei al hacer deploy el contrato.

<div align="center">
  <img src="img\constructor.png" alt="Valores específicos en wei">
</div>

Importante en Solidity se trabaja en wei (1 ETH = 10^18 wei)

## Modificador (Modifier)

* Si la cantidad es igual a 0, revierte la transacción con el error personalizado CantidadCero

```
modifier noCero(uint256 _cantidad) {
        if (_cantidad == 0) revert CantidadCero();
        _;
}
```

* Verifica que el depósito no haga que el total depositado en el banco exceda el límite máximo permitido    
```
modifier dentroLimiteDeposito(uint256 _cantidad) {
        if (totalDepositado + _cantidad > limiteTotalDeposito) {
            revert ExcedeLimiteDeposito();
        }
        _;
}
```

* Verifica que el monto del retiro individual no exceda el límite máximo permitido por transacción

```
modifier dentroLimiteRetiro(uint256 _cantidad) {
        if (_cantidad > limiteRetiro) {
            revert ExcedeLimiteRetiro();
        }
        _;
}
```

* Verifica que el usuario tenga suficientes fondos en su cuenta para realizar la operación solicitada.

```    
modifier balanceSuficiente(uint256 _cantidad) {
        if (balances[msg.sender] < _cantidad) {
            revert BalanceInsuficiente();
        }
        _;
}
```

* Verifica que la cantidad proporcionada sea mayor que cero, evitando operaciones con valores nulos o negativos.
```
modifier cantidadValida(uint256 _cantidad) {
        require(_cantidad > 0, "Cantidad Cero");
        _;
}
```

* Verifica que el usuario tenga saldo suficiente para realizar la operación solicitada.
```    
modifier fondosSuficientes(uint256 _cantidad) {
        require(balances[msg.sender] >= _cantidad, "Fondos Insuficientes");
        _;
}
```

## Función External Payable

```
function deposito() external payable {

        // msg.value es cantidad de ETH (en wei)
        bool isZeroAmount = msg.value == 0;
        bool exceedsCap = totalDepositedo + msg.value > limiteTotalDeposito;

        if (isZeroAmount) revert ZeroAmount();
        if (exceedsCap) revert DepositExceedsBankCap();

        // msg.sender es la dirección (billetera o contrato)
        balances[msg.sender] += msg.value;
        totalDepositedo += msg.value;
        _incrementarCantidadDeposito();

        emit Deposito(msg.sender, msg.value);
}
```

```
function recuperarDeposito(uint256 _cantidad) external cantidadValida(_cantidad) fondosSuficientes(_cantidad){
         
        balances[msg.sender] -= _cantidad;

        (bool resultado, ) = msg.sender.call{value: _cantidad}("");
        require (resultado, "Transferencia Fallida");
    }
```

```
function retiro(uint256 _cantidad) external  noCero(_cantidad) dentroLimiteRetiro(_cantidad) {
        
        require(balances[msg.sender] >= _cantidad, "Balance Insuficiente");

        balances[msg.sender] -= _cantidad;
        totalDepositado -= _cantidad;
        _incrementarCantidadRetiro();

        (bool success, ) = msg.sender.call{value: _cantidad}("");
        if (!success) revert TransferenciaFallida();

        emit Retiro(msg.sender, _cantidad);
}
```

## Función Private

```
function _incrementarCantidadDeposito() private {
        cantidadDeposito += 1;
}

function _incrementarCantidadRetiro() private {
        cantidadRetiro += 1;
}
```

## Función External View

```
function getBalance(address usuario) external view returns (uint256) {
        return balances[usuario];
}
```

## Instrucciones de despliegue

En remix luego de compilar el Smart Contract ir a Environment y seleccioanr Sepolia Testnet - MetaMask

<div align="center">
  <img src="img\deployTestnet.png" alt="Deploy TestNet">
</div>


## Autor

| [<img src="https://avatars.githubusercontent.com/u/123877201?v=4" width=115><br><sub>Jesus H. Parra B.</sub>](https://github.com/ing-jhparra)
| :---: |