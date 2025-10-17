// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract KipuBankContract {
    
    mapping(address => uint256) private balances;

    // Variables
    uint256 public totalDepositado;
    uint256 public cantidadDeposito;
    uint256 public cantidadRetiro;
    
    // Constantes
    uint256 public immutable limiteTotalDeposito; 
    uint256 public immutable limiteRetiro;

    // Eventos 
    event Deposito(address indexed usuario, uint256 cantidad);
    event Retiro(address indexed usuario, uint256 cantidad);

    // Errores Personalizados
    error ExcedeLimiteDeposito();
    error CantidadCero();
    error BalanceInsuficiente();
    error ExcedeLimiteRetiro();
    error TransferenciaFallida();

    // Constructor
    constructor(uint256 _limiteTotalDeposito, uint256 _limiteRetiro) {
        limiteTotalDeposito = _limiteTotalDeposito;
        limiteRetiro = _limiteRetiro;
    }

    // Modificadores
    modifier noCero(uint256 _cantidad) {
        if (_cantidad == 0) revert CantidadCero();
        _;
    }
    
    modifier dentroLimiteDeposito(uint256 _cantidad) {
        if (totalDepositado + _cantidad > limiteTotalDeposito) {
            revert ExcedeLimiteDeposito();
        }
        _;
    }

    modifier dentroLimiteRetiro(uint256 _cantidad) {
        if (_cantidad > limiteRetiro) {
            revert ExcedeLimiteRetiro();
        }
        _;
    }
    
    modifier balanceSuficiente(uint256 _cantidad) {
        if (balances[msg.sender] < _cantidad) {
            revert BalanceInsuficiente();
        }
        _;
    }

    modifier cantidadValida(uint256 _cantidad) {
        require(_cantidad > 0, "CantidadCero");
        _;
    }
    
    modifier fondosSuficientes(uint256 _cantidad) {
        require(balances[msg.sender] >= _cantidad, "FondosInsuficientes");
        _;
    }

    // Funciones
    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    fallback() external payable {
        balances[msg.sender] += msg.value;
    }

    // Funciones
    function deposito() external payable noCero(msg.value) dentroLimiteDeposito(msg.value) {

        /* msg.sender representa la dirección (billetera o contrato) y 
           msg.value representa la cantidad de ETH (en wei) que se envía junto con una transacción */

        balances[msg.sender] += msg.value;
        totalDepositado += msg.value;
        _incrementarCantidadDeposito();

        emit Deposito(msg.sender, msg.value);
    }

    function recuperarDeposito(uint256 _cantidad) external cantidadValida(_cantidad) fondosSuficientes(_cantidad){
         
        balances[msg.sender] -= _cantidad;

        (bool resultado, ) = msg.sender.call{value: _cantidad}("");
        require (resultado, "Transferencia Fallida");
    }

    function retiro() external payable noCero(msg.value) dentroLimiteRetiro(msg.value) balanceSuficiente(msg.value) {
        
        balances[msg.sender] -= msg.value;
        totalDepositado -= msg.value;
        _incrementarCantidadRetiro();

        (bool success, ) = payable(msg.sender).call{value: msg.value}("");
        if (!success) revert TransferenciaFallida();

        emit Retiro(msg.sender, msg.value);
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