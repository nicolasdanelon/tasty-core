// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "TastyTokenMock.sol";

contract TastyTokenTest is Test {
    TastyTokenMock public tastyToken;
    using stdStorage for StdStorage;

    function setUp() public {
        tastyToken = new TastyTokenMock();
    }

    function testReservertShouldBeInThePeriod() public {
        vm.expectRevert("The period is out of the limits");
        tastyToken.reserve(9, 1, 2);
    }

    function testReservertIfReserveMoreThanLimit() public {
        uint8 day = 31;
        uint8 month = 4;
        uint8 period = 2;

        string memory keyOfReserve = string.concat(
            Strings.toString(day),
            Strings.toString(month)
        );

        for (uint256 i = 0; i < 21; i++) {
            tastyToken.reserve(period, day, month);
        }
        vm.expectRevert("There is not more space to reserve");
        tastyToken.reserve(period, day, month);
    }

    function testReserverShouldReservePeriod() public {
        uint8 day = 31;
        uint8 month = 4;
        uint8 period = 2;
        tastyToken.reserve(period, day, month);
        string memory keyOfReserve = string.concat(
            Strings.toString(day),
            Strings.toString(month)
        );
        uint256 countOfReserves = tastyToken.countOfReserves(
            period,
            keyOfReserve
        );

        assertEq(countOfReserves, 1);
    }

    function testReserverShouldReserveMultiplePeriod() public {
        uint8 day = 31;
        uint8 month = 4;
        uint8 period = 2;
        tastyToken.reserve(period, day, month);
        string memory keyOfReserve = string.concat(
            Strings.toString(day),
            Strings.toString(month)
        );
        uint256 countOfReserves = tastyToken.countOfReserves(
            period,
            keyOfReserve
        );

        assertEq(countOfReserves, 1);
    }

    function testReservertIfArePayingOutsideOfTheLimits() public {
        uint8 day = 31;
        uint8 month = 4;
        uint8 period = 2;
        string memory keyOfReserve = string.concat(
            Strings.toString(day),
            Strings.toString(month)
        );
        vm.expectRevert("Your amount is outside of the limits");

        tastyToken.reserve{value: 1 ether}(period, day, month);
    }

    function testReservertIfTheTokenIdIsNotCorrect() public {
        vm.expectRevert("The token Id does not existe");
        tastyToken.receivePerson(423423);
    }

    function testReservertIfTheTokenIsTaken() public {
        uint8 day = 31;
        uint8 month = 4;
        uint8 period = 2;
        uint256 newItemId = tastyToken.reserve{value: 0.01 ether}(
            period,
            day,
            month
        );

        tastyToken.setStatus(newItemId, TastyToken.ReservStatus.TAKED);
        vm.expectRevert("The reserve is already taken");
        tastyToken.receivePerson(newItemId);
    }

    function testReceivePersonChangeStatusToTaken() public {
        tastyToken.ownerDepositFound{value: 10 ether}();

        uint256 newItemId = tastyToken.reserve{value: 0.01 ether}(2, 31, 4);

        tastyToken.receivePerson(newItemId);
        (
            uint8 period,
            uint8 day,
            uint8 month,
            uint256 amountDeposited,
            TastyToken.ReservStatus status
        ) = tastyToken.tokenMetadata(newItemId);

        assertEq(uint256(status), uint256(TastyToken.ReservStatus.TAKED));
    }

    function testReceivePersonAmount() public {
        tastyToken.ownerDepositFound{value: 10 ether}();

        uint256 newItemId = tastyToken.reserve{value: 0.01 ether}(2, 31, 4);

        uint256 prevBalance = address(this).balance;

        tastyToken.receivePerson(newItemId);
        (
            uint8 period,
            uint8 day,
            uint8 month,
            uint256 amountDeposited,
            TastyToken.ReservStatus status
        ) = tastyToken.tokenMetadata(newItemId);

        uint256 newBalance = address(this).balance;

        assertEq(newBalance > prevBalance, true);
    }

    function testSellTicket() public {
        tastyToken.ownerDepositFound{value: 10 ether}();

        uint256 newItemId = tastyToken.reserve{value: 0.01 ether}(2, 31, 4);

        // assertEq(.length, 1);
    }

    function testOfferTicket() public {
        tastyToken.ownerDepositFound{value: 10 ether}();

        uint256 newItemId = tastyToken.reserve{value: 0.01 ether}(2, 31, 4);
        tastyToken.sellTicket(newItemId, 0.02 ether);
        vm.prank(address(1));
        deal(address(1), 10000e18);
        tastyToken.offer{value: 0.05 ether}(newItemId);
        address me = tastyToken.ownerOf(newItemId);

        assertEq(me, address(1));
    }

    receive() external payable {}

    fallback() external payable {}
}
