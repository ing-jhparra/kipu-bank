// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import {KipuBankContract} from "../src/KipuBank.sol";
import {MockUniswapV2RouterSimple} from "../src/MockUniswapV2RouterSimple.sol";

contract TestIntercambioEspecifico is Test {

    address public clienteQuePaga = address(0x10);
    address receptor = 0x35C5b417169Ad9348d0eF91c2804e5781Cf04b18;

    KipuBankContract public banco1;
    KipuBankContract public banco2;
    MockUniswapV2RouterSimple public uniswap;
    
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    
    address public admin = address(0x1);
    address public clienteTokenB = address(0x2);
    
    // VARIABLES MODIFICABLES - VALORES AUMENTADOS
    uint256 public LIQUIDEZ_TOKEN_B = 50000 * 10**18;    // 50,000 TokenB
    uint256 public FONDOS_CLIENTE_A = 10000 * 10**18;    // 10,000 TokenA
    uint256 public LIQUIDEZ_TOKEN_A = 20000 * 10**18;    // 20,000 TokenA
    uint256 public MONTO_SWAP = 500 * 10**18;            // 500 TokenA

    function setUp() public {
        // Deploy tokens
        tokenA = new ERC20Mock("Token A", "TKA");
        tokenB = new ERC20Mock("Token B", "TKB");
        
        // Configurar fondos iniciales
        _configurarFondosIniciales();

        // Deploy bancos
        vm.startPrank(admin);
        banco1 = new KipuBankContract(100000 ether, 10000 ether, 100_000_000 * 1e8, address(1));
        banco2 = new KipuBankContract(100000 ether, 10000 ether, 100_000_000 * 1e8, address(1));
        vm.stopPrank();

        // Deploy Uniswap
        vm.startPrank(clienteTokenB);
        uniswap = new MockUniswapV2RouterSimple(address(tokenA), address(tokenB), 2e18);
        vm.stopPrank();

        _configurarLiquidez();
    }

    function _configurarFondosIniciales() internal {
        // Cliente TokenB recibe TokenB para liquidez
        tokenB.mint(clienteTokenB, 100000 * 10**18); // 100,000 TokenB
        
        // Cliente que paga recibe TokenA para swaps
        tokenA.mint(clienteQuePaga, 20000 * 10**18); // 20,000 TokenA
        
        // Fondos de respaldo para admin
        tokenA.mint(admin, 50000 * 10**18);
        tokenB.mint(admin, 50000 * 10**18);
    }

    function _configurarLiquidez() internal {
        // Proveer liquidez al Uniswap
        vm.startPrank(clienteTokenB);
        
        // Aprobar y transferir TokenB al Uniswap
        tokenB.approve(address(uniswap), LIQUIDEZ_TOKEN_B);
        tokenB.transfer(address(uniswap), LIQUIDEZ_TOKEN_B);
        
        vm.stopPrank();

        // Dar TokenA al Uniswap para swaps
        tokenA.mint(address(uniswap), LIQUIDEZ_TOKEN_A);
        
        console.log("=== LIQUIDEZ CONFIGURADA ===");
        console.log("Uniswap TokenA:", tokenA.balanceOf(address(uniswap)) / 1e18);
        console.log("Uniswap TokenB:", tokenB.balanceOf(address(uniswap)) / 1e18);
        console.log("Cliente Que Paga TokenA:", tokenA.balanceOf(clienteQuePaga) / 1e18);
        console.log("Cliente TokenB TokenB:", tokenB.balanceOf(clienteTokenB) / 1e18);
    }

    function testIntercambioClienteEspecifico() public {
        _verificarBalancesSuficientes();

        uint256 montoSwap = 100e18; //MONTO_SWAP;

        console.log("=== CONFIGURACION ACTUAL ===");
        console.log("Liquidez TokenB:", LIQUIDEZ_TOKEN_B / 1e18);
        console.log("Liquidez TokenA:", LIQUIDEZ_TOKEN_A / 1e18);
        console.log("Fondos Cliente A:", FONDOS_CLIENTE_A / 1e18);
        console.log("Monto Swap:", MONTO_SWAP / 1e18);
        console.log("Ratio: 1 TokenA = 2 TokenB");

        uint256 balanceAInicial = tokenA.balanceOf(clienteQuePaga);
        uint256 balanceBInicial = tokenB.balanceOf(receptor);

        console.log("=== BALANCES INICIALES ===");
        console.log("Paga:", clienteQuePaga);
        console.log("TokenA inicial:", balanceAInicial / 1e18);
        console.log("Cuenta que Recibe:", receptor);
        console.log("TokenB inicial:", balanceBInicial / 1e18);

        vm.startPrank(clienteQuePaga);

        // Aprobar tokens para Uniswap
        tokenA.approve(address(uniswap), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // Realizar swap enviando tokens al receptor
        uniswap.swapExactTokensForTokens(
            montoSwap,
            0,
            path,
            receptor,
            block.timestamp + 1 hours
        );

        vm.stopPrank();

        uint256 balanceAFinal = tokenA.balanceOf(clienteQuePaga);
        uint256 balanceBFinal = tokenB.balanceOf(receptor);

        uint256 tokenBRecibidos = balanceBFinal - balanceBInicial;

        console.log("=== RESULTADOS ===");
        console.log("TokenA final del pagador:", balanceAFinal / 1e18);
        console.log("TokenB final del receptor:", balanceBFinal / 1e18);
        console.log("TokenB recibidos:", tokenBRecibidos / 1e18);

        assertEq(tokenBRecibidos, montoSwap * 2, "El receptor no recibio la cantidad correcta");
        console.log("Intercambio exitoso!");
    }

    function _verificarBalancesSuficientes() internal view {
        // CORREGIDO: Verificar clienteQuePaga en lugar de clienteTokenA
        require(
            tokenA.balanceOf(clienteQuePaga) >= MONTO_SWAP,
            "Cliente que paga sin suficiente TokenA"
        );
        
        uint256 tokenBNecesarios = MONTO_SWAP * 2;
        require(
            tokenB.balanceOf(address(uniswap)) >= tokenBNecesarios,
            "Uniswap sin suficiente TokenB"
        );
        
        require(
            tokenA.balanceOf(address(uniswap)) >= MONTO_SWAP,
            "Uniswap sin suficiente TokenA para recibir"
        );

        // Verificar margen para operaciones adicionales
        require(
            tokenA.balanceOf(clienteQuePaga) >= MONTO_SWAP * 2,
            "Cliente que paga sin margen para operaciones adicionales"
        );
        
        require(
            tokenB.balanceOf(address(uniswap)) >= tokenBNecesarios * 5,
            "Uniswap sin liquidez para multiples operaciones"
        );
    }

    function configurarMontos(
        uint256 _liquidezB,
        uint256 _liquidezA, 
        uint256 _fondosA,
        uint256 _montoSwap
    ) public {
        LIQUIDEZ_TOKEN_B = _liquidezB;
        LIQUIDEZ_TOKEN_A = _liquidezA;
        FONDOS_CLIENTE_A = _fondosA;
        MONTO_SWAP = _montoSwap;
    }
}

// Mock ERC20
contract ERC20Mock {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return true;
    }
}