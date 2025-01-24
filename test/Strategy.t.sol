// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Strategy} from "../src/Strategy.sol";
import {AavePoolMock} from "../src/mocks/AavePoolMock.sol";

contract StrategyTest is Test {
    Strategy public strategy;
    ERC20Mock public asset;
    AavePoolMock public aavePool;
    string public name = "Strategy Vault";
    string public symbol = "SV";

    uint256 public constant INITIAL_DEPOSIT = 1000e6; // 1000 USDC

    function setUp() public {
        asset = new ERC20Mock();
        aavePool = new AavePoolMock();

        aavePool.initReserve(address(asset));

        strategy = new Strategy(address(asset), address(aavePool), name, symbol);

        asset.mint(address(this), INITIAL_DEPOSIT);
    }

    function _depositIntoStrategy(uint256 amount) internal {
        asset.approve(address(strategy), amount);
        strategy.deposit(amount, address(this));
    }

    function test_deployment() public view {
        assertEq(address(strategy.aaveV3Pool()), address(aavePool));
        assertEq(strategy.asset(), address(asset));
        assertEq(strategy.name(), name);
        assertEq(strategy.symbol(), symbol);
    }

    function test_deposit() public {
        _depositIntoStrategy(INITIAL_DEPOSIT);

        uint256 strategyBalance = strategy.totalAssets();
        assertEq(strategyBalance, INITIAL_DEPOSIT);
    }

    function test_withdrawal() public {
        _depositIntoStrategy(INITIAL_DEPOSIT);

        vm.warp(block.timestamp + 365 days);

        uint256 withdrawAmount = strategy.maxWithdraw(address(this));
        strategy.withdraw(withdrawAmount, address(this), address(this));

        assertTrue(asset.balanceOf(address(this)) > 0);
    }

    function test_totalAssets() public {
        _depositIntoStrategy(INITIAL_DEPOSIT);
        assertEq(strategy.totalAssets(), INITIAL_DEPOSIT);

        // Test mixed supply of aTokens and USDC
        uint256 half = INITIAL_DEPOSIT / 2;
        vm.prank(address(strategy));
        aavePool.withdraw(address(asset), half, address(strategy));
        assertEq(strategy.totalAssets(), INITIAL_DEPOSIT);
    }
}
