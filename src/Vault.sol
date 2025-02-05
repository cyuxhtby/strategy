// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20, IERC20, SafeERC20, ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strategy} from "./Strategy.sol";

contract Vault is ERC4626, Ownable {

    event StrategyMigrated(address newStrategy);
    event Deposited(uint256 amount);
    event Withdrawal(uint256 amount);

    using SafeERC20 for IERC20;

    error StrategyNotSet();
    error InvalidStrategy();

    Strategy public strategy;

    constructor(address _asset, string memory _name, string memory _symbol)
        Ownable(msg.sender)
        ERC20(_name, _symbol)
        ERC4626(IERC20(_asset))
    {}

    function setStrategy(address _strategy) external onlyOwner {
        require(address(_strategy) != address(strategy), InvalidStrategy());
        _migrateStrategy(_strategy);
    }

    function _migrateStrategy(address _strategy) internal {
        require(_strategy != address(0), InvalidStrategy());

        if (address(strategy) != address(0)) {
            uint256 oldBalance = strategy.totalAssets();
            if (oldBalance > 0) {
                strategy.withdraw(oldBalance);
            }
        }
        
        strategy = Strategy(_strategy);

        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));
        if (vaultBalance > 0) {
            IERC20(asset()).safeIncreaseAllowance(address(strategy), vaultBalance);
            IERC20(asset()).safeTransfer(address(strategy), vaultBalance);
            strategy.deploy(vaultBalance);
        }

        emit StrategyMigrated(address(strategy));
    }
    
    /// @notice Returns the total amount of value locked in the vault and strategy.
    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));
        if (address(strategy) == address(0)) return vaultBalance;

        return strategy.totalAssets() + vaultBalance;
    }

    /// @notice Deposits assets into the vault and supplies them to strategy.
    function _deposit(
        address /*caller*/, 
        address /*receiver*/, 
        uint256 assets, 
        uint256 /*shares*/
    ) internal override {
        IERC20(asset()).safeTransfer(address(strategy), assets);
        strategy.deploy(assets);

        emit Deposited(assets);
    }

    /// @notice Withdraws assets from the strategy and transfers them to the receiver.
    function _withdraw(
        address /* caller */,
        address receiver,
        address /* owner */,
        uint256 assets,
        uint256 /* shares */
    ) internal override {
        strategy.withdraw(assets);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdrawal(assets);
    }
}
