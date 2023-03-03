// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ContentStore.sol";

contract TestContentStore {
  ContentStore content;
  bytes32 cid1;

  function beforeAll() public {
    content = ContentStore(DeployedAddresses.ContentStore());
    cid1 = bytes32(bytes("QmcJw6x4bQr7oFnVnF6i8SLcJvhXjaxWvj54FYXmZ4Ct6p"));
  }

  function testAddPublicRepository() public {
    (,,, bool exists,) = content.metadata(cid1);

    Assert.equal(exists, false, "expect exists to be false on initial check");
    content.addPublicRepository(cid1);

    (,,, exists,) = content.metadata(cid1);
    Assert.equal(exists, true, "expect exists to be true after update");
  }

  function testTipAuthorForExistingRepository() public {
    uint balanceBefore = content.accountPendingTips(msg.sender);
    uint tip = 42;

    content.tipAuthorForRepository{value: tip}(cid1);
    uint balanceAfter = content.accountPendingTips(msg.sender);

    Assert.equal(balanceAfter, balanceBefore + tip, "expected increase in balanace of tip");
  }
}
