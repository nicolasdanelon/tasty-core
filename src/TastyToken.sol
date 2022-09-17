// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

import "forge-std/console.sol";

// 213 => 5
//

contract TastyToken is ERC721URIStorage {
    enum ReservStatus {
        RESERVED,
        TAKED,
        TOSELL
    }

    struct TastyTokenData {
        uint8 period;
        uint8 day;
        uint8 month;
        uint256 amountDeposited;
        ReservStatus status;
    }
    struct TastyToSell {
        uint256 price;
        uint256 tokenId;
        TastyTokenData tasty;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 MIN_RESERVE = 0.001 ether;
    uint256 MAX_RESERVE = 0.1 ether;

    uint256 PERCENTAGE_OF_REAWRD = 15; // 15%

    uint8 public constant FIRST_PERDIOD = 0;
    uint8 public constant SECOND_PERDIOD = 1;
    uint8 public constant THIRD_PERIOD = 2;
    uint8 public constant FOURTH_PERIOD = 3;
    uint8 public constant FIFTH_PERIOD = 4;
    uint256 public amountOfOwnerDeposited = 0;
    mapping(uint8 => mapping(string => uint8)) public countOfReserves;
    // mapping(address => uint256) countOfReserves;
    mapping(uint256 => TastyTokenData) public tokenMetadata;

    TastyToSell[] public ticketsToSell;

    constructor() ERC721("TastyToken", "TTKT") {}

    function reserve(
        uint8 periodToReserve,
        uint8 day,
        uint8 month
    ) external payable returns (uint256) {
        require(
            msg.value <= MAX_RESERVE && msg.value >= MIN_RESERVE,
            "Your amount is outside of the limits"
        );
        require(
            periodToReserve >= 0 && periodToReserve <= 4,
            "The period is out of the limits"
        );
        string memory keyOfReserve = string.concat(
            Strings.toString(day),
            Strings.toString(month)
        );
        require(
            countOfReserves[periodToReserve][keyOfReserve] <= 20,
            "There is not more space to reserve"
        );
        countOfReserves[periodToReserve][keyOfReserve] =
            countOfReserves[periodToReserve][keyOfReserve] +
            1;
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        tokenMetadata[newItemId] = TastyTokenData(
            periodToReserve,
            day,
            month,
            msg.value,
            ReservStatus.RESERVED
        );
        _tokenIds.increment();
        return newItemId;
    }

    uint256[] myArray;

    function sellTicket(uint256 _tokenId, uint256 _price) external {
        TastyTokenData memory data = tokenMetadata[_tokenId];

        require(data.period != 0, "The token Id does not exist");

        data.status = ReservStatus.TOSELL;
        tokenMetadata[_tokenId] = data;
        TastyToSell memory tastyToSell = TastyToSell(_price, _tokenId, data);

        ticketsToSell.push(tastyToSell);
    }

    function offer(uint256 _tokenId) external payable {
        TastyTokenData memory data = tokenMetadata[_tokenId];
        require(data.period != 0, "The token Id does not exist");
        require(
            data.status == ReservStatus.TOSELL,
            "The Ticket is not to sell"
        );

        for (uint256 index = 0; index < ticketsToSell.length; index++) {
            TastyToSell memory tastyToSell = ticketsToSell[index];
            if (tastyToSell.tokenId == _tokenId) {
                require(
                    msg.value >= tastyToSell.price,
                    "The price is higher than the amount you sent"
                );
                if (tastyToSell.price < msg.value) {
                    uint256 amountToReturn = msg.value - tastyToSell.price;
                    (bool sent, ) = msg.sender.call{value: amountToReturn}("");
                    require(sent, "Failed to send Ether");
                    data.status = ReservStatus.RESERVED;
                    address actualOwner = _ownerOf(_tokenId);
                    _safeTransfer(actualOwner, msg.sender, _tokenId, "0x");
                    delete ticketsToSell[index];

                    break;
                }
            }
        }
    }

    function receivePerson(uint256 _tokenId) external {
        TastyTokenData memory data = tokenMetadata[_tokenId];
        require(data.period != 0, "The token Id does not exist");
        require(
            data.status == ReservStatus.RESERVED,
            "The reserve is already taken"
        );
        data.status = ReservStatus.TAKED;
        uint256 feeToSend = _calculatePercentage(data.amountDeposited);
        address ownerOfToken = _ownerOf(_tokenId);

        uint256 amountToSend = data.amountDeposited + feeToSend;
        (bool sent, ) = ownerOfToken.call{value: amountToSend}("");
        require(sent, "Failed to send Ether");

        tokenMetadata[_tokenId] = data;
    }

    function _calculatePercentage(uint256 _value) internal returns (uint256) {
        return (_value * PERCENTAGE_OF_REAWRD) / 10000;
    }

    function ownerDepositFound() external payable {
        amountOfOwnerDeposited += msg.value;
    }
}

// period 1 : 15-16
// period 2 : 17-18
// period 1 : 19-20
// period 1 : 21-22
// period 1 : 23-24
