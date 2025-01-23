// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.18;

import {ERC4626Test} from "@openzeppelin/test/token/ERC20/extensions/ERC4626.t.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Strategy} from "../src/Strategy.sol";
import {AavePoolMock} from "../src/mocks/AavePoolMock.sol";

contract StrategyERC4626Test is ERC4626Test {
    Strategy strategy;
    AavePoolMock aavePoolMock;

    function setUp() public override {
        _underlying_ = address(new ERC20Mock());
        aavePoolMock = new AavePoolMock();

        aavePoolMock.initReserve(_underlying_);

        strategy = new Strategy(_underlying_, address(aavePoolMock), "Strategy Vault", "SV");

        _vault_ = address(strategy);
    }
}
