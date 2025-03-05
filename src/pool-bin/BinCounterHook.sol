// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "infinity-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "infinity-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "infinity-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "infinity-core/src/types/PoolId.sol";
import {IBinPoolManager} from "infinity-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinBaseHook} from "./BinBaseHook.sol";

/// @notice BinCounterHook is a contract that counts the number of times a hook is called
/// @dev note the code is not production ready, it is only to share how a hook looks like
contract BinCounterHook is BinBaseHook {
    using PoolIdLibrary for PoolKey;

    mapping(PoolId => uint256 count) public beforeMintCount;
    mapping(PoolId => uint256 count) public afterMintCount;
    mapping(PoolId => uint256 count) public beforeSwapCount;
    mapping(PoolId => uint256 count) public afterSwapCount;

    constructor(IBinPoolManager _poolManager) BinBaseHook(_poolManager) {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeMint: true,
                afterMint: true,
                beforeBurn: false,
                afterBurn: false,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterMintReturnDelta: false,
                afterBurnReturnDelta: false
            })
        );
    }

    function _beforeMint(address, PoolKey calldata key, IBinPoolManager.MintParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, uint24)
    {
        beforeMintCount[key.toId()]++;
        return (this.beforeMint.selector, 0);
    }

    function _afterMint(
        address,
        PoolKey calldata key,
        IBinPoolManager.MintParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        afterMintCount[key.toId()]++;
        return (this.afterMint.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function _beforeSwap(address, PoolKey calldata key, bool, int128, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        beforeSwapCount[key.toId()]++;
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _afterSwap(address, PoolKey calldata key, bool, int128, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        afterSwapCount[key.toId()]++;
        return (this.afterSwap.selector, 0);
    }
}
