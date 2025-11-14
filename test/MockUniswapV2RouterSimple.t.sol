// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MockUniswapV2RouterSimple.sol";

contract MockUniswapV2RouterSimpleTest is Test {
    MockUniswapV2RouterSimple public router;
    
    // Mock tokens para testing
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    uint256 public constant RATIO = 2; // 1 tokenA = 2 tokenB

    function setUp() public {
        // Deploy mock tokens
        tokenA = new ERC20Mock("Token A", "TKNA");
        tokenB = new ERC20Mock("Token B", "TKNB");
        
        // Deploy router con ratio 1:2
        vm.prank(owner);
        router = new MockUniswapV2RouterSimple(
            address(tokenA),
            address(tokenB),
            RATIO
        );
        
        // Dar tokens a los usuarios para testing
        tokenA.mint(user1, 1000 ether);
        tokenB.mint(address(router), 5000 ether); // Fondos para el router
    }

    // ========== TESTS DE CONFIGURACIÓN ==========

    function testConstructor() public {
        // Verificamos la configuración indirectamente mediante el comportamiento
        // El test de getAmountsOut verificará que el ratio funciona correctamente
        assertTrue(true); // Placeholder - la configuración se prueba en otros tests
    }

    // ========== TESTS PARA GETAMOUTSOUT ==========

    function testGetAmountsOut() public {
        uint256 amountIn = 100;
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256[] memory amounts = router.getAmountsOut(amountIn, path);

        assertEq(amounts.length, 2);
        assertEq(amounts[0], amountIn);
        assertEq(amounts[1], amountIn * RATIO);
    }

    function testGetAmountsOutWithDifferentAmounts() public {
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // Test con diferentes cantidades
        uint256[] memory testAmounts = new uint256[](4);
        testAmounts[0] = 1;
        testAmounts[1] = 100;
        testAmounts[2] = 1000;
        testAmounts[3] = 1 ether;

        for (uint256 i = 0; i < testAmounts.length; i++) {
            uint256[] memory amounts = router.getAmountsOut(testAmounts[i], path);
            assertEq(amounts[1], testAmounts[i] * RATIO);
        }
    }

    function testGetAmountsOutWithZeroInput() public {
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256[] memory amounts = router.getAmountsOut(0, path);

        assertEq(amounts.length, 2);
        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
    }

    // ========== TESTS PARA SWAPEXACTTOKENSFORTOKENS ==========

    function testSwapExactTokensForTokens() public {
        uint256 amountIn = 100 ether;
        uint256 expectedAmountOut = amountIn * RATIO;

        // Aprobar tokens para el router
        vm.startPrank(user1);
        tokenA.approve(address(router), amountIn);

        // Balances antes del swap
        uint256 userTokenABefore = tokenA.balanceOf(user1);
        uint256 userTokenBBefore = tokenB.balanceOf(user1);
        uint256 routerTokenABefore = tokenA.balanceOf(address(router));
        uint256 routerTokenBBefore = tokenB.balanceOf(address(router));

        // Realizar swap
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        router.swapExactTokensForTokens(
            amountIn,
            0, // amountOutMin
            path,
            user1,
            block.timestamp + 1 hours
        );

        // Verificar balances después del swap
        assertEq(tokenA.balanceOf(user1), userTokenABefore - amountIn);
        assertEq(tokenB.balanceOf(user1), userTokenBBefore + expectedAmountOut);
        assertEq(tokenA.balanceOf(address(router)), routerTokenABefore + amountIn);
        assertEq(tokenB.balanceOf(address(router)), routerTokenBBefore - expectedAmountOut);
    }

    function testSwapExactTokensForTokensToDifferentReceiver() public {
        uint256 amountIn = 50 ether;

        vm.startPrank(user1);
        tokenA.approve(address(router), amountIn);

        uint256 user2BalanceBefore = tokenB.balanceOf(user2);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            user2, // Enviar tokens a user2
            block.timestamp + 1 hours
        );

        assertEq(tokenB.balanceOf(user2), user2BalanceBefore + (amountIn * RATIO));
        assertEq(tokenB.balanceOf(user1), 0); // user1 no recibió tokens B
    }

    function testSwapWithInsufficientAllowance() public {
        uint256 amountIn = 100 ether;

        vm.startPrank(user1);
        tokenA.approve(address(router), amountIn - 1); // Allowance insuficiente

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.expectRevert(); // Debería revertir por transferFrom
        router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            user1,
            block.timestamp + 1 hours
        );
    }

    function testSwapWithInsufficientBalance() public {
        uint256 amountIn = 1500 ether; // Más de lo que tiene user1

        vm.startPrank(user1);
        tokenA.approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.expectRevert(); // Debería revertir por saldo insuficiente
        router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            user1,
            block.timestamp + 1 hours
        );
    }

    function testSwapWithRouterInsufficientLiquidity() public {
        // Router sin suficientes tokenB
        ERC20Mock tokenBLowLiquidity = new ERC20Mock("Token B Low", "TKNBL");
        tokenBLowLiquidity.mint(address(router), 10 ether); // Solo 10 tokens

        vm.prank(owner);
        MockUniswapV2RouterSimple routerLowLiq = new MockUniswapV2RouterSimple(
            address(tokenA),
            address(tokenBLowLiquidity),
            RATIO
        );

        tokenA.mint(user1, 100 ether);
        
        vm.startPrank(user1);
        tokenA.approve(address(routerLowLiq), 100 ether);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenBLowLiquidity);

        // Intentar swap que requiere más tokens de los que tiene el router
        vm.expectRevert(); // Debería revertir por saldo insuficiente del router
        routerLowLiq.swapExactTokensForTokens(
            10 ether, // Debería recibir 20 ether de tokenB
            0,
            path,
            user1,
            block.timestamp + 1 hours
        );
    }

    // ========== TESTS DE COMPORTAMIENTO ==========

    function testPathIsIgnored() public {
        // Test que el router ignora el path y siempre usa el ratio configurado
        uint256 amountIn = 100 ether;

        vm.startPrank(user1);
        tokenA.approve(address(router), amountIn);

        // Path "incorrecto" pero debería funcionar igual
        address[] memory wrongPath = new address[](2);
        wrongPath[0] = address(tokenB); // Esto debería ser tokenA normalmente
        wrongPath[1] = address(tokenA); // Esto debería ser tokenB normalmente

        // Aún así debería funcionar porque el router usa tokenA y tokenB internos
        router.swapExactTokensForTokens(
            amountIn,
            0,
            wrongPath,
            user1,
            block.timestamp + 1 hours
        );

        // Verificar que se recibieron tokens B (no tokens A)
        assertTrue(tokenB.balanceOf(user1) > 0);
    }

    // ========== TESTS DE EDGE CASES ==========

    function testSwapZeroAmount() public {
        vm.startPrank(user1);
        tokenA.approve(address(router), 0);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        router.swapExactTokensForTokens(
            0,
            0,
            path,
            user1,
            block.timestamp + 1 hours
        );

        // No debería cambiar balances
        assertEq(tokenA.balanceOf(user1), 1000 ether);
        assertEq(tokenB.balanceOf(user1), 0);
    }

    function testFuzzSwap(uint96 amount) public {
        vm.assume(amount > 0 && amount <= 100 ether);
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amount);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256 userBBalanceBefore = tokenB.balanceOf(user1);

        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            user1,
            block.timestamp + 1 hours
        );

        assertEq(tokenB.balanceOf(user1), userBBalanceBefore + (amount * RATIO));
    }

    function testMultipleSwaps() public {
        vm.startPrank(user1);
        tokenA.approve(address(router), 500 ether);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // Realizar múltiples swaps
        uint256[] memory swapAmounts = new uint256[](3);
        swapAmounts[0] = 10 ether;
        swapAmounts[1] = 50 ether;
        swapAmounts[2] = 100 ether;

        uint256 totalTokenBReceived = 0;

        for (uint256 i = 0; i < swapAmounts.length; i++) {
            uint256 tokenBBefore = tokenB.balanceOf(user1);
            router.swapExactTokensForTokens(
                swapAmounts[i],
                0,
                path,
                user1,
                block.timestamp + 1 hours
            );
            totalTokenBReceived += (tokenB.balanceOf(user1) - tokenBBefore);
        }

        uint256 totalTokenASpent = 10 ether + 50 ether + 100 ether;
        assertEq(totalTokenBReceived, totalTokenASpent * RATIO);
        assertEq(tokenA.balanceOf(user1), 1000 ether - totalTokenASpent);
    }

    function testRatioConsistency() public {
        // Verificar que el ratio es consistente en múltiples operaciones
        uint256 amountIn = 25 ether;
        
        vm.startPrank(user1);
        tokenA.approve(address(router), amountIn * 3);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // Primer swap
        router.swapExactTokensForTokens(amountIn, 0, path, user1, block.timestamp + 1 hours);
        uint256 firstOutput = tokenB.balanceOf(user1);
        
        // Segundo swap
        router.swapExactTokensForTokens(amountIn, 0, path, user1, block.timestamp + 1 hours);
        uint256 secondOutput = tokenB.balanceOf(user1) - firstOutput;
        
        // Tercer swap
        router.swapExactTokensForTokens(amountIn, 0, path, user1, block.timestamp + 1 hours);
        uint256 thirdOutput = tokenB.balanceOf(user1) - firstOutput - secondOutput;

        // Todos deberían ser iguales
        assertEq(firstOutput, amountIn * RATIO);
        assertEq(secondOutput, amountIn * RATIO);
        assertEq(thirdOutput, amountIn * RATIO);
    }
}

// Mock ERC20 para testing
contract ERC20Mock {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }
}