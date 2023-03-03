// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";

// TODO: Handle forced-funds

struct Metadata {
	// This is null for anonymous tx's
	address author; 
	uint tips;
	bool exists;

	Version version;
}

struct Version {
	bool hasNext;
	uint64 number;

	bytes32 previousCID;
	bytes32 nextCID;
}

contract ContentStore is Ownable {
	bytes32[] public store;
	mapping (bytes32 => Metadata) public metadata;

	mapping (address => uint) public accountBalances;

	uint32 public constant ownersCutInBPS = 500;
	uint32 public constant totalBPS = 10_000;

	function tipContent(bytes32 cid) public payable {
		if (!contentExists(cid)) {
			storeContent(cid);
		}
		updateStateForTip(cid, msg.value);
	}

	function updateStateForTip(bytes32 cid, uint tip) private {
		updateBalanceForContentAuthor(cid, tip);
		metadata[cid].tips += tip;
	}

	function updateBalanceForContentAuthor(bytes32 cid, uint tip) private {
		address author = metadata[cid].author;
		address empty;
		if (author == empty) {
			accountBalances[owner()] += tip;
		} else {
			uint ownersTip = (ownersCutInBPS * tip) / totalBPS;
			accountBalances[owner()] += ownersTip;
			accountBalances[author] += tip - ownersTip;
		}
	}

	function publishContent(bytes32 cid) public {
		requireContentIsNew(cid);
		storeContentAsAuthor(cid);
	}

	function publishNewVersionForContent(
		bytes32 cid,
		bytes32 previousCID 
	) public {
		requireNewVersionIsValid(cid, previousCID);
		publishContent(cid);
		updateStateForNewVersion(cid, previousCID);
	}

	function requireNewVersionIsValid(
		bytes32 cid,
		bytes32 previousCID 
	) private view {
		bool previousContentExists = contentExists(previousCID);
		require(previousContentExists, "cannot update for content that is not stored");

		bool contentIsLatest = !metadata[previousCID].version.hasNext;
		require(contentIsLatest, "cannot update for content that has a next version");

		bool authorIsSender = metadata[previousCID].author == msg.sender;
		require(authorIsSender, "cannot update as sender is not the author");

		bool isCircularVersion = metadata[previousCID].version.nextCID == cid;
		require(!isCircularVersion, "cannot update version circular");
	}

	function updateStateForNewVersion(bytes32 cid, bytes32 previousCID) private {
		metadata[cid].version.number = metadata[previousCID].version.number + 1;
		metadata[cid].version.previousCID = previousCID;

		metadata[previousCID].version.nextCID = cid;
		metadata[previousCID].version.hasNext = true;
	}

	function requireContentIsNew(bytes32 cid) private view {
		require(!contentExists(cid), "cannot perform transaction since content exists");
	}

	function contentExists(bytes32 cid) private view returns (bool) {
		return metadata[cid].exists;
	}

	function storeContentAsAuthor(bytes32 cid) private {
		storeContent(cid);
		metadata[cid].author = msg.sender;
	}

	function storeContent(bytes32 cid) private {
		metadata[cid].exists = true;
		store.push(cid);
	}

	function withdraw() public {
		require(accountBalances[msg.sender] > 0, "no funds to withdraw");
		uint balance = accountBalances[msg.sender];
		accountBalances[msg.sender] = 0;
		payable(msg.sender).transfer(balance);	
	}

	receive() external payable {
		accountBalances[owner()] += msg.value;
	}
}
