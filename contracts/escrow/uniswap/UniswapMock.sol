pragma solidity ^0.6.12;

contract MockFactory {
    function getPair(address token1, address token2) public returns (address) {
        address LPToken = 0xaF7C6DeAd245b93dE19BB1BB828B0AcCE94AEfb3;
        return LPToken;
    }
}
