pragma solidity 0.8.18;

import "./TestContracts/DevTestSetup.sol";

contract BasicOps is DevTestSetup {

    function testOpenTrove() public {
        priceFeed.setPrice(2000e18);
        uint256 trovesCount = troveManager.getTroveOwnersCount();
        assertEq(trovesCount, 0);

        vm.startPrank(A);
        borrowerOperations.openTrove{value: 2 ether}(1e18, 2000e18, ZERO_ADDRESS, ZERO_ADDRESS);

        trovesCount = troveManager.getTroveOwnersCount();
        assertEq(trovesCount, 1);
    }

     function testCloseTrove() public {
        priceFeed.setPrice(2000e18);
        vm.startPrank(A);
        borrowerOperations.openTrove{value: 2 ether}(1e18, 2000e18, ZERO_ADDRESS, ZERO_ADDRESS);
        vm.stopPrank();

        vm.startPrank(B);
        borrowerOperations.openTrove{value: 2 ether}(1e18, 2000e18, ZERO_ADDRESS, ZERO_ADDRESS);

        uint256 trovesCount = troveManager.getTroveOwnersCount();
        assertEq(trovesCount, 2);
       
        vm.startPrank(B);
        borrowerOperations.closeTrove();
        vm.stopPrank();
    
        // Check Troves count reduced by 1
        trovesCount = troveManager.getTroveOwnersCount();
        assertEq(trovesCount, 1);
    }

    // adjustTrove

    function testAdjustTrove() public {
        priceFeed.setPrice(2000e18);
        vm.startPrank(A);
        borrowerOperations.openTrove{value: 2 ether}(1e18, 2000e18, ZERO_ADDRESS, ZERO_ADDRESS);

        // Check Trove coll and debt
        uint256 debt_1 = troveManager.getTroveDebt(A);
        assertGt(debt_1, 0);
        uint256 coll_1 = troveManager.getTroveColl(A);
        assertGt(coll_1, 0);
 
        // Adjust trove
        borrowerOperations.adjustTrove{value: 1 ether}(1e18, 0,  500e18,  true,  ZERO_ADDRESS,  ZERO_ADDRESS);

        // Check coll and debt altered
        uint256 debt_2 = troveManager.getTroveDebt(A);
        assertGt(debt_2, debt_1);
        uint256 coll_2 = troveManager.getTroveColl(A);
        assertGt(coll_2, coll_1);
    }

    function testRedeem() public {
        priceFeed.setPrice(2000e18);
        vm.startPrank(A);
        borrowerOperations.openTrove{value: 5 ether}(1e18, 5_000e18, ZERO_ADDRESS, ZERO_ADDRESS);
        vm.stopPrank();

        uint256 debt_1 = troveManager.getTroveDebt(A);
        assertGt(debt_1, 0);
        uint256 coll_1 = troveManager.getTroveColl(A);
        assertGt(coll_1, 0);

        vm.startPrank(B);
        borrowerOperations.openTrove{value: 5 ether}(1e18, 4_000e18, ZERO_ADDRESS, ZERO_ADDRESS);
        
        vm.warp(block.timestamp + troveManager.BOOTSTRAP_PERIOD() + 1);

        uint256 redemptionAmount = 1000e18;  // 1k BOLD
        uint256 expectedCollReduction = redemptionAmount * 1e18 / priceFeed.fetchPrice();

        uint256 expectedColl_A = troveManager.getTroveColl(A) - expectedCollReduction;
        uint256 expectedDebt_A = troveManager.getTroveDebt(A) - redemptionAmount;
        uint256 expectedNICR = LiquityMath._computeNominalCR(expectedColl_A,expectedDebt_A); 
      
        // B redeems 1k BOLD
        troveManager.redeemCollateral(
            redemptionAmount,
            ZERO_ADDRESS,
            ZERO_ADDRESS,
            ZERO_ADDRESS,
            expectedNICR,
            10,
            1e18
        );
       
        // Check A's coll and debt reduced
        uint256 debt_2 = troveManager.getTroveDebt(A);
        assertLt(debt_2, debt_1);
        uint256 coll_2 = troveManager.getTroveColl(A);
        assertLt(coll_2, coll_1);
    }

    // liquidate

    // SP deposit

    // SP withdraw
}