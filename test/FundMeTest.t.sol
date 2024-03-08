// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    address USER = makeAddr("user");

    FundMe fundMe;
    function setUp() external {
        // We do it like this as we do not need to pass the address value again in test it will get called in the run() function written in scripts and ideally this should happen as we make 
        // script file to call and run the code that we write so we should call our function only inside the scripts and not in the tests and we also make our code more DRY
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // This line means that the next line should revert
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER); // This line means that the next transaction is performed by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure()  public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testFundAddsFundersToArray() public funded {
        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        address OWNER = fundMe.getOwner();
        uint256 startingOwnerBalance = OWNER.balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(OWNER);
        fundMe.withdraw();

        uint256 endingOwnerBalance = OWNER.balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; startingFunderIndex < numberOfFunders; startingFunderIndex++) {
            hoax(address(i), SEND_VALUE); // This is same as pranking the next line with address(i) and also dealing SEND_VALUE ether in that address
            fundMe.fund{value: SEND_VALUE}();
        }
        
        address OWNER = fundMe.getOwner();
        uint256 startingOwnerBalance = OWNER.balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(OWNER);
        fundMe.withdraw();

        uint256 endingOwnerBalance = OWNER.balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalance);        
    }
}