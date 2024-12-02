pragma solidity >=0.6.0 <0.8.0;

import "../library/SafeMath.sol";
import "./Params.sol";
import "./interfaces/IValidators.sol";
import "./library/SafeSend.sol";
import "./interfaces/IMultiPriceOracle.sol";

contract Reward is Params, SafeSend {
    using SafeMath for uint;

    address public admin;

    // normal, base on 10000
    uint public burnRate1;

    // price changes, base on 10000
    uint public burnRate2;

    uint public curretBurnRate;

    // Rewards for each block
    uint public reward;

    // oracle
    MultiPriceOracle public oracle;
    uint public prePrice;

    // base on 10000
    uint public dropPercentage; //such as 3000 = 30%
    uint public priceCheckPeriod ;

    event ChangeAdmin(address indexed admin);
    event UpdateBurnRates(uint burnRate);
    event UpdateReward(uint reward);
    event UpdateOracle(address indexed oracle);
    event UpdateDropPercentage(uint percentage);
    event UpdatePriceCheckPeriod(uint period);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function initialize(address _admin) external onlyNotInitialized {
        admin = _admin;
        initialized = true;
    }

    function changeAdmin(address _newAdmin)
    external
    onlyValidAddress(_newAdmin)
    onlyAdmin {
        admin = _newAdmin;
        emit ChangeAdmin(admin);
    }

    function updateBurnRates1(uint _burnRate)
    external
    onlyAdmin {
        require(_burnRate <= PERCENT_BASE, "Invalid rates");

        burnRate1 = _burnRate;

        emit UpdateBurnRates(_burnRate);
    }

    function updateBurnRates2(uint _burnRate)
    external
    onlyAdmin {
        require(_burnRate <= PERCENT_BASE, "Invalid rates");

        burnRate2 = _burnRate;

        emit UpdateBurnRates(_burnRate);
    }

    function updateReward(uint _reward)
    external
    onlyAdmin {
        reward = _reward;

        emit UpdateReward(_reward);
    }

    function updateOracle(address _addr) 
    external 
    onlyAdmin {
        oracle = MultiPriceOracle(_addr);

        emit UpdateOracle(_addr);
    }

    function updateDropPercentage(uint _percentage) 
    external 
    onlyAdmin {
        require(_percentage <= PERCENT_BASE, "Invalid percentage");
        dropPercentage = _percentage;

        emit UpdateDropPercentage(_percentage);
    }

    function updatePriceCheckPeriod(uint _period) 
    external 
    onlyAdmin {
        priceCheckPeriod = _period;

        emit UpdatePriceCheckPeriod(_period);
    }

    function currentBurnRate()
    internal 
    returns (uint) {
        uint burnRate = burnRate1;
        if ((address(oracle) != address(0))) {
            try oracle.assetPrices(address(0)) returns (uint nativePrice) {
                if (prePrice > nativePrice) {
                    uint drop = prePrice.sub(nativePrice);
                    uint256 _dropPercentage = drop.mul(10000).div(prePrice);
                    if (_dropPercentage >= dropPercentage) {
                        burnRate = burnRate2;
                    }
                }
                prePrice = nativePrice;
            } catch {}
        }

        return burnRate;
    }

    function withdrawReward()
    external 
    onlyValidatorsContract {
        if (reward == 0) {
            return;
        }

        if (curretBurnRate == 0) {
            curretBurnRate = burnRate1;
        }
        if (priceCheckPeriod != 0 && block.number.mod(priceCheckPeriod) == 0) {
            curretBurnRate = currentBurnRate();
        }

        uint burnVal = reward.mul(curretBurnRate).div(PERCENT_BASE);
        if (burnVal > address(this).balance) {
            return;
        }
        sendValue(validatorsContract.getBurnReceiver(), burnVal);

        uint foundationRate = validatorsContract.getFoundationRate();
        if (curretBurnRate + foundationRate > PERCENT_BASE) {
            foundationRate = PERCENT_BASE.sub(curretBurnRate);
        }

        uint foundationVal = reward.mul(foundationRate).div(PERCENT_BASE);

        uint _amount = reward.sub(burnVal);
        if (_amount > address(this).balance) {
            return;
        }
        validatorsContract.receiveBlockReward{value : _amount}(foundationVal);
    }

    receive() external payable {}
}