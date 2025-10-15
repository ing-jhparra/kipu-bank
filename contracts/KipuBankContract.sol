// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract KipuBankContract {
    mapping(address => uint256) private balances;
    uint256 public totalDepositedo;
    uint256 public immutable limiteTotalDeposito; 
    uint256 public immutable limiteRetiro;
    uint256 public cantidadDeposito;
    uint256 public cantidadRetiro;

    // Eventos 
    event Deposito(address indexed usuario, uint256 cantidad);
    event Retiro(address indexed usuario, uint256 cantidad);

    error DepositExceedsBankCap();
    error ZeroAmount();
    error InsufficientBalance();
    error WithdrawalExceedsLimit();
    error TransferFailed();

    constructor(uint256 _limiteTotalDeposito, uint256 _limiteRetiro) {
        limiteTotalDeposito = _limiteTotalDeposito;
        limiteRetiro = _limiteRetiro;
    }


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

    function retiro(uint256 cantidad) external {
        
        bool isZeroAmount = cantidad == 0;
        bool insufficientBalance = cantidad > balances[msg.sender];
        bool exceedsLimit = cantidad > limiteRetiro;

        if (isZeroAmount) revert ZeroAmount();
        if (insufficientBalance) revert InsufficientBalance();
        if (exceedsLimit) revert WithdrawalExceedsLimit();

        balances[msg.sender] -= cantidad;
        totalDepositedo -= cantidad;
        _incrementarCantidadRetiro();

        (bool success, ) = payable(msg.sender).call{value: cantidad}("");
        if (!success) revert TransferFailed();

        emit Retiro(msg.sender, cantidad);
    }

    function getBalance(address usuario) external view returns (uint256) {
        return balances[usuario];
    }

    function _incrementarCantidadDeposito() private {
        cantidadDeposito += 1;
    }

    function _incrementarCantidadRetiro() private {
        cantidadRetiro += 1;
    }
}