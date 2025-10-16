// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol";

contract KipuBankContract {
    
    mapping(address => uint256) private balances;

    // Variables de estado
    uint256 public totalDepositado;
    uint256 public cantidadDeposito;
    uint256 public cantidadRetiro;
    
    // Constantes
    uint256 public immutable limiteTotalDeposito; 
    uint256 public immutable limiteRetiro;

    // Eventos 
    event Deposito(address indexed usuario, uint256 cantidad);
    event Retiro(address indexed usuario, uint256 cantidad);

    error ExcedeLimiteDeposito(uint256 cantidadEnviada);
    error CantidadCero(uint256 cantidadEnviada);
    error BalanceInsuficiente();
    error ExcedeLimiteRetiro(uint256 cantidadEnviada);
    error TransferenciaFallida();

    // Constructor
    constructor(uint256 _limiteTotalDeposito, uint256 _limiteRetiro) {
        limiteTotalDeposito = _limiteTotalDeposito;
        limiteRetiro = _limiteRetiro;
    }

    // Modificadores
    modifier noCero(uint256 _cantidad) {
        if (_cantidad == 0) revert CantidadCero(_cantidad);
        _;
    }
    
    modifier dentroLimiteDeposito(uint256 _cantidad) {
        if (totalDepositado + _cantidad > limiteTotalDeposito) {
            revert ExcedeLimiteDeposito(_cantidad);
        }
        _;
    }

    modifier dentroLimiteRetiro(uint256 _cantidad) {
        if (_cantidad > limiteRetiro) {
            revert ExcedeLimiteRetiro(_cantidad);
        }
        _;
    }
    
    modifier balanceSuficiente(uint256 _cantidad) {
        if (balances[msg.sender] < _cantidad) {
            revert BalanceInsuficiente();
        }
        _;
    }

    // Funciones
    function deposito() external payable noCero(msg.value) dentroLimiteDeposito(msg.value) {

        // msg.sender es la dirección (billetera o contrato)
        balances[msg.sender] += msg.value;
        totalDepositado += msg.value;
        _incrementarCantidadDeposito();

        emit Deposito(msg.sender, msg.value);
    }

    function retiro(uint256 _cantidad) external noCero(_cantidad) dentroLimiteRetiro(_cantidad) balanceSuficiente(_cantidad) {
        
        balances[msg.sender] -= _cantidad;
        totalDepositado -= _cantidad;
        _incrementarCantidadRetiro();

        (bool success, ) = payable(msg.sender).call{value: _cantidad}("");
        if (!success) revert TransferenciaFallida();

        emit Retiro(msg.sender, _cantidad);
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