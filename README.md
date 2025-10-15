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

```
uint256 public immutable limiteTotalDeposito; 
uint256 public immutable limiteRetiro;
```

## Variables de almacenamiento (Storage)

```
uint256 public totalDepositedo;
uint256 public cantidadDeposito;
uint256 public cantidadRetiro;
```

## Mapping

```
mapping(address => uint256) private balances;
```

## Eventos (events)

```
event Deposito(address indexed usuario, uint256 cantidad);
event Retiro(address indexed usuario, uint256 cantidad);
```

## Errores Personalizados (Custom Errors)

```
error DepositExceedsBankCap();
error ZeroAmount();
error InsufficientBalance();
error WithdrawalExceedsLimit();
error TransferFailed();
```

## Constructor (Constructor)

```
constructor(uint256 _limiteTotalDeposito, uint256 _limiteRetiro) {
        limiteTotalDeposito = _limiteTotalDeposito;
        limiteRetiro = _limiteRetiro;
}
```

## Modificador (Modifier)

```
function _incrementarCantidadDeposito() private {
        cantidadDeposito += 1;
}

function _incrementarCantidadRetiro() private {
        cantidadRetiro += 1;
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

## Función Private
## Función External View

## Autor
| [<img src="https://avatars.githubusercontent.com/u/123877201?v=4" width=115><br><sub>Jesus H. Parra B.</sub>](https://github.com/ing-jhparra)
| :---: |