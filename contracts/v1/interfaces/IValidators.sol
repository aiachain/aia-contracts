pragma solidity >=0.6.0 <0.8.0;

import "./IVotePool.sol";

interface IValidators {
    function improveRanking() external;

    function lowerRanking() external;

    function removeRanking() external;

    function pendingReward(IVotePool pool) external view returns (uint);

    function withdrawReward() external;

    function votePools(address validator) external view returns (IVotePool);

    function getPoaMinMargin() external view returns (uint);

    function getPosMinMargin() external view returns (uint);

    function getPunishAmount() external view returns (uint);

    function receiveBlockReward(uint) external payable;

    function getMarginBurnRate() external view returns (uint);

    function getMarginBurnPeriod() external view returns (uint);

    function getBurnReceiver() external view returns (address payable);

    function getFoundationRate() external view returns (uint);
}

    enum Operation {Distribute, UpdateValidators}
