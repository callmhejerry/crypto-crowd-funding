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
