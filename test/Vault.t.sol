// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {AaveV3Deposit} from "../src/AaveV3Deposit.sol";
import {AavePoolMock} from "../src/mocks/AavePoolMock.sol";
import {Vault} from "../src/Vault.sol";
import {Strategy} from "../src/Strategy.sol";
import {StrategyMock} from "../src/mocks/StrategyMock.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract VaultTest is Test {
    Vault public vault;
    ERC20Mock public asset;
    StrategyMock public strategy;
    AavePoolMock public aavePool;

    uint256 public constant INITIAL_DEPOSIT = 1000e6; // 1000 USDC

    function setUp() public {
        asset = new ERC20Mock();
        vault = new Vault(address(asset), "Strategy Vault", "SV");
        
        aavePool = new AavePoolMock();
        aavePool.initReserve(address(asset));
        strategy = new StrategyMock(address(vault));
        
        asset.mint(address(this), INITIAL_DEPOSIT);
    }

    function test_setStrategy() public {
        assertEq(address(vault.strategy()), address(0));
        
        vault.setStrategy(address(strategy));
        assertEq(address(vault.strategy()), address(strategy));
    }

    function test_setStrategy_onlyOwner() public {
        address unauthorized = address(1);
        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", unauthorized));
        vault.setStrategy(address(strategy));
    }

    function test_setStrategy_invalidStrategy() public {
        vm.expectRevert(Vault.InvalidStrategy.selector);
        vault.setStrategy(address(0));
    }

    function test_migrateStrategy() public {
        vault.setStrategy(address(strategy));
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, address(this));
        
        StrategyMock newStrategy = new StrategyMock(address(vault));
        
        vault.setStrategy(address(newStrategy));
        
        assertEq(strategy.totalAssets(), 0);
        assertEq(newStrategy.totalAssets(), INITIAL_DEPOSIT);
    }

    function test_deposit_noStrategy() public {
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, address(this));
        
        assertEq(asset.balanceOf(address(vault)), INITIAL_DEPOSIT);
    }

    function test_deposit_withStrategy() public {
        vault.setStrategy(address(strategy));
        
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, address(this));
        
        assertEq(strategy.totalAssets(), INITIAL_DEPOSIT);
        assertEq(asset.balanceOf(address(vault)), 0);
    }

    function test_withdraw_noStrategy() public {
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, address(this));
        
        vault.withdraw(INITIAL_DEPOSIT, address(this), address(this));
        assertEq(asset.balanceOf(address(this)), INITIAL_DEPOSIT);
    }

    function test_withdraw_withStrategy() public {
        vault.setStrategy(address(strategy));
        
        asset.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, address(this));
        
        vault.withdraw(INITIAL_DEPOSIT, address(this), address(this));
        assertEq(asset.balanceOf(address(this)), INITIAL_DEPOSIT);
    }
} 