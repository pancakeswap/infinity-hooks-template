// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    HOOKS_BEFORE_INITIALIZE_OFFSET,
    HOOKS_AFTER_INITIALIZE_OFFSET,
    HOOKS_BEFORE_MINT_OFFSET,
    HOOKS_AFTER_MINT_OFFSET,
    HOOKS_BEFORE_BURN_OFFSET,
    HOOKS_AFTER_BURN_OFFSET,
    HOOKS_BEFORE_SWAP_OFFSET,
    HOOKS_AFTER_SWAP_OFFSET,
    HOOKS_BEFORE_DONATE_OFFSET,
    HOOKS_AFTER_DONATE_OFFSET,
    HOOKS_BEFORE_SWAP_RETURNS_DELTA_OFFSET,
    HOOKS_AFTER_SWAP_RETURNS_DELTA_OFFSET,
    HOOKS_AFTER_MINT_RETURNS_DELTA_OFFSET,
    HOOKS_AFTER_BURN_RETURNS_DELTA_OFFSET
} from "infinity-core/src/pool-bin/interfaces/IBinHooks.sol";
import {PoolKey} from "infinity-core/src/types/PoolKey.sol";
import {BalanceDelta} from "infinity-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "infinity-core/src/types/BeforeSwapDelta.sol";
import {IHooks} from "infinity-core/src/interfaces/IHooks.sol";
import {IVault} from "infinity-core/src/interfaces/IVault.sol";
import {IBinHooks} from "infinity-core/src/pool-bin/interfaces/IBinHooks.sol";
import {IBinPoolManager} from "infinity-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinPoolManager} from "infinity-core/src/pool-bin/BinPoolManager.sol";

/// @notice BaseHook abstract contract for Bin pool hooks to inherit
abstract contract BinBaseHook is IBinHooks {
    /// @notice The sender is not the pool manager
    error NotPoolManager();

    /// @notice The sender is not the vault
    error NotVault();

    /// @notice The sender is not this contract
    error NotSelf();

    /// @notice The pool key does not include this hook
    error InvalidPool();

    /// @notice The delegation of lockAcquired failed
    error LockFailure();

    /// @notice The method is not implemented
    error HookNotImplemented();

    struct Permissions {
        bool beforeInitialize;
        bool afterInitialize;
        bool beforeMint;
        bool afterMint;
        bool beforeBurn;
        bool afterBurn;
        bool beforeSwap;
        bool afterSwap;
        bool beforeDonate;
        bool afterDonate;
        bool beforeSwapReturnDelta;
        bool afterSwapReturnDelta;
        bool afterMintReturnDelta;
        bool afterBurnReturnDelta;
    }

    /// @notice The address of the pool manager
    IBinPoolManager public immutable poolManager;

    /// @notice The address of the vault
    IVault public immutable vault;

    constructor(IBinPoolManager _poolManager) {
        poolManager = _poolManager;
        vault = BinPoolManager(address(poolManager)).vault();
    }

    /// @dev Only the pool manager may call this function
    modifier poolManagerOnly() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    /// @dev Only the vault may call this function
    modifier vaultOnly() {
        if (msg.sender != address(vault)) revert NotVault();
        _;
    }

    /// @dev Only this address may call this function
    modifier selfOnly() {
        if (msg.sender != address(this)) revert NotSelf();
        _;
    }

    /// @dev Only pools with hooks set to this contract may call this function
    modifier onlyValidPools(IHooks hooks) {
        if (address(hooks) != address(this)) revert InvalidPool();
        _;
    }

    /// @dev Delegate calls to corresponding methods according to callback data
    function lockAcquired(bytes calldata data) external virtual vaultOnly returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).call(data);
        if (success) return returnData;
        if (returnData.length == 0) revert LockFailure();
        // if the call failed, bubble up the reason
        /// @solidity memory-safe-assembly
        assembly {
            revert(add(returnData, 32), mload(returnData))
        }
    }

    /// @inheritdoc IBinHooks
    function beforeInitialize(address sender, PoolKey calldata key, uint24 activeId)
        external
        virtual
        poolManagerOnly
        returns (bytes4)
    {
        return _beforeInitialize(sender, key, activeId);
    }

    function _beforeInitialize(address, PoolKey calldata, uint24) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function afterInitialize(address sender, PoolKey calldata key, uint24 activeId)
        external
        virtual
        poolManagerOnly
        returns (bytes4)
    {
        return _afterInitialize(sender, key, activeId);
    }

    function _afterInitialize(address, PoolKey calldata, uint24) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function beforeMint(
        address sender,
        PoolKey calldata key,
        IBinPoolManager.MintParams calldata params,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, uint24) {
        return _beforeMint(sender, key, params, hookData);
    }

    function _beforeMint(address, PoolKey calldata, IBinPoolManager.MintParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4, uint24)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function afterMint(
        address sender,
        PoolKey calldata key,
        IBinPoolManager.MintParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, BalanceDelta) {
        return _afterMint(sender, key, params, delta, hookData);
    }

    function _afterMint(address, PoolKey calldata, IBinPoolManager.MintParams calldata, BalanceDelta, bytes calldata)
        internal
        virtual
        returns (bytes4, BalanceDelta)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function beforeBurn(
        address sender,
        PoolKey calldata key,
        IBinPoolManager.BurnParams calldata params,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4) {
        return _beforeBurn(sender, key, params, hookData);
    }

    function _beforeBurn(address, PoolKey calldata, IBinPoolManager.BurnParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function afterBurn(
        address sender,
        PoolKey calldata key,
        IBinPoolManager.BurnParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, BalanceDelta) {
        return _afterBurn(sender, key, params, delta, hookData);
    }

    function _afterBurn(address, PoolKey calldata, IBinPoolManager.BurnParams calldata, BalanceDelta, bytes calldata)
        internal
        virtual
        returns (bytes4, BalanceDelta)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        bool swapForY,
        int128 amountSpecified,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, BeforeSwapDelta, uint24) {
        return _beforeSwap(sender, key, swapForY, amountSpecified, hookData);
    }

    function _beforeSwap(address, PoolKey calldata, bool, int128, bytes calldata)
        internal
        virtual
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function afterSwap(
        address sender,
        PoolKey calldata key,
        bool swapForY,
        int128 amountSpecified,
        BalanceDelta delta,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, int128) {
        return _afterSwap(sender, key, swapForY, amountSpecified, delta, hookData);
    }

    function _afterSwap(address, PoolKey calldata, bool, int128, BalanceDelta, bytes calldata)
        internal
        virtual
        returns (bytes4, int128)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4) {
        return _beforeDonate(sender, key, amount0, amount1, hookData);
    }

    function _beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc IBinHooks
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4) {
        return _afterDonate(sender, key, amount0, amount1, hookData);
    }

    function _afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    /// @dev Helper function to construct the hook registration map
    function _hooksRegistrationBitmapFrom(Permissions memory permissions) internal pure returns (uint16) {
        return uint16(
            (permissions.beforeInitialize ? 1 << HOOKS_BEFORE_INITIALIZE_OFFSET : 0)
                | (permissions.afterInitialize ? 1 << HOOKS_AFTER_INITIALIZE_OFFSET : 0)
                | (permissions.beforeMint ? 1 << HOOKS_BEFORE_MINT_OFFSET : 0)
                | (permissions.afterMint ? 1 << HOOKS_AFTER_MINT_OFFSET : 0)
                | (permissions.beforeBurn ? 1 << HOOKS_BEFORE_BURN_OFFSET : 0)
                | (permissions.afterBurn ? 1 << HOOKS_AFTER_BURN_OFFSET : 0)
                | (permissions.beforeSwap ? 1 << HOOKS_BEFORE_SWAP_OFFSET : 0)
                | (permissions.afterSwap ? 1 << HOOKS_AFTER_SWAP_OFFSET : 0)
                | (permissions.beforeDonate ? 1 << HOOKS_BEFORE_DONATE_OFFSET : 0)
                | (permissions.afterDonate ? 1 << HOOKS_AFTER_DONATE_OFFSET : 0)
                | (permissions.beforeSwapReturnDelta ? 1 << HOOKS_BEFORE_SWAP_RETURNS_DELTA_OFFSET : 0)
                | (permissions.afterSwapReturnDelta ? 1 << HOOKS_AFTER_SWAP_RETURNS_DELTA_OFFSET : 0)
                | (permissions.afterMintReturnDelta ? 1 << HOOKS_AFTER_MINT_RETURNS_DELTA_OFFSET : 0)
                | (permissions.afterBurnReturnDelta ? 1 << HOOKS_AFTER_BURN_RETURNS_DELTA_OFFSET : 0)
        );
    }
}
