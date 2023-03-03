// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";

struct Metadata {
	// This is null for anonymous tx's
	address author; 
	uint tips;
	bool exists;

	Version version;
}

struct Version {
	bool hasNext;
	uint64 version;

	bytes32 previousCID;
	bytes32 nextCID;
}

contract ContentStore is Ownable {
	bytes32[] public store;
	mapping (bytes32 => Metadata) public metadata;

	mapping (address => uint) public accountBalances;

	uint32 public constant ownersCutInBPS = 100;

	function tipContent(bytes32 cid) public payable {
		if (!contentExists(cid)) {
			storeContent(cid);
		}
		updateStateForTip(cid, msg.value);
	}

	function updateStateForTip(bytes32 cid, uint tip) private {
		address author = metadata[cid].author;
		updateAuthorBalance(author, tip);
		metadata[cid].tips += tip;
	}

	function updateAuthorBalance(address account, uint tip) private {
		address empty;
		if (account == empty) {
			accountBalances[owner()] += tip;
		} else {
			accountBalances[account] += tip;
		}
	}

	function publishContent(bytes32 cid) public {
		requireContentIsNew(cid);
		storeContentAsAuthor(cid);
	}

	function updateContent(
		bytes32 cid,
		bytes32 previousCID 
	) public {
		// TODO
		// Update an existing repository by adding a new version
		// Enforce a valid update based on previousCID and increment
		// the version number automatically
	}

	function isUpdateValid(
		bytes32 previousCID 
	) public returns (bool) {
		// TODO
		// Return a boolean corresponding to whether an update is valid
		// given the previous CID (`hasNext` is false, the previous CID exists)
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
		// TODO
	}

	receive() external payable {
		// TODO
		accountBalances[owner()] += msg.value;
	}
}
