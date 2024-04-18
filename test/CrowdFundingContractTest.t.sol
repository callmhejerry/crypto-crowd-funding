// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CrowdFunding} from "../src/CrowdFundingContract.sol";

contract CrowdFundingContractTest is Test {
    CrowdFunding crowdFunding;
    address CREATOR_1 = makeAddr("creator_1");
    address BENEFICIARY_1 = makeAddr("beneficiary_1");
    address contributor_1 = makeAddr("contributor_1");
    address contributor_2 = makeAddr("contributor_2");

    function setUp() public {
        crowdFunding = new CrowdFunding();
    }

    function testCreateCrowdFundingCampaign() public {
        vm.startPrank(CREATOR_1);

        string memory description = "First Crowd funding";
        uint256 startTime = block.timestamp;
        uint256 duration = 1 days;
        uint256 targetAmount = 10 ether;

        crowdFunding.createCampaign(startTime, duration, targetAmount, description, BENEFICIARY_1);

        assertEq(crowdFunding.getTotalCampaigns(), 1);
        (
            uint256 actualId,
            uint256 actualStartTime,
            uint256 actualEndTime,
            uint256 actualTargetAmount,
            address actualBeneficiary,
            uint256 actualFundingBalance,
            address actualCreator,
            string memory actualDescription
        ) = crowdFunding.getCampaignById(0);
        assertEq(actualDescription, description);
        assertEq(actualBeneficiary, BENEFICIARY_1);
        assertEq(actualCreator, CREATOR_1);
        assertEq(actualEndTime, startTime + duration);
        assertEq(actualFundingBalance, 0);
        assertEq(actualStartTime, startTime);
        assertEq(actualId, 0);
        assertEq(actualTargetAmount, targetAmount);
    }

    function testContributeToCampaign() createCampaign(CREATOR_1, BENEFICIARY_1) public {

        uint256 amountToContribute = 3 ether;

        vm.deal(contributor_1, 5 ether);
        vm.startPrank(contributor_1);

        crowdFunding.contributeToCampaign{value: amountToContribute}(0);

        assertEq(address(crowdFunding).balance, amountToContribute);
        assertEq(crowdFunding.getCampaignFundingBalance(0), amountToContribute);
        assertEq(crowdFunding.getAmountContributed(0), amountToContribute);
        
        vm.stopPrank();
    }

    function testRetrieveContribution() public createCampaign(CREATOR_1, BENEFICIARY_1) {
        uint256 amountToContribute = 3 ether;
        uint256 initialCrowdFundingBalance = address(crowdFunding).balance;
        vm.deal(contributor_1, 3 ether);
        vm.startPrank(contributor_1);
        crowdFunding.contributeToCampaign{value: 3 ether}(0);

        assertEq(address(crowdFunding).balance, initialCrowdFundingBalance +  amountToContribute);
        assertEq(crowdFunding.getAmountContributed(0), amountToContribute);

        skip(1 days);
        console.log("Campaign Status is: %d", uint(crowdFunding.getCampaignStatus(0)));
        // console.log("Hi");

        crowdFunding.retrieveContribution(0);
        assertEq(address(crowdFunding).balance, initialCrowdFundingBalance);
        assertEq(crowdFunding.getAmountContributed(0), 0);
        assertEq(contributor_1.balance, amountToContribute);
    }

    function testGetCampaignStatusToBeInavtive()public {
        vm.startPrank(CREATOR_1);
        uint256 campaignStartTime = block.timestamp + 1 days;
        uint256 campaignDuration = 2 weeks;

        crowdFunding.createCampaign(campaignStartTime, campaignDuration, 5 ether, "Testing inactive campaign", BENEFICIARY_1);

        uint256 campaignStatus = uint(crowdFunding.getCampaignStatus(0));

        assertEq(campaignStatus,0);
    }

    function testGetCampaignStatusToBeActive() public createCampaign(CREATOR_1, BENEFICIARY_1){
        uint256 campaignStatus = uint(crowdFunding.getCampaignStatus(0));
        
        assertEq(campaignStatus, 1);
    }

    function testGetCampaignStatusToBeSuccessful() public createCampaign(CREATOR_1, BENEFICIARY_1) {
        vm.deal(contributor_1, 10 ether);
        vm.stopPrank();
        vm.prank(contributor_1);

        crowdFunding.contributeToCampaign{value: 10 ether}(0);
        skip(2 days);

        uint256 campaignStatus = uint(crowdFunding.getCampaignStatus(0));

        assertEq(campaignStatus, 2);
    }

    function testGetCampaignStatusToBeFailed() public  createCampaign(CREATOR_1, BENEFICIARY_1){
        skip(2 days);
        uint256 campaignStatus = uint(crowdFunding.getCampaignStatus(0));

         assertEq(campaignStatus, 3);
    }


    function testClaimFundContributed() public createCampaign(CREATOR_1, BENEFICIARY_1)  {
        vm.stopPrank();
        vm.deal(contributor_1, 5 ether);
        vm.deal(contributor_2, 5 ether);

          uint256 crowdFundingBalanceBeforeContribution = address(crowdFunding).balance;

        vm.prank(contributor_1);
        crowdFunding.contributeToCampaign{value: 5 ether}(0);
        vm.prank(contributor_2);
        crowdFunding.contributeToCampaign{value: 5 ether}(0);

                uint256 crowdFundingBalanceAfterContribution = address(crowdFunding).balance;

        assertEq(crowdFundingBalanceAfterContribution, 10 ether);

        vm.expectRevert("CrowdFunding: Funds can only be claimed from successful campaign");
        vm.startPrank(BENEFICIARY_1);
        crowdFunding.claimFundsContributed(0);

        skip(2 days);

        uint256 beneficiaryBalanceBeforeClaiming = BENEFICIARY_1.balance;
        
        crowdFunding.claimFundsContributed(0);

        assertEq(BENEFICIARY_1.balance, beneficiaryBalanceBeforeClaiming +  10 ether);
        assertEq(address(crowdFunding).balance, crowdFundingBalanceBeforeContribution);
    }

    modifier createCampaign(address creator, address beneficiary) {
        vm.startPrank(creator);

        string memory description = "First Crowd funding";
        uint256 startTime = block.timestamp;
        uint256 duration = 1 days;
        uint256 targetAmount = 10 ether;

        crowdFunding.createCampaign(startTime, duration, targetAmount, description, beneficiary);
        _;
    }
}
