// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";

struct Metadata {
	bytes32 cid;

	// This is null for anonymous tx's
	address author; 
	uint tips;
	bool isTracked;
	
	Version version;
}

struct Version {
	bool hasNewer;
	uint64 version;

	bytes32 previousCID;
	bytes32 nextCID;
}

contract ContentStore is Ownable {
	bytes32[] public content;

	mapping (bytes32 => Metadata) public metadata;

	mapping (address => uint) public accountPendingTips;
	mapping (bytes32 => uint) public contentTotalTips;

	uint32 public constant ownersCutInBPS = 100;

	function tipAuthorForRepository(bytes32 cid) public payable {
		// Add anonymous repository if mapping does not exist
		// Increase balance for author's withdrawable

	}

	function addPublicRepository(bytes32 cid) public {
		// Upload a new public repository with the appropriate metadata
	}

	function updatePublicRepository(bytes32 cid) public {}

	function updatePublicRepository(
		bytes32 cid,
		bytes32 previousCID 
	) public {
		// Update an existing repository by adding a new version
		// Enforce a valid update based on previousCID and increment
		// the version number automatically
	}

	function isUpdateValid(
		bytes32 previousCID 
	) public returns (bool) {
		// Return a boolean corresponding to whether an update is valid
		// given the previous CID (`hasNewer` is false, the previous CID exists)
	}

	function addAnonymousRepository(bytes32 cid) private {}

	function withdraw() public {}

	receive() external payable {
		accountPendingTips[owner()] += msg.value;
	}
}
