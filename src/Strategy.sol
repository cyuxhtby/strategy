// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20, IERC20, SafeERC20, ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPool} from "@aave/aave-v3-core/contracts/interfaces/IPool.sol";
import {IAToken} from "@aave/aave-v3-core/contracts/interfaces/IAToken.sol";

contract Strategy is ERC4626 {
    error ZeroValue();

    using SafeERC20 for ERC20; // Handles weird erc20s

    IPool public immutable aaveV3Pool;
    IAToken public immutable aToken;

    constructor(address _asset, address _pool, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC4626(IERC20(_asset))
    {
        aaveV3Pool = IPool(_pool);
        aToken = IAToken(aaveV3Pool.getReserveData(address(_asset)).aTokenAddress);
    }

    /// @notice Returns the total amount of value locked in vault.
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + aToken.balanceOf(address(this));
    }

    /// @notice Deposits assets into the vault and supplies them to aave
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);
        IERC20(asset()).approve(address(aaveV3Pool), assets);
        aaveV3Pool.supply(asset(), assets, address(this), 0);
    }

    /// @notice Withdraws assets from aave and then the vault
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        aaveV3Pool.withdraw(asset(), Math.min(aToken.balanceOf(address(this)), assets), address(this));
        super._withdraw(caller, receiver, owner, assets, shares);
    }
}
