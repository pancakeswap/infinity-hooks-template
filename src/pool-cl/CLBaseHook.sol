// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {
    HOOKS_BEFORE_INITIALIZE_OFFSET,
    HOOKS_AFTER_INITIALIZE_OFFSET,
    HOOKS_BEFORE_ADD_LIQUIDITY_OFFSET,
    HOOKS_AFTER_ADD_LIQUIDITY_OFFSET,
    HOOKS_BEFORE_REMOVE_LIQUIDITY_OFFSET,
    HOOKS_AFTER_REMOVE_LIQUIDITY_OFFSET,
    HOOKS_BEFORE_SWAP_OFFSET,
    HOOKS_AFTER_SWAP_OFFSET,
    HOOKS_BEFORE_DONATE_OFFSET,
    HOOKS_AFTER_DONATE_OFFSET,
    HOOKS_BEFORE_SWAP_RETURNS_DELTA_OFFSET,
    HOOKS_AFTER_SWAP_RETURNS_DELTA_OFFSET,
    HOOKS_AFTER_ADD_LIQUIDIY_RETURNS_DELTA_OFFSET,
    HOOKS_AFTER_REMOVE_LIQUIDIY_RETURNS_DELTA_OFFSET
} from "infinity-core/src/pool-cl/interfaces/ICLHooks.sol";
import {PoolKey} from "infinity-core/src/types/PoolKey.sol";
import {BalanceDelta} from "infinity-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "infinity-core/src/types/BeforeSwapDelta.sol";
import {IHooks} from "infinity-core/src/interfaces/IHooks.sol";
import {IVault} from "infinity-core/src/interfaces/IVault.sol";
import {ICLHooks} from "infinity-core/src/pool-cl/interfaces/ICLHooks.sol";
import {ICLPoolManager} from "infinity-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLPoolManager} from "infinity-core/src/pool-cl/CLPoolManager.sol";

/// @notice BaseHook abstract contract for CL pool hooks to inherit
abstract contract CLBaseHook is ICLHooks {
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
        bool beforeAddLiquidity;
        bool afterAddLiquidity;
        bool beforeRemoveLiquidity;
        bool afterRemoveLiquidity;
        bool beforeSwap;
        bool afterSwap;
        bool beforeDonate;
        bool afterDonate;
        bool beforeSwapReturnDelta;
        bool afterSwapReturnDelta;
        bool afterAddLiquidityReturnDelta;
        bool afterRemoveLiquidityReturnDelta;
    }

    /// @notice The address of the pool manager
    ICLPoolManager public immutable poolManager;

    /// @notice The address of the vault
    IVault public immutable vault;

    constructor(ICLPoolManager _poolManager) {
        poolManager = _poolManager;
        vault = CLPoolManager(address(poolManager)).vault();
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

    /// @inheritdoc ICLHooks
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96)
        external
        virtual
        poolManagerOnly
        returns (bytes4)
    {
        return _beforeInitialize(sender, key, sqrtPriceX96);
    }

    function _beforeInitialize(address, PoolKey calldata, uint160) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc ICLHooks
    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        virtual
        poolManagerOnly
        returns (bytes4)
    {
        return _afterInitialize(sender, key, sqrtPriceX96, tick);
    }

    function _afterInitialize(address, PoolKey calldata, uint160, int24) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc ICLHooks
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4) {
        return _beforeAddLiquidity(sender, key, params, hookData);
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc ICLHooks
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, BalanceDelta) {
        return _afterAddLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    /// @inheritdoc ICLHooks
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4) {
        return _beforeRemoveLiquidity(sender, key, params, hookData);
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal virtual returns (bytes4) {
        revert HookNotImplemented();
    }

    /// @inheritdoc ICLHooks
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, BalanceDelta) {
        return _afterRemoveLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual poolManagerOnly returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    /// @inheritdoc ICLHooks
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, BeforeSwapDelta, uint24) {
        return _beforeSwap(sender, key, params, hookData);
    }

    function _beforeSwap(address, PoolKey calldata, ICLPoolManager.SwapParams calldata, bytes calldata)
        internal
        virtual
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc ICLHooks
    function afterSwap(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external virtual poolManagerOnly returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }

    function _afterSwap(address, PoolKey calldata, ICLPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        virtual
        returns (bytes4, int128)
    {
        revert HookNotImplemented();
    }

    /// @inheritdoc ICLHooks
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

    /// @inheritdoc ICLHooks
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
                | (permissions.beforeAddLiquidity ? 1 << HOOKS_BEFORE_ADD_LIQUIDITY_OFFSET : 0)
                | (permissions.afterAddLiquidity ? 1 << HOOKS_AFTER_ADD_LIQUIDITY_OFFSET : 0)
                | (permissions.beforeRemoveLiquidity ? 1 << HOOKS_BEFORE_REMOVE_LIQUIDITY_OFFSET : 0)
                | (permissions.afterRemoveLiquidity ? 1 << HOOKS_AFTER_REMOVE_LIQUIDITY_OFFSET : 0)
                | (permissions.beforeSwap ? 1 << HOOKS_BEFORE_SWAP_OFFSET : 0)
                | (permissions.afterSwap ? 1 << HOOKS_AFTER_SWAP_OFFSET : 0)
                | (permissions.beforeDonate ? 1 << HOOKS_BEFORE_DONATE_OFFSET : 0)
                | (permissions.afterDonate ? 1 << HOOKS_AFTER_DONATE_OFFSET : 0)
                | (permissions.beforeSwapReturnDelta ? 1 << HOOKS_BEFORE_SWAP_RETURNS_DELTA_OFFSET : 0)
                | (permissions.afterSwapReturnDelta ? 1 << HOOKS_AFTER_SWAP_RETURNS_DELTA_OFFSET : 0)
                | (permissions.afterAddLiquidityReturnDelta ? 1 << HOOKS_AFTER_ADD_LIQUIDIY_RETURNS_DELTA_OFFSET : 0)
                | (permissions.afterRemoveLiquidityReturnDelta ? 1 << HOOKS_AFTER_REMOVE_LIQUIDIY_RETURNS_DELTA_OFFSET : 0)
        );
    }
}
