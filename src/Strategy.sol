// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IVault} from "./interfaces/IVault.sol";

abstract contract Strategy {
    error Unauthorized();

    IVault public vault;

    constructor(address _vault) {
        vault = IVault(_vault);
    }

    modifier onlyVault() {
        if (msg.sender != address(vault)) revert Unauthorized();
        _;
    } 

    function deploy(uint256 assets) external virtual;

    function withdraw(uint256 assets) external virtual;

    function totalAssets() external view virtual returns (uint256);

    function name() public view virtual returns (string memory);
    
    function asset() public view returns (address) {
        return vault.asset();
    }
}
