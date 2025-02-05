// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/aave-v3-core/contracts/interfaces/IPool.sol";
import {AaveV3Deposit} from "../../src/AaveV3Deposit.sol";
import {Vault} from "../../src/Vault.sol";

contract AaveV3DepositIntegrationTest is Test {
    uint256 constant INITIAL_DEPOSIT = 1000e6;
    // Sepolia addresses
    address constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address constant USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    AaveV3Deposit public strategy;
    Vault public vault;
    IERC20 public usdc;
    IPool public aavePool;

    function setUp() public {
        vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"));
        usdc = IERC20(USDC);
        aavePool = IPool(AAVE_POOL);

        vault = new Vault(USDC, "Strategy Vault", "SV");
        strategy = new AaveV3Deposit(AAVE_POOL, address(vault), USDC);
        vault.setStrategy(address(strategy));
        
        deal(USDC, address(this), INITIAL_DEPOSIT);
    }

    function test_integration_yield() public {
        usdc.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, address(this));
        uint256 startBalance = strategy.totalAssets();

        vm.warp(block.timestamp + 7 days);
        vm.roll(block.number + 50400);
        
        uint256 endBalance = strategy.totalAssets();
        console.log("Start Balance: ", startBalance / 1e6);
        console.log("End Balance: ", endBalance / 1e6);
        console.log("USDC Yield accrued: ", (endBalance - startBalance) / 1e6);

        assertTrue(endBalance > startBalance);
    }
} 