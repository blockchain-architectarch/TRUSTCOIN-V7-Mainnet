// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrustcoinV7Mainnet is ERC20, Ownable {

    uint256 public constant INITIAL_SUPPLY  = 200_000_000 * 10**18;
    uint256 public constant BURN_TARGET     = 100_000_000 * 10**18;
    uint256 public constant MONTHLY_RELEASE =   4_000_000 * 10**18;
    uint64  public constant TOTAL_MONTHS    = 50;

    uint256 public constant RELEASE_PERIOD = 30 days;
    uint256 public constant WALLET_LIMIT_UNLOCK = 1811808000;
    uint256 public constant EARLY_WALLET_LIMIT = 10_000 * 10**18;

    address public constant FUND_ADDRESS   = 0xaE851e35a6d4dd66D7Fc2aAAe603a2eD744763Af;
    address public constant HOLDERS_POOL   = 0x487E0513F6C96814349A7607F427a920cC4A002A;
    address public constant GUARDS_POOL    = 0x31e0712b7b21dce5B5b15b66AD3F60F8ca235c4c;
    address public constant CHARITY_POOL   = 0x0bcAb02E1610aD3e61c7A0090cE401b7ad041426;
    address public constant OTC_HUB_ADDRESS = 0xA8e5095dF9f22dA77021454064995cCEd79D2A5D;

    mapping(address => bool) public isExempt;

    address public emissionBridge;
    address public taxBridge;
    address public priceOracle;
    address public oracleAdmin;
    address public exemptAdmin;

    uint128 public basePrice;
    uint128 public currentPrice;
    uint64  public deployTimestamp;
    uint64  public lastReleaseTime;
    uint64  public priceUpdatedAt;
    uint128 public burnedTotal;
    uint64  public monthsReleased;
    bool    public burningStopped;

    mapping(address => uint256) public holderSince;

    event MonthlyReleaseExecuted(uint256 indexed month, uint256 toEmissionBridge, uint256 burned, uint256 ts);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice, address by);
    event BasePriceReset(uint256 oldBase, uint256 newBase);
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);
    event OracleAdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event EmissionBridgeSet(address indexed bridge);
    event TaxBridgeSet(address indexed bridge);
    event TaxDistributed(address indexed from, uint256 burned, uint256 toFund, uint256 toTaxBridge);
    event BurnComplete(uint256 total, uint256 ts);
    event HolderRegistered(address indexed holder, uint256 timestamp);
    event HolderReset(address indexed holder);
    event ExemptSet(address indexed addr, bool exempt);
    event OracleAdminTransferred(address indexed oldAdmin, address indexed newAdmin, uint256 ts);
    event ExemptAdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event ExemptAdminTransferred(address indexed oldAdmin, address indexed newAdmin, uint256 ts);

    constructor(uint128 _initialPrice, address _oracleAdmin, address _exemptAdmin)
        ERC20("Trustcoin", "TRUST")
        Ownable(msg.sender)
    {
        require(_initialPrice > 0, "Price must be > 0");
        require(_oracleAdmin != address(0), "Zero: oracleAdmin");
        require(_exemptAdmin != address(0), "Zero: exemptAdmin");
        deployTimestamp = uint64(block.timestamp);
        lastReleaseTime = uint64(block.timestamp) - uint64(RELEASE_PERIOD);
        priceUpdatedAt  = uint64(block.timestamp);
        basePrice       = _initialPrice;
        currentPrice    = _initialPrice;
        oracleAdmin     = _oracleAdmin;
        exemptAdmin     = _exemptAdmin;

        isExempt[address(this)]      = true;
        isExempt[FUND_ADDRESS]       = true;
        isExempt[HOLDERS_POOL]       = true;
        isExempt[GUARDS_POOL]        = true;
        isExempt[CHARITY_POOL]       = true;
        isExempt[OTC_HUB_ADDRESS]    = true;

        _mint(address(this), INITIAL_SUPPLY);
    }

    function setEmissionBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "Zero: emissionBridge");
        emissionBridge = _bridge;
        emit EmissionBridgeSet(_bridge);
    }

    function setTaxBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "Zero: taxBridge");
        taxBridge = _bridge;
        emit TaxBridgeSet(_bridge);
    }

    function setOracleAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Zero: oracleAdmin");
        address old = oracleAdmin;
        oracleAdmin = _admin;
        emit OracleAdminUpdated(old, _admin);
    }

    function transferOracleAdmin(address _newAdmin) external {
        require(msg.sender == oracleAdmin, "Not authorized");
        require(_newAdmin != address(0), "Zero: oracleAdmin");
        address old = oracleAdmin;
        oracleAdmin = _newAdmin;
        emit OracleAdminTransferred(old, _newAdmin, block.timestamp);
    }

    function setOracleAddress(address _newOracle) external {
        require(msg.sender == owner() || msg.sender == oracleAdmin, "Not authorized");
        address old = priceOracle;
        priceOracle = _newOracle;
        emit OracleUpdated(old, _newOracle);
    }

    function setExempt(address _addr, bool _exempt) external {
        require(msg.sender == owner() || msg.sender == exemptAdmin, "Not authorized");
        require(_addr != address(0), "Zero address");
        isExempt[_addr] = _exempt;
        emit ExemptSet(_addr, _exempt);
    }

    function setExemptAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Zero: exemptAdmin");
        address old = exemptAdmin;
        exemptAdmin = _admin;
        emit ExemptAdminUpdated(old, _admin);
    }

    function transferExemptAdmin(address _newAdmin) external {
        require(msg.sender == exemptAdmin, "Not authorized");
        require(_newAdmin != address(0), "Zero: exemptAdmin");
        address old = exemptAdmin;
        exemptAdmin = _newAdmin;
        emit ExemptAdminTransferred(old, _newAdmin, block.timestamp);
    }

    function updatePrice(uint128 _newPrice) external {
        require(msg.sender == owner() || msg.sender == priceOracle, "Not authorized");
        require(_newPrice > 0, "Price must be > 0");
        uint128 old  = currentPrice;
        currentPrice = _newPrice;
        priceUpdatedAt = uint64(block.timestamp);
        emit PriceUpdated(old, _newPrice, msg.sender);
    }

    function resetBasePrice() external onlyOwner {
        uint128 old = basePrice;
        basePrice   = currentPrice;
        emit BasePriceReset(old, currentPrice);
    }

    function _dropPercent() internal view returns (uint256) {
        if (currentPrice >= basePrice) return 0;
        unchecked {
            return ((uint256(basePrice) - uint256(currentPrice)) * 100) / uint256(basePrice);
        }
    }

    function _panicTax() internal view returns (uint256) {
        uint256 drop = _dropPercent();
        if (drop < 10)  return 0;
        if (drop >= 50) return 5;
        unchecked { return drop / 10; }
    }

    function monthlyRelease() external onlyOwner {
        require(emissionBridge != address(0), "Emission bridge not set");
        require(monthsReleased < TOTAL_MONTHS, "All months released");
        require(block.timestamp >= uint256(lastReleaseTime) + RELEASE_PERIOD, "Too early");

        uint256 available = balanceOf(address(this));
        require(available > 0, "Treasury empty");

        uint256 toRelease        = available < MONTHLY_RELEASE ? available : MONTHLY_RELEASE;
        uint256 toBurn           = toRelease / 2;
        uint256 toEmissionBridge = toRelease - toBurn;

        unchecked { monthsReleased++; }
        lastReleaseTime = uint64(block.timestamp);

        if (toBurn > 0 && !burningStopped) {
            super._update(address(this), address(0), toBurn);
            unchecked { burnedTotal += uint128(toBurn); }
            _checkStop();
        }
        if (toEmissionBridge > 0) {
            super._update(address(this), emissionBridge, toEmissionBridge);
        }
        emit MonthlyReleaseExecuted(monthsReleased, toEmissionBridge, toBurn, block.timestamp);
    }

    function _checkStop() internal {
        if (!burningStopped && burnedTotal >= uint128(BURN_TARGET)) {
            burningStopped = true;
            emit BurnComplete(burnedTotal, block.timestamp);
        }
    }

    function _isPeriod1() internal view returns (bool) {
        return monthsReleased < TOTAL_MONTHS;
    }

    function _isExempt(address addr) internal view returns (bool) {
        return isExempt[addr];
    }

    function _walletLimit() internal view returns (uint256) {
        if (block.timestamp < WALLET_LIMIT_UNLOCK) {
            return EARLY_WALLET_LIMIT;
        }
        return type(uint256).max;
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        bool toExempt   = _isExempt(to);
        bool fromExempt = _isExempt(from);

        if (!toExempt && holderSince[to] == 0) {
            holderSince[to] = block.timestamp;
            emit HolderRegistered(to, block.timestamp);
        }
        if (!fromExempt && from != emissionBridge && holderSince[from] != 0) {
            delete holderSince[from];
            emit HolderReset(from);
        }

        if (!toExempt) {
            require(balanceOf(to) + amount <= _walletLimit(), "Exceeds wallet limit");
        }

        if (taxBridge == address(0) || emissionBridge == address(0)) {
            super._update(from, to, amount);
            return;
        }

        if (fromExempt || toExempt) {
            super._update(from, to, amount);
            return;
        }

        bool period1 = _isPeriod1();

        if (period1) {
            require(amount >= 1_000 * 10**18, "Min 1000 tokens in Period 1");
        }

        uint256 panicRate = _panicTax();
        uint256 totalBurn;
        uint256 totalFund;
        uint256 totalTaxBridge;

        unchecked {
            if (period1) {
                uint256 baseBridge = (amount * 25) / 10000;
                uint256 baseFund   = (amount * 25) / 10000;
                uint256 panicFund;
                uint256 panicBridge;
                if (panicRate > 0) {
                    uint256 panicTotal = (amount * panicRate) / 100;
                    panicFund   = panicTotal / 2;
                    panicBridge = panicTotal - panicFund;
                }
                totalBurn      = 0;
                totalFund      = baseFund + panicFund;
                totalTaxBridge = baseBridge + panicBridge;
            } else {
                uint256 baseFund      = (amount * 25) / 10000;
                uint256 baseTaxBridge = (amount * 25) / 10000;
                uint256 panicFund;
                uint256 panicBridge;
                if (panicRate > 0) {
                    uint256 panicTotal = (amount * panicRate) / 100;
                    panicFund   = panicTotal / 2;
                    panicBridge = panicTotal - panicFund;
                }
                totalBurn      = 0;
                totalFund      = baseFund + panicFund;
                totalTaxBridge = baseTaxBridge + panicBridge;
            }
        }

        uint256 sendAmount = amount - totalBurn - totalFund - totalTaxBridge;

        if (totalBurn > 0) {
            super._update(from, address(0), totalBurn);
            unchecked { burnedTotal += uint128(totalBurn); }
            _checkStop();
        }
        if (totalFund > 0) {
            super._update(from, FUND_ADDRESS, totalFund);
        }
        if (totalTaxBridge > 0) {
            super._update(from, taxBridge, totalTaxBridge);
        }
        super._update(from, to, sendAmount);

        emit TaxDistributed(from, totalBurn, totalFund, totalTaxBridge);
    }

    function getHolderDay(address holder) external view returns (uint256) {
        if (holderSince[holder] == 0) return 0;
        unchecked { return (block.timestamp - holderSince[holder]) / 1 days + 1; }
    }

    function isActiveHolder(address holder) external view returns (bool) {
        return holderSince[holder] != 0 && balanceOf(holder) > 0;
    }

    function nextReleaseIn() external view returns (uint256 daysLeft) {
        uint256 next = uint256(lastReleaseTime) + RELEASE_PERIOD;
        if (block.timestamp >= next) return 0;
        return (next - block.timestamp) / 1 days;
    }

    function burnProgress() external view returns (
        uint256 currentSupply, uint256 burned, uint256 burnedPercent, uint256 remaining, bool stopped
    ) {
        currentSupply = totalSupply();
        burned        = burnedTotal;
        unchecked { burnedPercent = (uint256(burnedTotal) * 100) / BURN_TARGET; }
        remaining = burnedTotal >= uint128(BURN_TARGET) ? 0 : BURN_TARGET - burnedTotal;
        stopped   = burningStopped;
    }

    function releaseStatus() external view returns (
        uint256 dropPercent, uint256 panicTaxPercent, uint256 nextInDays, uint256 monthsLeft, bool period1
    ) {
        dropPercent     = _dropPercent();
        panicTaxPercent = _panicTax();
        monthsLeft      = monthsReleased < TOTAL_MONTHS ? TOTAL_MONTHS - monthsReleased : 0;
        uint256 next    = uint256(lastReleaseTime) + RELEASE_PERIOD;
        nextInDays      = block.timestamp >= next ? 0 : (next - block.timestamp) / 1 days;
        period1         = _isPeriod1();
    }

    function walletLimitStatus() external view returns (uint256 currentLimit, uint256 unlocksAt, bool unlocked) {
        currentLimit = _walletLimit();
        unlocksAt    = WALLET_LIMIT_UNLOCK;
        unlocked     = block.timestamp >= WALLET_LIMIT_UNLOCK;
    }

    function allBalances() external view returns (
        uint256 treasury, uint256 emBridge, uint256 txBridge, uint256 fund,
        uint256 holders, uint256 guards, uint256 charity, uint256 otcHub
    ) {
        treasury  = balanceOf(address(this));
        emBridge  = emissionBridge != address(0) ? balanceOf(emissionBridge) : 0;
        txBridge  = taxBridge      != address(0) ? balanceOf(taxBridge)      : 0;
        fund      = balanceOf(FUND_ADDRESS);
        holders   = balanceOf(HOLDERS_POOL);
        guards    = balanceOf(GUARDS_POOL);
        charity   = balanceOf(CHARITY_POOL);
        otcHub    = balanceOf(OTC_HUB_ADDRESS);
    }

    function version() external pure returns (string memory) {
        return "Trustcoin V7 MAINNET - exemptAdmin+oracleAdmin dual-role, WALLET_LIMIT_UNLOCK fixed-date, 50mo/4M emission, immediate first release";
    }
}
