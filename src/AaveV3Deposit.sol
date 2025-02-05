// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPool} from "@aave/aave-v3-core/contracts/interfaces/IPool.sol";
import {IAToken} from "@aave/aave-v3-core/contracts/interfaces/IAToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strategy} from "./Strategy.sol";

contract AaveV3Deposit is Strategy {
    using SafeERC20 for IERC20;

    IPool public immutable pool;
    IAToken public immutable aToken;
    string private _name;

    constructor(address _pool, address _vault, address _asset) Strategy(_vault) {
        pool = IPool(_pool);
        aToken = IAToken(pool.getReserveData(_asset).aTokenAddress);
        _name = string(abi.encodePacked("Aave V3 ", IERC20Metadata(_asset).symbol(), " Strategy"));
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Deploys assets into designated Aave pool
    function deploy(uint256 assets) external override onlyVault {
        IERC20(asset()).safeIncreaseAllowance(address(pool), assets);
        pool.supply(asset(), assets, address(this), 0);
    }

    /// @notice Withdraws assets from Aave and sends them to the vault
    function withdraw(uint256 assets) external override onlyVault {
        pool.withdraw(
            asset(),
            Math.min(aToken.balanceOf(address(this)), assets),
            address(vault)
        );
    }

    function totalAssets() external view override returns (uint256) {
        return aToken.balanceOf(address(this)) + IERC20(asset()).balanceOf(address(this));
    }
}
