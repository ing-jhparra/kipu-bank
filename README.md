#  Contrato Ineligente para KipuBank
<p align="center">
   <br />
   <img src="img\contracts.png" width="55%">
   <br />
</p>
<div align="center">
  <img src="https://img.shields.io/badge/Estado-En%20desarrollo-yellow" alt="Proyecto en desarrollo">
</div>

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

* mapping(address => uint256) private balances; : Almacenar los balances de tokens/ETH por dirección

## Eventos (events)

* event Deposito(address indexed usuario, uint256 cantidad); : Registrar cuando un usuario realiza un depósito en un contrato.
* event Retiro(address indexed usuario, uint256 cantidad); : Registrar cuando un usuario realiza un retiro del contrato.

## Errores Personalizados (Custom Errors)


* error ExcedeLimiteDeposito(); : Validar que los depósitos no superen los límites establecidos.
* error CantidadCero(); : Prevenir operaciones con montos inválidos.
* error BalanceInsuficiente(); : Verificar que el usuario tenga fondos suficientes.
* error ExcedeLimiteRetiro(); : Controlar los límites de retiro.
* error TransferenciaFallida(); : Manejar fallas genéricas en transferencias.


## Constructor (Constructor)

* Inicializar el contrato con parámetros configurables que definen los límites operativos desde el momento del despliegue.

```
constructor(uint256 _limiteTotalDeposito, uint256 _limiteRetiro) {
        limiteTotalDeposito = _limiteTotalDeposito;
        limiteRetiro = _limiteRetiro;
}
```

## Modificador (Modifier)

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

## Función Private

function _incrementarCantidadDeposito() private {
        cantidadDeposito += 1;
}

function _incrementarCantidadRetiro() private {
        cantidadRetiro += 1;
}
## Función External View

## Autor
| [<img src="https://avatars.githubusercontent.com/u/123877201?v=4" width=115><br><sub>Jesus H. Parra B.</sub>](https://github.com/ing-jhparra)
| :---: |