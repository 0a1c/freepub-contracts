// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

import "../contracts/ContentStore.sol";

contract TestContentStoreReentrancy {
  uint public initialBalance = 1 ether;

  ContentStore content = ContentStore(DeployedAddresses.ContentStore());

  address currentAddress = address(this);

  bytes32 constant cid1 = bytes32(bytes("QmcJw6x4bQr7oFnVnF6i8SLcJvhXjaxWvj54FYXmZ4Ct6p"));
  bytes32 constant cid2 = bytes32(bytes("Qmf412jQZiuVUtdgnB36FXFX7xg5V6KEbSJ4dpQuhkLyfD"));
  uint constant tip = 42;

  function beforeAll() public {
    content.publishContent(cid1);
    content.tipContent{value: tip}(cid1);

    content.tipContent{value: tip}(cid2);
  }

  function testWithdrawReentrancy() public {
    uint balanceBefore = currentAddress.balance;
    uint withdrawable = content.accountBalances(currentAddress);

    (bool success,) = address(content).call(
      abi.encodeCall(ContentStore.withdraw, ())
    );
    // Accept either a transaction revert or a successful transaction with
    // the expected result.
    if (success) {
      uint balanceAfter = currentAddress.balance;
      Assert.equal(balanceAfter, balanceBefore + withdrawable, "");
    }
  }

  receive() external payable {
    uint withdrawable = content.accountBalances(currentAddress);
    if (address(content).balance >= withdrawable) {
      content.withdraw();
    }
  }
}
