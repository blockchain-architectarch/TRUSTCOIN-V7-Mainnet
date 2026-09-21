// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITrustcoinV7 {
    function monthsReleased() external view returns (uint64);
}

contract TaxBridgeV7Mainnet is Ownable {

    uint256 public constant HOLDERS_SHARE = 8000;
    uint256 public constant GUARDS_SHARE  = 1000;
    uint256 public constant CHARITY_SHARE = 1000;

    uint256 public constant DISTRIBUTION_PERIOD = 90 days;
    uint256 public constant TIMELOCK_DURATION   = 365 days;
    uint64  public constant UNLOCK_MONTH        = 50;

    address public constant GUARDS_VAULT  = 0x31e0712b7b21dce5B5b15b66AD3F60F8ca235c4c;
    address public constant CHARITY_VAULT = 0x0bcAb02E1610aD3e61c7A0090cE401b7ad041426;

    ITrustcoinV7 public trustToken;

    address public holdersDistributor;
    address public pendingDistributor;
    uint256 public timelockEnd;

    uint256 public lastDistribution;
    uint256 public totalDistributed;
    uint256 public distributionCount;

    event Distributed(uint256 indexed count, uint256 total, uint256 toHolders, uint256 toGuards, uint256 toCharity, uint256 ts);
    event DistributorProposed(address indexed proposed, uint256 timelockEnd, uint256 ts);
    event DistributorApplied(address indexed oldDistributor, address indexed newDistributor, uint256 ts);
    event DistributorProposalCancelled(address indexed cancelled, uint256 ts);
    event HoldersDistributorSet(address indexed distributor, uint256 ts);

    constructor(address _trustToken) Ownable(msg.sender) {
        require(_trustToken != address(0), "Zero: trustToken");
        trustToken       = ITrustcoinV7(_trustToken);
        lastDistribution = block.timestamp;
    }

    function initializeDistributor(address _distributor) external onlyOwner {
        require(holdersDistributor == address(0), "Already initialized - use proposeDistributor");
        require(_distributor != address(0), "Zero: distributor");
        holdersDistributor = _distributor;
        emit HoldersDistributorSet(_distributor, block.timestamp);
    }

    function proposeDistributor(address _distributor) external onlyOwner {
        require(_distributor != address(0), "Zero: distributor");
        require(_distributor != holdersDistributor, "Already active");
        pendingDistributor = _distributor;
        timelockEnd        = block.timestamp + TIMELOCK_DURATION;
        emit DistributorProposed(_distributor, timelockEnd, block.timestamp);
    }

    function applyDistributor() external {
        require(pendingDistributor != address(0), "Nothing pending");
        require(block.timestamp >= timelockEnd, "Timelock not expired");
        address old        = holdersDistributor;
        holdersDistributor = pendingDistributor;
        pendingDistributor = address(0);
        timelockEnd        = 0;
        emit DistributorApplied(old, holdersDistributor, block.timestamp);
        emit HoldersDistributorSet(holdersDistributor, block.timestamp);
    }

    function cancelProposal() external onlyOwner {
        require(pendingDistributor != address(0), "Nothing to cancel");
        require(block.timestamp < timelockEnd, "Timelock expired - apply it");
        address cancelled  = pendingDistributor;
        pendingDistributor = address(0);
        timelockEnd        = 0;
        emit DistributorProposalCancelled(cancelled, block.timestamp);
    }

    function distribute() external {
        require(holdersDistributor != address(0), "Distributor not set");
        require(trustToken.monthsReleased() >= UNLOCK_MONTH, "Locked until month 51");
        require(block.timestamp >= lastDistribution + DISTRIBUTION_PERIOD, "Too early: wait 90 days");

        uint256 balance = IERC20(address(trustToken)).balanceOf(address(this));
        require(balance > 0, "Bridge is empty");

        uint256 toHolders = (balance * HOLDERS_SHARE) / 10000;
        uint256 toGuards  = (balance * GUARDS_SHARE)  / 10000;
        uint256 toCharity = balance - toHolders - toGuards;

        lastDistribution = block.timestamp;
        unchecked { totalDistributed += balance; distributionCount++; }

        require(IERC20(address(trustToken)).transfer(holdersDistributor, toHolders), "Holders transfer failed");
        require(IERC20(address(trustToken)).transfer(GUARDS_VAULT, toGuards), "Guards transfer failed");
        require(IERC20(address(trustToken)).transfer(CHARITY_VAULT, toCharity), "Charity transfer failed");

        emit Distributed(distributionCount, balance, toHolders, toGuards, toCharity, block.timestamp);
    }

    function isUnlocked() external view returns (bool) {
        return trustToken.monthsReleased() >= UNLOCK_MONTH;
    }

    function isReady() external view returns (bool) {
        return (
            holdersDistributor != address(0) &&
            trustToken.monthsReleased() >= UNLOCK_MONTH &&
            block.timestamp >= lastDistribution + DISTRIBUTION_PERIOD &&
            IERC20(address(trustToken)).balanceOf(address(this)) > 0
        );
    }

    function nextDistributionIn() external view returns (uint256 daysLeft) {
        uint256 next = lastDistribution + DISTRIBUTION_PERIOD;
        if (block.timestamp >= next) return 0;
        return (next - block.timestamp) / 1 days;
    }

    function timelockRemainingDays() external view returns (uint256) {
        if (pendingDistributor == address(0)) return 0;
        if (block.timestamp >= timelockEnd) return 0;
        return (timelockEnd - block.timestamp) / 1 days;
    }

    function bridgeBalance() external view returns (uint256) {
        return IERC20(address(trustToken)).balanceOf(address(this));
    }

    function previewDistribution() external view returns (uint256 total, uint256 toHolders, uint256 toGuards, uint256 toCharity) {
        total     = IERC20(address(trustToken)).balanceOf(address(this));
        toHolders = (total * HOLDERS_SHARE) / 10000;
        toGuards  = (total * GUARDS_SHARE)  / 10000;
        toCharity = total - toHolders - toGuards;
    }

    function status() external view returns (
        uint256 balance, uint256 nextInDays, uint256 totalSent, uint256 count,
        bool unlocked, bool ready, address distributor, address pending, uint256 timelockDaysLeft
    ) {
        balance    = IERC20(address(trustToken)).balanceOf(address(this));
        uint256 next = lastDistribution + DISTRIBUTION_PERIOD;
        nextInDays = block.timestamp >= next ? 0 : (next - block.timestamp) / 1 days;
        totalSent  = totalDistributed;
        count      = distributionCount;
        unlocked   = trustToken.monthsReleased() >= UNLOCK_MONTH;
        ready      = holdersDistributor != address(0) && unlocked && block.timestamp >= next && balance > 0;
        distributor      = holdersDistributor;
        pending          = pendingDistributor;
        timelockDaysLeft = this.timelockRemainingDays();
    }

    function version() external pure returns (string memory) {
        return "TaxBridge V7 MAINNET - UNLOCK_MONTH=50 - split 80/10/10 - 365day timelock migration - 90day distribute";
    }
}
