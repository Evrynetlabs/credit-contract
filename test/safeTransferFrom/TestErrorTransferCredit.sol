pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "../utils/ThrowProxy.sol";
import "../utils/PayableThrowProxy.sol";
import "../../contracts/ERC1155e.sol";

contract TestErrorTransferCredit {
    ERC1155E public credit;
    PayableThrowProxy private fooAccountProxy;
    ThrowProxy private operatorAccountProxy;
    address private fooAccount;
    address private operatorAccount;
    uint256 private initialCreditBalance = 100;
    uint256 private transferringAmount = 30;

    function beforeEach() external {
        credit = new ERC1155E();
        fooAccountProxy = new PayableThrowProxy(address(credit));
        fooAccount = address(fooAccountProxy);
        operatorAccountProxy = new ThrowProxy(address(credit));
        operatorAccount = address(operatorAccountProxy);
    }

    function prepareFungible() internal returns(uint256) {
        uint256 fungibleCreditID = credit.create("", false);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;
        uint256[] memory quantities = new uint256[](1);
        quantities[0] = initialCreditBalance;

        credit.mintFungible(fungibleCreditID, tos, quantities);
        return fungibleCreditID;
    }

    function prepareNonFungible() internal returns(uint256){
        uint256 nonFungibleCreditType = credit.create("", true);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;

        credit.mintNonFungible(nonFungibleCreditType, tos);
        return nonFungibleCreditType + 1;
    }

    function prepareOperator(bool approved) internal {
        ERC1155E(fooAccount).setApprovalForAll(operatorAccount, approved);
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error setting approval to operator");
    }

    function testErrorTransferCreditToZeroAddress() external {
        uint256 nonFungibleCreditID = prepareNonFungible();
        address barAccount = address(0);
        prepareOperator(true);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, nonFungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, nonFungibleCreditID);

        ERC1155E(fooAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error owner transfers to zero address");

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error operator transfers to zero address");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, nonFungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, nonFungibleCreditID);

        Assert.equal(initialFooAccountBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(initialBarAccountBalance, remainingBarAccountBalance, "bar account balance should not increased");
    }

    function testErrorUnauthorizedOperator() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(1);
        prepareOperator(false);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, transferringAmount, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error no transfer permission");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(initialBarAccountBalance, remainingBarAccountBalance, "bar account balance should not increased");
    }

    function testErrorTransferNonFungibleCreditWithoutOwnership() external {
        uint256 nonFungibleCreditID = prepareNonFungible() + 1;
        address barAccount = address(1);
        prepareOperator(true);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, nonFungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, nonFungibleCreditID);

        ERC1155E(fooAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error transfer without ownership");

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error transfer without ownership via operator");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, nonFungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, nonFungibleCreditID);

        Assert.equal(initialFooAccountBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(initialBarAccountBalance, remainingBarAccountBalance, "bar account balance should not increased");
    }

    function testErrorTransferCreditToNotSupportedContract() external {
        uint256 nonFungibleCreditID = prepareNonFungible();
        address barContract = address(new ThrowProxy(address(1)));
        prepareOperator(true);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, nonFungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barContract, nonFungibleCreditID);

        ERC1155E(fooAccount).safeTransferFrom(fooAccount, barContract, nonFungibleCreditID, 1, bytes(""));
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error owner transfers to not supported contract");

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barContract, nonFungibleCreditID, 1, bytes(""));
        (success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error operator transfers to not supported contract");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, nonFungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barContract, nonFungibleCreditID);

        Assert.equal(initialFooAccountBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(initialBarAccountBalance, remainingBarAccountBalance, "bar account balance should not increased");
    }
}