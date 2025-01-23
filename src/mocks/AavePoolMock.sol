// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "@aave/aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ATokenMock is ERC20 {
    constructor() ERC20("ATokenMock", "ATM") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

contract AavePoolMock {
    error InsufficientBalance();

    mapping(address => mapping(address => uint256)) public supplies;
    mapping(address => DataTypes.ReserveData) private _reserves;
    ATokenMock public immutable aToken;

    constructor() {
        aToken = new ATokenMock();
    }

    function initReserve(address asset) external {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        reserve.aTokenAddress = address(aToken);
        reserve.configuration.data = 1; // Enable borrowing/lending (active reserve)
        reserve.liquidityIndex = 1e27; // Initial liquidity index (1.0 in ray)
        reserve.currentLiquidityRate = 0; // 0% interest rate
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 /*referralCode*/ ) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        supplies[asset][onBehalfOf] += amount;
        ATokenMock(aToken).mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        if (supplies[asset][msg.sender] < amount) revert InsufficientBalance();
        supplies[asset][msg.sender] -= amount;
        IERC20(asset).transfer(to, amount);
        aToken.burn(msg.sender, amount);
        return amount;
    }

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory) {
        return _reserves[asset];
    }
}
