// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    event ETHConvertidoABolivares (address usuario, uint256 ethAmount, uint256 bsfAmount);

    constructor() ERC20("Bolivares Fuerte", "BSF") {
        
        // Tasa inicial: 1 ETH = 3500 BSF
        tasaCambio = 3500;

        // 1 millón de tokens
        mint(msg.sender, 1000000 * 10**18);
    }

    function previsualizarConversion(uint256 _ethAmount) external view returns (uint256) {
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
        
        emit ETHConvertidoABolivares (msg.sender, msg.value, cantidadBSF);
    }

     // Función para actualizar la tasa de cambio (solo el dueño)
    function actualizarTasa(uint256 _nuevaTasa) external soloAdministrador {
        require(_nuevaTasa > 0, "La tasa debe ser mayor a cero");
        tasaCambio = _nuevaTasa;
        emit TasaCambioActualizada(_nuevaTasa);
    }

    // Función para calcular cuántos BsF da por ETH
    function calcularBolivares(uint256 _ethAmount) external view returns (uint256) {
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

// Contrato soporte multi-token y contabilidad interna
contract KipuBankContract is BolivaresFuertesContract {

    AggregatorV3Interface internal fuentePrecio;

    // Map: usuario => token => saldo
    mapping(address => mapping(address => uint256)) private balances;
    mapping(address => bool) public usuarios;

    // Variables y Constantes
    uint256 public totalDepositado;
    uint256 public cantidadDepositos;
    uint256 public cantidadRetiros;
    uint256 public immutable limiteTotalDeposito;
    uint256 public immutable limiteRetiro;
    uint256 public limiteBancoUSD;

    event Deposito(address indexed usuario, address indexed token, uint256 cantidad);
    event Retiro(address indexed usuario, address indexed token, uint256 cantidad);
    event UsuarioRegistrado(address indexed usuario);
    event RetiroDeEmergencia(address indexed operador, address destino, uint256 cantidad);

    error ExcedeLimiteDeposito();
    error CantidadCero();
    error BalanceInsuficiente();
    error ExcedeLimiteRetiro();
    error TransferenciaFallida();
    error FondosInsuficientesContrato();

    constructor(uint256 _limiteTotalDeposito, uint256 _limiteRetiro, uint256 _limiteBancoUSD, address _fuentePrecio) {
        limiteTotalDeposito = _limiteTotalDeposito;
        limiteRetiro = _limiteRetiro;

        // Inicializa el oráculo en el constructor (ETH/USD en Sepolia/Goerli/Ethereum Mainnet)
        limiteBancoUSD = _limiteBancoUSD;
        fuentePrecio = AggregatorV3Interface(_fuentePrecio);
    }

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

    modifier balanceSuficiente(address token, uint256 _cantidad) {
        if (balances[msg.sender][token] < _cantidad) revert BalanceInsuficiente();
        _;
    }

    function depositoToken(address token, uint256 cantidad) external noCero(cantidad) dentroLimiteDeposito(cantidad) {
        IERC20(token).transferFrom(msg.sender, address(this), cantidad);
        _depositar(msg.sender, token, cantidad);
    }

    function retiroETH(uint256 cantidad)
        external
        noCero(cantidad)
        balanceSuficiente(address(0), cantidad)
        dentroLimiteRetiro(cantidad)
    {
        balances[msg.sender][address(0)] -= cantidad;
        totalDepositado -= cantidad;
        cantidadRetiros++;

        (bool success, ) = msg.sender.call{value: cantidad}("");
        if (!success) revert TransferenciaFallida();

        emit Retiro(msg.sender, address(0), cantidad);
    }

    function retiroToken(address token, uint256 cantidad)
        external
        noCero(cantidad)
        balanceSuficiente(token, cantidad)
        dentroLimiteRetiro(cantidad)
    {
        balances[msg.sender][token] -= cantidad;
        totalDepositado -= cantidad;
        cantidadRetiros++;

        IERC20(token).transfer(msg.sender, cantidad);
        emit Retiro(msg.sender, token, cantidad);
    }

    // Función interna para registrar depósitos multi-token
    function _depositar(address usuario, address token, uint256 cantidad) private {
        balances[usuario][token] += cantidad;
        totalDepositado += cantidad;
        cantidadDepositos++;

        if (!usuarios[usuario]) {
            usuarios[usuario] = true;
            emit UsuarioRegistrado(usuario);
        }

        emit Deposito(usuario, token, cantidad);
    }

    // Emergencia solo para Ether
    function emergenciaRetiro(address payable destino, uint256 cantidad)
        external
        soloOperador
        noCero(cantidad)
    {
        if (address(this).balance < cantidad) revert FondosInsuficientesContrato();
        (bool success, ) = destino.call{value: cantidad}("");
        if (!success) revert TransferenciaFallida();

        emit RetiroDeEmergencia(msg.sender, destino, cantidad);
    }

    // CONSULTA DE BALANCES: usuario, token
    function obtenerBalance(address usuario, address token) external view returns (uint256) {
        return balances[usuario][token];
    }

    function obtenerBalanceContrato() external view returns (uint256) {
        return address(this).balance;
    }

    function obtenerLimites() 
        external 
        view 
        returns (uint256 limiteTotalDeposito_, uint256 limiteRetiro_) 
    {
        return (limiteTotalDeposito, limiteRetiro);
    }

    function esUsuarioRegistrado(address _usuario) external view returns (bool) {
        return usuarios[_usuario];
    }

    // Obtiene el último precio ETH/USD de Chainlink
    function obtenerPrecioETHUSD() public view returns (uint256) {
        (, int price, , , ) = fuentePrecio.latestRoundData();
        return uint256(price); // 8 decimales
    }

    // Convierte ETH a USD usando el oráculo
    function convertirETHaUSD(uint256 ethAmountWei) public view returns (uint256) {
        uint256 ethUSDPrice = obtenerPrecioETHUSD();
        // ethAmountWei: 1e18 = 1 ETH, price tiene 8 decimales
        return (ethAmountWei * ethUSDPrice) / 1e26; // Normaliza a 18 decimales
    }

    // Modificador para controlar el bank cap en USD
    modifier dentroBankCap(uint256 _ethAmountWei) {
        uint256 currentDepositedUSD = convertirETHaUSD(totalDepositado + _ethAmountWei);
        require(currentDepositedUSD <= limiteBancoUSD, "Excede el bank cap USD");
        _;
    }

    // Depósito con control de límite en USD
    function depositoETH() 
        external 
        payable 
        dentroBankCap(msg.value) 
        /* ...tus otros modificadores... */
    {
        _depositar(msg.sender, address(0), msg.value);
    }   

    // Permite cambiar el limiteBancoUSD (solo propietario o admin)
    function establecerLimiteBancoUSD(uint256 _newCap) external soloAdministrador {
        limiteBancoUSD = _newCap;
    }

    // Convierte cualquier cantidad a formato USDC (6 decimales)
function convertirDecimalesUSDC(address token, uint256 amount) public view returns (uint256) {
    uint8 tokenDecimals;

    if (token == address(0)) {
        // Ether (ETH) estándar: 18 decimales
        tokenDecimals = 18;
    } else {
        // Token ERC20
        tokenDecimals = ERC20(token).decimals();
    }

    // Ajusta hacia USDC (6 decimales)
    if (tokenDecimals == 6) {
        // Ya es formato USDC
        return amount;
    } else if (tokenDecimals > 6) {
        return amount / (10 ** (tokenDecimals - 6));
    } else {
        return amount * (10 ** (6 - tokenDecimals));
    }
}

}