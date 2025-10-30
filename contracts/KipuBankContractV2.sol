// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Contrato gestión de Roles
contract RoleContract {
    
    // Roles
    address public propietario;
    mapping(address => bool) public administradores;
    mapping(address => bool) public operadores;

    // Eventos
    event NuevoAdministrador(address indexed admin);
    event AdministradorEliminado(address indexed admin);
    event NuevoOperador(address indexed operador);
    event OperadorEliminado(address indexed operador);
    event PropietarioCambiado(address indexed nuevoPropietario);

    // Errores
    error SoloParaPropietario();
    error SoloParaAdministrador();
    error SoloParaOperador();
    error DireccionInvalida();

    constructor() {
        propietario = msg.sender;
        // El propietario es también Administrador por defecto
        administradores[msg.sender] = true;
    }

    // Modificadores
    modifier soloPropietario() {
        if (msg.sender != propietario) revert SoloParaPropietario();
        _;
    }

    modifier soloAdministrador() {
        if (!administradores[msg.sender]) revert SoloParaAdministrador();
        _;
    }

    modifier soloOperador() {
        if (!operadores[msg.sender]) revert SoloParaOperador();
        _;
    }

    modifier direccionValida(address _direccion) {
        if (_direccion == address(0)) revert DireccionInvalida();
        _;
    }

    // Funciones para gestión de roles
    function agregarAdministrador(address _admin) 
        external 
        soloPropietario 
        direccionValida(_admin) 
    {
        administradores[_admin] = true;
        emit NuevoAdministrador(_admin);
    }

    function eliminarAdministrador(address _admin) 
        external 
        soloPropietario 
        direccionValida(_admin) 
    {
        administradores[_admin] = false;
        emit AdministradorEliminado(_admin);
    }

    function agregarOperador(address _operador) 
        external 
        soloAdministrador 
        direccionValida(_operador) 
    {
        operadores[_operador] = true;
        emit NuevoOperador(_operador);
    }

    function eliminarOperador(address _operador) 
        external 
        soloAdministrador 
        direccionValida(_operador) 
    {
        operadores[_operador] = false;
        emit OperadorEliminado(_operador);
    }

    function transferirPropiedad(address nuevoPropietario) 
        external 
        soloPropietario 
        direccionValida(nuevoPropietario) 
    {
        propietario = nuevoPropietario;
        emit PropietarioCambiado(nuevoPropietario);
    }

    // Funciones de consulta
    function esPropietario(address _cuenta) external view returns (bool) {
        return _cuenta == propietario;
    }

    function esAdministrador(address _cuenta) external view returns (bool) {
        return administradores[_cuenta];
    }

    function esOperador(address _cuenta) external view returns (bool) {
        return operadores[_cuenta];
    }
}

// Contrato soporte de Multitoken

contract BolivaresFuertesContract is ERC20, RoleContract {

     // Tasa de cambio: 1 ETH = X BSF
    uint256 public tasaCambio;

    event TasaCambioActualizada(uint256 nuevaTasa);
    event ETHConvertidoABSF(address usuario, uint256 ethAmount, uint256 bsfAmount);

    constructor() ERC20("Bolivares Fuerte", "BSF") {
        
        // Tasa inicial: 1 ETH = 3500 BSF
        tasaCambio = 3500;

        // 1 millón de tokens
        mint(msg.sender, 1000000 * 10**18);
    }

    function previewConversion(uint256 _ethAmount) external view returns (uint256) {
        require(tasaCambio > 0, "Tasa de cambio no configurada");
        return (_ethAmount * tasaCambio) / 1e18;
    }

    function convertirETHaBSF() external payable {
        require(msg.value > 0, "Debes enviar ETH");
        require(tasaCambio > 0, "Tasa de cambio no configurada");
        
        // Calcular cuántos BsF corresponde
        uint256 cantidadBSF = (msg.value * tasaCambio) / 1e18;
        
        // Transferir los BsF al usuario
        _transfer(propietario, msg.sender, cantidadBSF);
        
        emit ETHConvertidoABSF(msg.sender, msg.value, cantidadBSF);
    }

     // Función para actualizar la tasa de cambio (solo el dueño)
    function actualizarTasa(uint256 _nuevaTasa) external soloAdministrador {
        require(_nuevaTasa > 0, "La tasa debe ser mayor a cero");
        tasaCambio = _nuevaTasa;
        emit TasaCambioActualizada(_nuevaTasa);
    }

    // Función para calcular cuántos BsF da por ETH
    function calcularBsF(uint256 _ethAmount) external view returns (uint256) {
        return (_ethAmount * tasaCambio) / 1e18;
    }

    // Ejemplo de función que solo el owner puede ejecutar
    function mint(address to, uint256 amount) public soloPropietario {
        _mint(to, amount);
    }

    // Función para retirar el ETH del contrato (solo dueño)
    function retirarETH() external soloPropietario {
        payable(propietario).transfer(address(this).balance);
    }

}

contract KipuBankContract is BolivaresFuertesContract {
    // Balances
    mapping(address => uint256) private balances;
    mapping(address => uint256) private balancesBsF;
    mapping(address => bool) public usuarios;

    // Variables y Constantes
    uint256 public totalDepositado;
    uint256 public cantidadDepositos;
    uint256 public cantidadRetiros;
    uint256 public immutable limiteTotalDeposito; 
    uint256 public immutable limiteRetiro;

    // Eventos
    event Deposito(address indexed usuario, uint256 cantidad);
    event Retiro(address indexed usuario, uint256 cantidad);
    event UsuarioRegistrado(address indexed usuario);
    event RetiroEmergencia(address indexed operador, address destino, uint256 cantidad);

    // Errores
    error ExcedeLimiteDeposito();
    error CantidadCero();
    error BalanceInsuficiente();
    error ExcedeLimiteRetiro();
    error TransferenciaFallida();
    error FondosInsuficientesContrato();

    // Constructor
    constructor(uint256 _limiteTotalDeposito, uint256 _limiteRetiro) {
        limiteTotalDeposito = _limiteTotalDeposito;
        limiteRetiro = _limiteRetiro;
    }

    // Modificadores adicionales
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

    // Funciones de depósito
    receive() external payable {
        _depositar(msg.sender, msg.value);
    }

    fallback() external payable {
        _depositar(msg.sender, msg.value);
    }
      
    function deposito() 
        external 
        payable 
        noCero(msg.value) 
        dentroLimiteDeposito(msg.value) 
    {
        _depositar(msg.sender, msg.value);
    }

    // Función de retiro normal
    function retiro(uint256 _cantidad)
        external
        noCero(_cantidad)
        balanceSuficiente(_cantidad)
        dentroLimiteRetiro(_cantidad)
    {
        balances[msg.sender] -= _cantidad;
        totalDepositado -= _cantidad;
        cantidadRetiros++;

        (bool success, ) = msg.sender.call{value: _cantidad}("");
        if (!success) revert TransferenciaFallida();

        emit Retiro(msg.sender, _cantidad);
    }

    // Función de depósito interno
    function _depositar(address _usuario, uint256 _cantidad) private {
        balances[_usuario] += _cantidad;
        totalDepositado += _cantidad;
        cantidadDepositos++;

        // Registro automático del usuario
        if (!usuarios[_usuario]) {
            usuarios[_usuario] = true;
            emit UsuarioRegistrado(_usuario);
        }

        emit Deposito(_usuario, _cantidad);
    }

    // Retiro de emergencia (solo operadores)
    function emergenciaRetiro(address payable destino, uint256 cantidad)
        external
        soloOperador
        noCero(cantidad)
    {
        if (address(this).balance < cantidad) revert FondosInsuficientesContrato();
        
        (bool success, ) = destino.call{value: cantidad}("");
        if (!success) revert TransferenciaFallida();

        emit RetiroEmergencia(msg.sender, destino, cantidad);
    }

    // Funciones de consulta
    function getBalance(address usuario) external view returns (uint256) {
        return balances[usuario];
    }

    function getBalanceContrato() external view returns (uint256) {
        return address(this).balance;
    }

    function getLimites() 
        external 
        view 
        returns (
            uint256 limiteTotalDeposito_,
            uint256 limiteRetiro_
        ) 
    {
        return (limiteTotalDeposito, limiteRetiro);
    }

    function esUsuarioRegistrado(address _usuario) external view returns (bool) {
        return usuarios[_usuario];
    }
}