// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../src/TastyToken.sol";

contract TastyTokenMock is TastyToken {
    function setStatus(uint256 _tokenId, TastyToken.ReservStatus _status)
        public
    {
        TastyTokenData memory data = tokenMetadata[_tokenId];
        data.status = _status;
        tokenMetadata[_tokenId] = data;
    }
}
