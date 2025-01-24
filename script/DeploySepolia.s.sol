// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Strategy} from "../src/Strategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeploySepolia is Script {
    address constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address constant USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        Strategy strategy = new Strategy(
            USDC,
            AAVE_POOL,
            "Aave USDC Yield Vault v0",
            "aUSDCv0"
        );

        console.log("Strategy deployed to:", address(strategy));
        console.log("aToken address:", address(strategy.aToken()));

        vm.stopBroadcast();
    }
}