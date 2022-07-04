// SPDX-License-Identifier: MIT
pragma solidity 0.8;

library ADDRESS {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
