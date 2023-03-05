// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';

contract ContentStoreAxl is AxelarExecutable {
	bytes32[] public store;
	mapping (bytes32 => bool) public exists;

	constructor(address gateway_) AxelarExecutable(gateway_) {}

	function _execute(
		string calldata,
		string calldata,
		bytes calldata payload_
	) internal override {
		bytes32 cid = abi.decode(payload_, (bytes32));
		if (exists[cid]) {
			return;
		}

		store.push(cid);
		exists[cid] = true;
	}
}

