// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/KipuBank.sol";

contract KipuBankTest is Test {
    KipuBankContract public kipuBank1;
    KipuBankContract public kipuBank2;
    
    address public owner1 = address(1);
    address public owner2 = address(2);
    address public user1 = address(3);
    address public user2 = address(4);
    
    // Mock price feed para testing
    address public mockPriceFeed;

    function setUp() public {
        // Deploy mock price feed
        mockPriceFeed = address(new MockPriceFeed());
        
        // Primera instancia
        vm.startPrank(owner1);
        kipuBank1 = new KipuBankContract(
            1000 ether,    // limiteTotalDeposito
            10 ether,      // limiteRetiro
            1_000_000 * 1e8, // limiteBancoUSD más alto para evitar reverts
            mockPriceFeed  // usar mock en lugar de address real
        );
        vm.stopPrank();

        // Segunda instancia
        vm.startPrank(owner2);
        kipuBank2 = new KipuBankContract(
            2000 ether,    // límite más alto
            5 ether,       // límite de retiro más bajo  
            2_000_000 * 1e8, // bank cap más alto
            mockPriceFeed
        );
        vm.stopPrank();
    }

    function testInteraccionIndependiente() public {
        // User1 interactúa con kipuBank1
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        kipuBank1.depositoETH{value: 0.1 ether}(); // Cantidad más pequeña

        // User2 interactúa con kipuBank2  
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        kipuBank2.depositoETH{value: 0.1 ether}(); // Cantidad más pequeña

        // Verificar que los balances son independientes
        assertEq(kipuBank1.obtenerBalance(user1, address(0)), 0.1 ether);
        assertEq(kipuBank2.obtenerBalance(user2, address(0)), 0.1 ether);
        
        // User1 no tiene balance en kipuBank2
        assertEq(kipuBank2.obtenerBalance(user1, address(0)), 0);
        
        // User2 no tiene balance en kipuBank1
        assertEq(kipuBank1.obtenerBalance(user2, address(0)), 0);
    }

    function testInteraccionIndependienteConRetiros() public {
        // Primero hacer depósitos
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        kipuBank1.depositoETH{value: 0.1 ether}();

        vm.deal(user2, 1 ether);
        vm.prank(user2);
        kipuBank2.depositoETH{value: 0.1 ether}();

        // Luego hacer retiros
        uint256 user1BalanceBefore = user1.balance;
        vm.prank(user1);
        kipuBank1.retiroETH(0.05 ether);

        uint256 user2BalanceBefore = user2.balance;
        vm.prank(user2);
        kipuBank2.retiroETH(0.05 ether);

        // Verificar balances actualizados
        assertEq(kipuBank1.obtenerBalance(user1, address(0)), 0.05 ether);
        assertEq(kipuBank2.obtenerBalance(user2, address(0)), 0.05 ether);
        
        // Verificar que recibieron el ETH
        assertEq(user1.balance, user1BalanceBefore + 0.05 ether);
        assertEq(user2.balance, user2BalanceBefore + 0.05 ether);
    }

    function testDosInstanciasIndependientes() public view {
        // Verificar que tienen diferentes owners
        assertTrue(kipuBank1.esPropietario(owner1));
        assertTrue(kipuBank2.esPropietario(owner2));
        assertFalse(kipuBank1.esPropietario(owner2));
        assertFalse(kipuBank2.esPropietario(owner1));

        // Verificar límites diferentes
        (uint256 limite1, uint256 retiro1) = kipuBank1.obtenerLimites();
        (uint256 limite2, uint256 retiro2) = kipuBank2.obtenerLimites();
        
        assertEq(limite1, 1000 ether);
        assertEq(limite2, 2000 ether);
        assertEq(retiro1, 10 ether);
        assertEq(retiro2, 5 ether);
    }

    function testTasasCambioIndependientes() public {
        // Cambiar tasa en kipuBank1
        vm.prank(owner1);
        kipuBank1.actualizarTasa(4000);

        // Cambiar tasa en kipuBank2
        vm.prank(owner2);
        kipuBank2.actualizarTasa(6000);

        // Verificar tasas diferentes
        assertEq(kipuBank1.tasaCambio(), 4000);
        assertEq(kipuBank2.tasaCambio(), 6000);
    }

    function testTokensBSFIndependientes() public {
        // Mint tokens en cada instancia
        vm.prank(owner1);
        kipuBank1.mint(user1, 1000 ether);

        vm.prank(owner2);
        kipuBank2.mint(user2, 2000 ether);

        // Verificar que son tokens diferentes
        assertEq(kipuBank1.balanceOf(user1), 1000 ether);
        assertEq(kipuBank2.balanceOf(user2), 2000 ether);
        assertEq(kipuBank1.balanceOf(user2), 0);
        assertEq(kipuBank2.balanceOf(user1), 0);
    }

    function testBankCapNoExcedido() public {
        // Test con cantidades pequeñas para evitar bank cap
        vm.deal(user1, 0.5 ether);
        vm.prank(user1);
        
        // Esto no debería revertir por bank cap
        kipuBank1.depositoETH{value: 0.01 ether}();
        
        assertEq(kipuBank1.obtenerBalance(user1, address(0)), 0.01 ether);
    }
}

// Mock Price Feed para testing controlado
contract MockPriceFeed {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, 2000 * 1e8, 0, block.timestamp, 0); // Precio fijo: $2000 por ETH
    }
    
    function decimals() external pure returns (uint8) {
        return 8;
    }
}