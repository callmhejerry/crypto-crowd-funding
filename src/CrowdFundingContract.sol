// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract CrowdFunding {
    uint256 private s_totalCampaigns;

    constructor() {
        s_totalCampaigns = 0;
    }

    enum CampaignStatus {
        INACTIVE,
        ACTIVE,
        SUCCESSFUL,
        FAILED
    }
    // EXPIRED,
    // REFUNDING,
    // COMPLETED

    mapping(uint256 => Campaign) s_idToCampaign;

    struct Campaign {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 targetAmount;
        address beneficiary;
        uint256 fundingBalance;
        address creator;
        string description;
        mapping(address => uint256) contributors; // maps the contributor's address to the amount contributed
    }

    /// @notice A function used by campaign creators to create Crowd funding campaign
    /// @param _duration(uint256): the duration that a campaign will be valid
    /// @param _targetAmount(uint256): the amount to needed for the funding to be successful
    /// @param _description(uint256): the description of the campaign project
    /// @param _beneficiary(address): the address of the account that will received the total amount gathered
    /// in the crowd funding
    function createCampaign(
        uint256 _startTime,
        uint256 _duration,
        uint256 _targetAmount,
        string memory _description,
        address _beneficiary
    ) external {
        require(_targetAmount > 0, "CrowdFunding: Target amount cannot be zero");

        Campaign storage campaign = s_idToCampaign[s_totalCampaigns];
        campaign.id = s_totalCampaigns;
        campaign.startTime = _startTime;
        campaign.beneficiary = _beneficiary;
        campaign.creator = msg.sender;
        campaign.fundingBalance = 0;
        campaign.targetAmount = _targetAmount;
        campaign.endTime = _startTime + _duration;
        campaign.description = _description;

        s_totalCampaigns++;
    }

    function contributeToCampaign(uint256 _campaignId) external payable {
        require(_campaignId < s_totalCampaigns, "CrowdFunding: Invalid campaignId");
        require(msg.value > 0, "CrowdFunding: Contribution should be more than 0");
        require(
            getCampaignStatus(_campaignId) == CampaignStatus.ACTIVE,
            "CrowdFunding: Cannot contribute to a campaign that is not active"
        );

        Campaign storage campaign = s_idToCampaign[_campaignId];

        campaign.fundingBalance += msg.value;
        campaign.contributors[msg.sender] += msg.value;
    }

    function getCampaignStatus(uint256 _campaignId) public view returns (CampaignStatus) {
        Campaign storage campaign = s_idToCampaign[_campaignId];
        uint256 campaignStartTime = campaign.startTime;
        uint256 campaignEndTime = campaign.endTime;
        bool isCampaignTargetReached = campaign.targetAmount >= campaign.fundingBalance;

        if (block.timestamp < campaignStartTime) {
            return CampaignStatus.INACTIVE;
        } else if (block.timestamp >= campaignStartTime && block.timestamp < campaignEndTime) {
            return CampaignStatus.ACTIVE;
        } else if (block.timestamp >= campaignEndTime && isCampaignTargetReached) {
            return CampaignStatus.SUCCESSFUL;
        } else {
            return CampaignStatus.FAILED;
        }
    }

    ////////////////////////
    /// VIEW FUNCTIONS
    ///////////////////////

    function getTotalCampaigns() public view returns (uint256) {
        return s_totalCampaigns;
    }

    function getCampaignById(uint256 _campaignId)
        public
        view
        returns (uint256, uint256, uint256, uint256, address, uint256, address, string memory)
    {
        Campaign storage campaign = s_idToCampaign[_campaignId];
        return (
            campaign.id,
            campaign.startTime,
            campaign.endTime,
            campaign.targetAmount,
            campaign.beneficiary,
            campaign.fundingBalance,
            campaign.creator,
            campaign.description
        );
    }
}
