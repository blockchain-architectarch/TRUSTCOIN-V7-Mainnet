// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../TrustcoinV7Mainnet.sol";
import "../EmissionBridgeV7Mainnet.sol";
import "../TaxBridgeV7Mainnet.sol";

contract TrustcoinV7Test is Test {
    TrustcoinV7Mainnet token;
    EmissionBridgeV7Mainnet emissionBridge;
    TaxBridgeV7Mainnet taxBridge;

    address owner        = address(this);
    address oracleAdmin  = address(0x7);
    address exemptAdmin  = address(0x9);
    address holderA      = address(0xA1);
    address holderB      = address(0xB2);
    address strangerAddr = address(0xC3);

    uint128 constant INITIAL_PRICE = 1e18;

    function setUp() public {
        vm.warp(1_700_000_000);

        token = new TrustcoinV7Mainnet(INITIAL_PRICE, oracleAdmin, exemptAdmin);
        emissionBridge = new EmissionBridgeV7Mainnet(address(token));
        taxBridge = new TaxBridgeV7Mainnet(address(token));

        token.setEmissionBridge(address(emissionBridge));
        token.setTaxBridge(address(taxBridge));
        token.setExempt(address(taxBridge), true);
    }

    function _releaseMonths(uint256 n) internal {
        for (uint256 i = 0; i < n; i++) {
            token.monthlyRelease();
            vm.warp(block.timestamp + 31 days);
        }
    }

    function _fundHolderFromBridge(address holder, uint256 amount) internal {
        if (emissionBridge.bridgeBalance() == 0) {
            token.monthlyRelease();
            vm.warp(block.timestamp + 31 days);
        }
        emissionBridge.sendToMarket(holder, amount);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MONTHLY RELEASE
    // ═══════════════════════════════════════════════════════════════════════

    function test_FirstMonthlyReleaseImmediate() public {
        token.monthlyRelease();
        assertEq(token.monthsReleased(), 1);
    }

    function test_FullEmissionCycle() public {
        _releaseMonths(50);
        assertEq(token.monthsReleased(), 50);
        assertEq(token.burnedTotal(), token.BURN_TARGET());
        assertTrue(token.burningStopped());
        assertEq(emissionBridge.bridgeBalance(), 100_000_000 * 10**18);

        vm.expectRevert("All months released");
        token.monthlyRelease();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // ORACLE ADMIN
    // ═══════════════════════════════════════════════════════════════════════

    function test_OracleAdminSurvivesRenounce() public {
        token.renounceOwnership();
        address newOracleAdmin = address(0x77);
        vm.prank(oracleAdmin);
        token.transferOracleAdmin(newOracleAdmin);
        assertEq(token.oracleAdmin(), newOracleAdmin);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EXEMPT ADMIN
    // ═══════════════════════════════════════════════════════════════════════

    function test_ExemptAdminCanAddPool() public {
        address pool = address(0x999);
        vm.prank(exemptAdmin);
        token.setExempt(pool, true);
        assertTrue(token.isExempt(pool));
    }

    function test_ExemptAdminSurvivesRenounce() public {
        token.renounceOwnership();
        address newExemptAdmin = address(0x99);
        vm.prank(exemptAdmin);
        token.transferExemptAdmin(newExemptAdmin);
        assertEq(token.exemptAdmin(), newExemptAdmin);

        address pool = address(0x998);
        vm.prank(newExemptAdmin);
        token.setExempt(pool, true);
        assertTrue(token.isExempt(pool));
    }

    function test_SetExemptRejectsUnauthorized() public {
        vm.prank(strangerAddr);
        vm.expectRevert("Not authorized");
        token.setExempt(strangerAddr, true);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // WALLET LIMIT (anti-whale)
    // ═══════════════════════════════════════════════════════════════════════

    function test_WalletLimitBlocksBeforeUnlock() public {
        vm.warp(1_780_000_000);
        if (emissionBridge.bridgeBalance() == 0) {
            token.monthlyRelease();
        }
        vm.expectRevert("Exceeds wallet limit");
        emissionBridge.sendToMarket(holderA, 10_001 * 10**18);
    }

    function test_WalletLimitLiftsAfterUnlock() public {
        vm.warp(token.WALLET_LIMIT_UNLOCK() + 1);
        token.monthlyRelease();
        uint256 amount = 500_000 * 10**18;
        emissionBridge.sendToMarket(holderA, amount);
        uint256 expectedAfterTax = amount - (amount * 50) / 10000;
        assertEq(token.balanceOf(holderA), expectedAfterTax);
    }

    function testFuzz_WalletLimitNeverBypassed(uint256 amount) public {
        vm.warp(1_780_000_000);
        amount = bound(amount, 10_001 * 10**18, 40_000_000 * 10**18);
        while (emissionBridge.bridgeBalance() < amount && token.monthsReleased() < token.TOTAL_MONTHS()) {
            token.monthlyRelease();
            vm.warp(block.timestamp + 31 days);
        }
        vm.warp(1_780_000_000);
        vm.expectRevert("Exceeds wallet limit");
        emissionBridge.sendToMarket(holderA, amount);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // TAX
    // ═══════════════════════════════════════════════════════════════════════

    function test_RegularTransferAppliesTax() public {
        _fundHolderFromBridge(holderA, 9_000 * 10**18);

        uint256 sendAmount = 5_000 * 10**18;
        vm.prank(holderA);
        token.transfer(holderB, sendAmount);

        uint256 expectedTax = (sendAmount * 50) / 10000;
        assertEq(token.balanceOf(holderB), sendAmount - expectedTax);
    }

    function test_InternalTransferSkipsTax() public {
        if (emissionBridge.bridgeBalance() == 0) {
            token.monthlyRelease();
        }
        uint256 amount = 1_000_000 * 10**18;
        uint256 balBefore = token.balanceOf(token.FUND_ADDRESS());
        emissionBridge.sendToMarket(token.FUND_ADDRESS(), amount);
        assertEq(token.balanceOf(token.FUND_ADDRESS()), balBefore + amount);
    }

    function testFuzz_TaxSplitAlwaysSumsToAmount(uint256 amount, uint128 newPrice) public {
        amount = bound(amount, 1_200 * 10**18, 9_000 * 10**18);
        newPrice = uint128(bound(uint256(newPrice), 1, INITIAL_PRICE));

        token.updatePrice(newPrice);

        _fundHolderFromBridge(holderA, amount);
        uint256 balA = token.balanceOf(holderA);

        uint256 fundBefore = token.balanceOf(token.FUND_ADDRESS());
        uint256 bridgeBefore = token.balanceOf(address(taxBridge));

        vm.prank(holderA);
        token.transfer(holderB, balA);

        uint256 fundAfter = token.balanceOf(token.FUND_ADDRESS());
        uint256 bridgeAfter = token.balanceOf(address(taxBridge));
        uint256 toFund = fundAfter - fundBefore;
        uint256 toBridge = bridgeAfter - bridgeBefore;

        assertEq(token.balanceOf(holderB) + toFund + toBridge, balA);
    }

    function testFuzz_PanicTaxBounded(uint128 basePrice, uint128 newPrice) public {
        basePrice = uint128(bound(uint256(basePrice), 1e18, 1e30));
        newPrice = uint128(bound(uint256(newPrice), 1, uint256(basePrice)));

        token.updatePrice(basePrice);
        token.resetBasePrice();
        token.updatePrice(newPrice);

        (, uint256 panicTaxPercent,,,) = token.releaseStatus();
        assertLe(panicTaxPercent, 5);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // TAX BRIDGE DISTRIBUTOR
    // ═══════════════════════════════════════════════════════════════════════

    function test_InitializeDistributorOnlyOnce() public {
        address vault1 = address(0x111);
        address vault2 = address(0x222);
        taxBridge.initializeDistributor(vault1);
        vm.expectRevert();
        taxBridge.initializeDistributor(vault2);
    }

    function test_InitializeDistributorNoTimelock() public {
        address vault = address(0x111);

        _fundHolderFromBridge(holderA, 9_000 * 10**18);
        vm.prank(holderA);
        token.transfer(holderB, 5_000 * 10**18);

        _releaseMonths(token.TOTAL_MONTHS() - token.monthsReleased());

        taxBridge.initializeDistributor(vault);
        assertEq(taxBridge.holdersDistributor(), vault);

        vm.warp(block.timestamp + 90 days);
        uint256 bridgeBal = taxBridge.bridgeBalance();
        assertGt(bridgeBal, 0, "TaxBridge should have accrued balance from tax");

        taxBridge.distribute();
        assertEq(taxBridge.bridgeBalance(), 0);
    }
}
