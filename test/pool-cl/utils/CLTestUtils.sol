// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {CLPoolManager} from "infinity-core/src/pool-cl/CLPoolManager.sol";
import {Vault} from "infinity-core/src/Vault.sol";
import {Currency} from "infinity-core/src/types/Currency.sol";
import {SortTokens} from "infinity-core/test/helpers/SortTokens.sol";
import {PoolKey} from "infinity-core/src/types/PoolKey.sol";
import {CLPositionManager} from "infinity-periphery/src/pool-cl/CLPositionManager.sol";
import {CLPositionDescriptorOffChain} from "infinity-periphery/src/pool-cl/CLPositionDescriptorOffChain.sol";
import {ICLPositionManager} from "infinity-periphery/src/pool-cl/interfaces/ICLPositionManager.sol";
import {ICLRouterBase} from "infinity-periphery/src/pool-cl/interfaces/ICLRouterBase.sol";
import {Planner, Plan} from "infinity-periphery/src/libraries/Planner.sol";
import {Actions} from "infinity-periphery/src/libraries/Actions.sol";
import {DeployPermit2} from "permit2/test/utils/DeployPermit2.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {UniversalRouter, RouterParameters} from "infinity-universal-router/src/UniversalRouter.sol";
import {Commands} from "infinity-universal-router/src/libraries/Commands.sol";
import {ActionConstants} from "infinity-periphery/src/libraries/ActionConstants.sol";
import {LiquidityAmounts} from "infinity-periphery/src/pool-cl/libraries/LiquidityAmounts.sol";
import {TickMath} from "infinity-core/src/pool-cl/libraries/TickMath.sol";
import {PoolId, PoolIdLibrary} from "infinity-core/src/types/PoolId.sol";
import {IWETH9} from "infinity-periphery/src/interfaces/external/IWETH9.sol";

contract CLTestUtils is DeployPermit2 {
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;

    Vault vault;
    CLPoolManager poolManager;
    CLPositionManager positionManager;
    IAllowanceTransfer permit2;
    UniversalRouter universalRouter;

    function deployContractsWithTokens() internal returns (Currency, Currency) {
        vault = new Vault();
        poolManager = new CLPoolManager(vault);
        vault.registerApp(address(poolManager));

        permit2 = IAllowanceTransfer(deployPermit2());
        CLPositionDescriptorOffChain positionDescriptor = new CLPositionDescriptorOffChain("https://pancakeswap.finance/infinity/pool-cl/positions/");
        positionManager = new CLPositionManager(vault, poolManager, permit2, 100_000, positionDescriptor, IWETH9(address(0)));

        RouterParameters memory params = RouterParameters({
            permit2: address(permit2),
            weth9: address(0),
            v2Factory: address(0),
            v3Factory: address(0),
            v3Deployer: address(0),
            v2InitCodeHash: bytes32(0),
            v3InitCodeHash: bytes32(0),
            stableFactory: address(0),
            stableInfo: address(0),
            infiVault: address(vault),
            infiClPoolManager: address(poolManager),
            infiBinPoolManager: address(0),
            v3NFTPositionManager: address(0),
            infiClPositionManager: address(positionManager),
            infiBinPositionManager: address(0)
        });
        universalRouter = new UniversalRouter(params);

        MockERC20 token0 = new MockERC20("token0", "T0", 18);
        MockERC20 token1 = new MockERC20("token1", "T1", 18);

        // approve permit2 contract to transfer our funds
        token0.approve(address(permit2), type(uint256).max);
        token1.approve(address(permit2), type(uint256).max);

        permit2.approve(address(token0), address(positionManager), type(uint160).max, type(uint48).max);
        permit2.approve(address(token1), address(positionManager), type(uint160).max, type(uint48).max);

        permit2.approve(address(token0), address(universalRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(token1), address(universalRouter), type(uint160).max, type(uint48).max);

        return SortTokens.sort(token0, token1);
    }

    function addLiquidity(
        PoolKey memory key,
        uint128 amount0Max,
        uint128 amount1Max,
        int24 tickLower,
        int24 tickUpper,
        address recipient
    ) internal returns (uint256 tokenId) {
        tokenId = positionManager.nextTokenId();

        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());
        uint256 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0Max,
            amount1Max
        );
        Plan memory planner = Planner.init().add(
            Actions.CL_MINT_POSITION,
            abi.encode(key, tickLower, tickUpper, liquidity, amount0Max, amount1Max, recipient, new bytes(0))
        );
        bytes memory data = planner.finalizeModifyLiquidityWithClose(key);
        positionManager.modifyLiquidities(data, block.timestamp);
    }

    function decreaseLiquidity(
        uint256 tokenId,
        PoolKey memory key,
        uint128 amount0,
        uint128 amount1,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());
        uint256 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0,
            amount1
        );
        // amount0Min and amount1Min is 0 as some hook takes a fee from here
        Plan memory planner =
            Planner.init().add(Actions.CL_DECREASE_LIQUIDITY, abi.encode(tokenId, liquidity, 0, 0, new bytes(0)));
        bytes memory data = planner.finalizeModifyLiquidityWithClose(key);
        positionManager.modifyLiquidities(data, block.timestamp);
    }

    function exactInputSingle(ICLRouterBase.CLSwapExactInputSingleParams memory params) internal {
        Plan memory plan = Planner.init().add(Actions.CL_SWAP_EXACT_IN_SINGLE, abi.encode(params));
        bytes memory data = params.zeroForOne
            ? plan.finalizeSwap(params.poolKey.currency0, params.poolKey.currency1, ActionConstants.MSG_SENDER)
            : plan.finalizeSwap(params.poolKey.currency1, params.poolKey.currency0, ActionConstants.MSG_SENDER);

        bytes memory commands = abi.encodePacked(bytes1(uint8(Commands.INFI_SWAP)));
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = data;

        universalRouter.execute(commands, inputs);
    }

    function exactOutputSingle(ICLRouterBase.CLSwapExactOutputSingleParams memory params) internal {
        Plan memory plan = Planner.init().add(Actions.CL_SWAP_EXACT_OUT_SINGLE, abi.encode(params));
        bytes memory data = params.zeroForOne
            ? plan.finalizeSwap(params.poolKey.currency0, params.poolKey.currency1, ActionConstants.MSG_SENDER)
            : plan.finalizeSwap(params.poolKey.currency1, params.poolKey.currency0, ActionConstants.MSG_SENDER);

        bytes memory commands = abi.encodePacked(bytes1(uint8(Commands.INFI_SWAP)));
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = data;

        universalRouter.execute(commands, inputs);
    }

    /// @notice permit2 approve from user addr to contractToApprove for currency
    function permit2Approve(address userAddr, Currency currency, address contractToApprove) internal {
        vm.startPrank(userAddr);

        // If contractToApprove uses permit2, we must execute 2 permits/approvals.
        // 1. First, the caller must approve permit2 on the token.
        IERC20(Currency.unwrap(currency)).approve(address(permit2), type(uint256).max);

        // 2. Then, the caller must approve contractToApprove as a spender of permit2.
        permit2.approve(Currency.unwrap(currency), address(contractToApprove), type(uint160).max, type(uint48).max);
        vm.stopPrank();
    }
}
