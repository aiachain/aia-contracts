pragma solidity >=0.6.0 <0.8.0;

interface MultiPriceOracle {
    function assetPrices(address asset) external view returns (uint);
}