// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseStrategy, ERC20} from "@yearn/tokenized-strategy/BaseStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPool} from "@aave/aave-v3-core/contracts/interfaces/IPool.sol";
import {IAToken} from "@aave/aave-v3-core/contracts/interfaces/IAToken.sol";


contract Strategy is BaseStrategy {
    error ZeroValue();

    using SafeERC20 for ERC20; // Handles weird erc20s

    IPool public immutable aaveV3Pool;
    IAToken public immutable aToken;


    // The only default global variables from the BaseStrategy that can be accessed from storage is `asset` and `TokenizedStrategy`.

    constructor(address _asset, string memory _name, address _pool) BaseStrategy(_asset, _name) {
        aaveV3Pool = IPool(_pool);
        aToken = IAToken(aaveV3Pool.getReserveData(address(_asset)).aTokenAddress);
    }

    /// @notice Deploy funds into the Aave V3 lending pool
    /// @dev Called via BaseStrategy.deployFunds() to deploy available funds in the strategy.
    ///      This happens:
    ///      - After new deposits (when users call Strategy.deposit() or Strategy.mint() via fallbacks)
    ///      - During tend() calls if implemented
    ///      - During report() profit harvesting
    /// @param _amount The amount of asset to deposit into Aave
    function _deployFunds(uint256 _amount) internal override {
        require(_amount > 0, ZeroValue());
        // supply(asset, amount, onBehalfOf, referralCode)
        aaveV3Pool.supply(address(asset), _amount, address(this), 0);
    }

    /// @notice Withdraw funds from the Aave V3 lending pool
    /// @dev If _amount is greater than aToken balance, withdraws full available balance 
    /// @param _amount The amount requested to withdraw
    function _freeFunds(uint256 _amount) internal override {
        // withdraw(asset, amount, to)
        aaveV3Pool.withdraw(
            address(asset), 
            Math.min(aToken.balanceOf(address(this)), _amount), 
            address(this)
        );
    }

    /// @notice Returns the total assets the strategy has including both deployed and undeployed funds
    /// @dev aTokens automatically accrue interest so no manual harvesting is needed
    /// @return _totalAssets Total value of assets denominated in asset token
    function _harvestAndReport() internal view override returns (uint256 _totalAssets) {
           return asset.balanceOf(address(this)) + aToken.balanceOf(address(this));
    }


    /// @notice Returns how much can be withdrawn immediatly from the strategy
    /// @dev Aave imposes no withdraw restrictions so we can assume full amount
    /// @return . Max amount of assets available for withdrawal
    function availableWithdrawLimit() public view returns (uint256) {
        return asset.balanceOf(address(this)) + aToken.balanceOf(address(this));
    }

}