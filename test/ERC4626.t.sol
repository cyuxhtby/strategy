// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.18;

import {ERC4626Test} from "@openzeppelin/test/token/ERC20/extensions/ERC4626.t.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Vault} from "../src/Vault.sol";
import {Strategy} from "../src/Strategy.sol";
import {AaveV3Deposit} from "../src/AaveV3Deposit.sol";
import {AavePoolMock} from "../src/mocks/AavePoolMock.sol";

contract StrategyERC4626Test is ERC4626Test {
    Vault vault;
    Strategy strategy;
    AavePoolMock aavePoolMock;

    function setUp() public override {
        _underlying_ = address(new ERC20Mock());
        aavePoolMock = new AavePoolMock();

        aavePoolMock.initReserve(_underlying_);

        vault = new Vault(_underlying_, "Strategy Vault", "SV");
        _vault_ = address(vault);

        strategy = new AaveV3Deposit(address(aavePoolMock), address(vault), _underlying_);
        vm.prank(vault.owner());
        vault.setStrategy(address(strategy));

        ERC20Mock(_underlying_).mint(address(this), type(uint128).max);
        ERC20Mock(_underlying_).approve(address(_vault_), type(uint128).max);
    }
}
