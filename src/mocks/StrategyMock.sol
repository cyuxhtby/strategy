// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strategy} from "../Strategy.sol";

contract StrategyMock is Strategy {
    using SafeERC20 for IERC20;
    
    uint256 public totalAssets_;
    string private _name;

    constructor(address _vault) Strategy(_vault) {
        _name = "Strategy Mock";
    }

    function deploy(uint256 assets) external override onlyVault {
        IERC20(asset()).safeTransferFrom(address(vault), address(this), assets);
        totalAssets_ += assets;
    }

    function withdraw(uint256 assets) external override onlyVault {
        IERC20(asset()).safeTransfer(address(vault), assets);
        totalAssets_ -= assets;
    }

    function totalAssets() external view override returns (uint256) {
        return totalAssets_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }
}