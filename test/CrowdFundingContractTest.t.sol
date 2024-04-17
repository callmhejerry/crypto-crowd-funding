// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CrowdFunding} from "../src/CrowdFundingContract.sol";

contract CrowdFundingContractTest is Test {
    CrowdFunding crowdFunding;
    address CREATOR_1 = makeAddr("creator_1");
    address BENEFICIARY_1 = makeAddr("beneficiary_1");

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
        address contributor_1 = makeAddr("contributor_1");
        uint256 amountToContribute = 3 ether;

        vm.deal(contributor_1, 5 ether);
        vm.startPrank(contributor_1);

        crowdFunding.contributeToCampaign{value: amountToContribute}(0);

        assertEq(address(crowdFunding).balance, amountToContribute);
        assertEq(crowdFunding.getAmountContributed(0), amountToContribute);
        
        vm.stopPrank();
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
