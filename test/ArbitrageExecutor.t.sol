// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ArbitrageExecutor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArbitrageExecutorTest is Test {
    ArbitrageExecutor public executor;
    
    // Тестовые адреса
    address public owner = address(0x1);
    address public uniswapRouter = address(0x2);
    address public aerodromeRouter = address(0x3);
    address public flashLoanPool = address(0x4);
    
    function setUp() public {
        // Деплоим контракт перед каждым тестом
        vm.prank(owner);
        executor = new ArbitrageExecutor(
            uniswapRouter,
            aerodromeRouter,
            flashLoanPool,
            1 ether // minProfit = 1 ETH
        );
    }
    
    // Тест 1: Проверка деплоя
    function test_Deployment() public view {
        assertEq(executor.owner(), owner, "Owner should be deployer");
        assertEq(executor.uniswapRouter(), uniswapRouter, "Uniswap router should be set");
        assertEq(executor.aerodromeRouter(), aerodromeRouter, "Aerodrome router should be set");
        assertEq(executor.flashLoanPool(), flashLoanPool, "Flash loan pool should be set");
        assertEq(executor.minProfit(), 1 ether, "Min profit should be 1 ETH");
    }
    
    // Тест 2: Изменение minProfit
    function test_SetMinProfit() public {
        uint256 newMinProfit = 2 ether;
        
        vm.prank(owner);
        executor.setMinProfit(newMinProfit);
        
        assertEq(executor.minProfit(), newMinProfit, "Min profit should be updated");
    }
    
    // Тест 3: Только владелец может менять minProfit
    function test_RevertIf_NotOwnerSetMinProfit() public {
    address attacker = address(0x999);
    
    vm.prank(attacker);
    vm.expectRevert(
        abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            attacker
        )
    );
    executor.setMinProfit(2 ether);
}
    
    // Тест 4: Изменение роутеров
    function test_SetRouters() public {
        address newUniswap = address(0x5);
        address newAerodrome = address(0x6);
        
        vm.prank(owner);
        executor.setRouters(newUniswap, newAerodrome);
        
        assertEq(executor.uniswapRouter(), newUniswap, "Uniswap router should be updated");
        assertEq(executor.aerodromeRouter(), newAerodrome, "Aerodrome router should be updated");
    }
    
    // Тест 5: Нельзя установить нулевой адрес роутера
    function test_RevertIf_ZeroAddressRouter() public {
        vm.prank(owner);
        vm.expectRevert("Invalid uniswap router");
        executor.setRouters(address(0), address(0x6));
        
        vm.prank(owner);
        vm.expectRevert("Invalid aerodrome router");
        executor.setRouters(address(0x5), address(0));
    }
    
    // Тест 6: Проверка баланса токенов
    function test_GetTokenBalance() public {
        // Создаём мок токен
        MockToken token = new MockToken();
        
        // Проверяем начальный баланс (должен быть 0)
        assertEq(executor.getTokenBalance(address(token)), 0, "Initial balance should be 0");
    }
}

// Мок токен для тестирования
contract MockToken {
    mapping(address => uint256) public balanceOf;
    
    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
    }
}
