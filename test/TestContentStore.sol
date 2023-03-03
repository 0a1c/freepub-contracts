// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

import "../contracts/ContentStore.sol";

contract TestContentStore is Ownable {
  uint public initialBalance = 1 ether;

  ContentStore content = ContentStore(DeployedAddresses.ContentStore());

  address currentAddress = address(this);
  address constant emptyAddress = address(0);

  bytes32 constant cid1 = bytes32(bytes("QmcJw6x4bQr7oFnVnF6i8SLcJvhXjaxWvj54FYXmZ4Ct6p"));
  bytes32 constant cid2 = bytes32(bytes("Qmf412jQZiuVUtdgnB36FXFX7xg5V6KEbSJ4dpQuhkLyfD"));
  bytes32 constant cid3 = bytes32(bytes("QmT1vneKp5pwvxUY12SGBYzWGqHJTjR4ykWMRyLgLwX43J"));
  bytes32 constant cid4 = bytes32(bytes("QmW3J3czdUzxRaaN31Gtu5T1U5br3t631b8AHdvxHdsHWg"));
  bytes32 constant cid5 = bytes32(bytes("QmTzfiBqmERArXmnFt7D3ABD1TqGPiV8njktV7yssEfzBj"));
  bytes32 constant emptyBytes32 = bytes32(bytes(""));

  uint constant tip = 42;

  function testPublishContent() public {
    assertExistsEquals(false, cid1);

    content.publishContent(cid1);

    assertExistsEquals(true, cid1);
    assertAuthorEquals(currentAddress, cid1);
    assertTipsEquals(0, cid1);

    assertEmptyVersion(cid1);
  }

  function assertEmptyVersion(bytes32 cid) public {
    Version memory version = contentVersion(cid);

    Assert.equal(version.hasNext, false, "");
    Assert.equal(version.number, 0, "");
    Assert.equal(version.previousCID, emptyBytes32, "");
    Assert.equal(version.nextCID, emptyBytes32, "");
  }

  function testAddDuplicatePublicRepository() public {
    assertExistsEquals(true, cid1);
    (bool success,) = address(content).call(
      abi.encodeCall(ContentStore.publishContent, (cid1))
    );
    Assert.isFalse(success, "");
  }

  function testTipContentForExistingRepository() public {
    assertExistsEquals(true, cid1);

    address author = contentAuthor(cid1);
    uint balanceBefore = content.accountBalances(author);
    content.tipContent{value: tip}(cid1);
    uint balanceAfter = content.accountBalances(author);

    Assert.equal(balanceAfter, balanceBefore + tip, "");
  }

  function testTipContentForNewRepository() public {
    assertExistsEquals(false, cid2);
    address author = contentAuthor(cid2);

    uint authorBalanceBefore = content.accountBalances(author);
    uint ownerBalanceBefore = content.accountBalances(owner());

    content.tipContent{value: tip}(cid2);

    uint authorBalanceAfter = content.accountBalances(author);
    uint ownerBalanceAfter = content.accountBalances(owner());

    Assert.equal(authorBalanceAfter, authorBalanceBefore, "");
    Assert.equal(ownerBalanceAfter, ownerBalanceBefore + tip, "");

    assertExistsEquals(true, cid2);
    assertAuthorEquals(emptyAddress, cid2);
    assertTipsEquals(tip, cid2);
    assertEmptyVersion(cid2);
  }

  function testPublishNewVersionForKnownAuthor() public {
    assertExistsEquals(true, cid1);
    assertExistsEquals(false, cid3);
    
    content.publishNewVersionForContent(cid3, cid1);
    
    assertExistsEquals(true, cid3);
    assertAuthorEquals(currentAddress, cid3);
    assertTipsEquals(0, cid3);

    Version memory prevVersion = contentVersion(cid1); 
    Version memory expPrevVersion = Version({
      hasNext: true,
      number: 0,
      previousCID: emptyBytes32,
      nextCID: cid3
    });
    assertVersionEquals(expPrevVersion, prevVersion);

    Version memory expCurVersion = Version({
      hasNext: false,
      number: 1,
      previousCID: cid1,
      nextCID: emptyBytes32
    });
    Version memory curVersion = contentVersion(cid3);
    assertVersionEquals(expCurVersion, curVersion);
  }

  function testPublishNewVersionFailures() public {
    assertExistsEquals(true, cid1);
    assertExistsEquals(true, cid2);
    assertExistsEquals(true, cid3);
    assertExistsEquals(false, cid4);
    assertExistsEquals(false, cid5);

    bool success;

    // Re-publish content
    (success,) = address(content).call(
      abi.encodeCall(ContentStore.publishNewVersionForContent, (cid2, cid3))
    );
    Assert.isFalse(success, "");

    // Circular update
    (success,) = address(content).call(
      abi.encodeCall(ContentStore.publishNewVersionForContent, (cid1, cid3))
    );
    Assert.isFalse(success, "");

    // Publish new version for non-existent content
    (success,) = address(content).call(
      abi.encodeCall(ContentStore.publishNewVersionForContent, (cid5, cid4))
    );
    Assert.isFalse(success, "");

    // Publish new version for anonymous content 
    (success,) = address(content).call(
      abi.encodeCall(ContentStore.publishNewVersionForContent, (cid5, cid2))
    );
    Assert.isFalse(success, "");

    // Publish new version for content that hasNext
    (success,) = address(content).call(
      abi.encodeCall(ContentStore.publishNewVersionForContent, (cid5, cid1))
    );
    Assert.isFalse(success, "");
  }

  function testWithdraw() public {
    uint balanceBefore = currentAddress.balance; 
    uint withdrawableBefore = content.accountBalances(currentAddress);
    Assert.isAbove(withdrawableBefore, 0, "");

    content.withdraw();

    uint balanceAfter = currentAddress.balance; 
    uint withdrawableAfter = content.accountBalances(currentAddress);
  
    Assert.equal(withdrawableAfter, 0, "");
    Assert.equal(balanceAfter, balanceBefore + withdrawableBefore, "");
  }

  // TODO: Withdraw Failure
  // TODO: Withdraw Re-Entrancy

  function testReceive() public {
    uint ownerBalanceBefore = content.accountBalances(owner());
    (bool success,) = address(content).call{value: tip}("");
    uint ownerBalanceAfter = content.accountBalances(owner());

    Assert.isTrue(success, "");
    Assert.equal(ownerBalanceAfter, ownerBalanceBefore + tip, "");
  }

  function assertVersionEquals(Version memory expVersion, Version memory version) public {
    Assert.equal(version.hasNext, expVersion.hasNext, "expect hasNext to match provided");
    Assert.equal(version.number, expVersion.number, "expect number to match provided");
    Assert.equal(version.previousCID, expVersion.previousCID, "expect previousCID to match provided");
    Assert.equal(version.nextCID, expVersion.nextCID, "expect nextCID to match provided");
  }

  function assertAuthorEquals(address expAuthor, bytes32 cid) public {
    address author = contentAuthor(cid);
    Assert.equal(author, expAuthor, "expect author to match provided");
  }

  function assertExistsEquals(bool expExists, bytes32 cid) public {
    (,, bool exists,) = content.metadata(cid);
    Assert.equal(exists, expExists, "expect exists to match provided");
  }

  function assertTipsEquals(uint expTips, bytes32 cid) public {
    (, uint tips,,) = content.metadata(cid);
    Assert.equal(tips, expTips, "expect tips to match provided");
  }

  function contentAuthor(bytes32 cid) public view returns (address) {
    (address author,,,) = content.metadata(cid);
    return author;
  }

  function contentVersion(bytes32 cid) public view returns (Version memory) {
    (,,, Version memory version) = content.metadata(cid);
    return version;
  }

  receive() external payable {}
}
