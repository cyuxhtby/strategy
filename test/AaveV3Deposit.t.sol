// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {AaveV3Deposit} from "../src/AaveV3Deposit.sol";
import {AavePoolMock} from "../src/mocks/AavePoolMock.sol";
import {Strategy} from "../src/Strategy.sol";
import {Vault} from "../src/Vault.sol";

contract AaveV3DepositTest is Test {
    AaveV3Deposit public strategy;
    ERC20Mock public asset;
    AavePoolMock public aavePool;
    Vault public vault;
    string public name = "Strategy Vault";
    string public symbol = "SV";

    uint256 public constant INITIAL_DEPOSIT = 1000e6; // 1000 USDC

    function setUp() public {
        asset = new ERC20Mock();
        aavePool = new AavePoolMock();
        aavePool.initReserve(address(asset));

        vault = new Vault(address(asset), name, symbol);
        strategy = new AaveV3Deposit(address(aavePool), address(vault), address(asset));
        vault.setStrategy(address(strategy));

        asset.mint(address(this), INITIAL_DEPOSIT);
    }

    function _depositIntoStrategy(uint256 amount) internal {
        asset.approve(address(vault), amount);
        vault.deposit(amount, address(this)); 
    }

    function test_deployment() public view {
        assertEq(address(strategy.pool()), address(aavePool));
        assertEq(strategy.asset(), address(asset));
        assertEq(strategy.name(), "Aave V3 E20M Strategy");
    }

    function test_deposit() public {
        _depositIntoStrategy(INITIAL_DEPOSIT);

        uint256 strategyBalance = strategy.totalAssets();
        assertEq(strategyBalance, INITIAL_DEPOSIT);
    }

    function test_withdrawal() public {
        _depositIntoStrategy(INITIAL_DEPOSIT);

        vm.warp(block.timestamp + 365 days);

        uint256 withdrawAmount = vault.maxWithdraw(address(this));
        vault.withdraw(withdrawAmount, address(this), address(this));

        assertEq(asset.balanceOf(address(this)), INITIAL_DEPOSIT);
        assertEq(strategy.totalAssets(), 0);
    }

    function test_totalAssets() public {
        _depositIntoStrategy(INITIAL_DEPOSIT);
        assertEq(strategy.totalAssets(), INITIAL_DEPOSIT);

        // Test mixed supply of aTokens in strat and USDC in vault
        uint256 half = INITIAL_DEPOSIT / 2;
        vm.prank(address(vault));
        strategy.withdraw(half);
        assertEq(strategy.totalAssets(), half);
        assertEq(vault.totalAssets(), INITIAL_DEPOSIT);
    }

    function test_onlyVaultCanDeploy() public {
        asset.mint(address(this), INITIAL_DEPOSIT);
        asset.transfer(address(strategy), INITIAL_DEPOSIT);
        
        vm.expectRevert(Strategy.Unauthorized.selector);
        strategy.deploy(INITIAL_DEPOSIT);
    }

    function test_onlyVaultCanWithdraw() public {
        _depositIntoStrategy(INITIAL_DEPOSIT);
        
        vm.expectRevert(Strategy.Unauthorized.selector);
        strategy.withdraw(INITIAL_DEPOSIT);
    }
} 