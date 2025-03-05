// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "infinity-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "infinity-core/src/types/Currency.sol";
import {PoolKey} from "infinity-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "infinity-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {CLCounterHook} from "../../src/pool-cl/CLCounterHook.sol";
import {CLTestUtils} from "./utils/CLTestUtils.sol";
import {CLPoolParametersHelper} from "infinity-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "infinity-core/src/types/PoolId.sol";
import {ICLRouterBase} from "infinity-periphery/src/pool-cl/interfaces/ICLRouterBase.sol";

contract CLCounterHookTest is Test, CLTestUtils {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    CLCounterHook hook;
    Currency currency0;
    Currency currency1;
    PoolKey key;

    function setUp() public {
        (currency0, currency1) = deployContractsWithTokens();
        hook = new CLCounterHook(poolManager);

        // create the pool key
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: hook,
            poolManager: poolManager,
            fee: uint24(3000), // 0.3% fee
            // tickSpacing: 10
            parameters: bytes32(uint256(hook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        // initialize pool at 1:1 price point (assume stablecoin pair)
        poolManager.initialize(key, Constants.SQRT_RATIO_1_1);
    }

    function testLiquidityCallback() public {
        assertEq(hook.beforeAddLiquidityCount(key.toId()), 0);
        assertEq(hook.afterAddLiquidityCount(key.toId()), 0);

        MockERC20(Currency.unwrap(currency0)).mint(address(this), 1 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 1 ether);
        addLiquidity(key, 1 ether, 1 ether, -60, 60, address(this));

        assertEq(hook.beforeAddLiquidityCount(key.toId()), 1);
        assertEq(hook.afterAddLiquidityCount(key.toId()), 1);
    }

    function testSwapCallback() public {
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 1 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 1 ether);
        addLiquidity(key, 1 ether, 1 ether, -60, 60, address(this));

        assertEq(hook.beforeSwapCount(key.toId()), 0);
        assertEq(hook.afterSwapCount(key.toId()), 0);

        MockERC20(Currency.unwrap(currency0)).mint(address(this), 0.1 ether);
        exactInputSingle(
            ICLRouterBase.CLSwapExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                amountIn: 0.1 ether,
                amountOutMinimum: 0,
                hookData: new bytes(0)
            })
        );

        assertEq(hook.beforeSwapCount(key.toId()), 1);
        assertEq(hook.afterSwapCount(key.toId()), 1);
    }
}
