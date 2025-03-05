// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "infinity-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "infinity-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "infinity-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "infinity-core/src/types/PoolId.sol";
import {ICLPoolManager} from "infinity-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLBaseHook} from "./CLBaseHook.sol";

/// @notice CLCounterHook is a contract that counts the number of times a hook is called
/// @dev note the code is not production ready, it is only to share how a hook looks like
contract CLCounterHook is CLBaseHook {
    using PoolIdLibrary for PoolKey;

    mapping(PoolId => uint256 count) public beforeAddLiquidityCount;
    mapping(PoolId => uint256 count) public afterAddLiquidityCount;
    mapping(PoolId => uint256 count) public beforeSwapCount;
    mapping(PoolId => uint256 count) public afterSwapCount;

    constructor(ICLPoolManager _poolManager) CLBaseHook(_poolManager) {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            })
        );
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata key,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        beforeAddLiquidityCount[key.toId()]++;
        return this.beforeAddLiquidity.selector;
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata key,
        ICLPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        afterAddLiquidityCount[key.toId()]++;
        return (this.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function _beforeSwap(address, PoolKey calldata key, ICLPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        beforeSwapCount[key.toId()]++;
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _afterSwap(address, PoolKey calldata key, ICLPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        afterSwapCount[key.toId()]++;
        return (this.afterSwap.selector, 0);
    }
}
