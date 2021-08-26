pragma solidity ^0.8.0;

library RandomHelper {
    function randomNumber() internal view returns (uint256 _randomNumber) {
        uint256 gasleft = gasleft();
        _randomNumber = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, gasleft)
            )
        );

        // _randomNumber = 0;
        // bytes32 _blockhash = blockhash(block.number );
        // uint256 nonce = uint256(keccak256(abi.encodePacked(msg.sender, _blockhash)));
        //  _blockhash = blockhash(block.number - 1);
        // _randomNumber= uint256(keccak256(abi.encodePacked(nonce, _blockhash)));
    }

    function randomId(uint256 nonce, uint256 _maxNumber)
        internal
        view
        returns (uint256 _result)
    {
        uint256 _inputValue = randomNumber();
        bytes32 _structHash;
        bytes32 _blockhash = blockhash(block.number - 1);

        uint256 gasLeft = gasleft();

        // 1
        _structHash = keccak256(
            abi.encode(_inputValue, gasLeft, nonce, _blockhash)
        );
        uint256 rdValue = uint256(_structHash);
        assembly {
            rdValue := add(mod(rdValue, _maxNumber), 1)
        }
        _result = rdValue;
    }

    function randomPromoRate(uint256 nonce, uint256 _inputValue)
        internal
        view
        returns (uint256 _rate)
    {
        // return 0;
        uint256 _maxNumber = 10000;
        bytes32 _structHash;
        bytes32 _blockhash = blockhash(block.number - 1);
        uint256 gasLeft = gasleft();

        // 1
        _structHash = keccak256(
            abi.encode(_inputValue, gasLeft, nonce, _blockhash)
        );
        uint256 rdValue = uint256(_structHash);
        assembly {
            rdValue := add(mod(rdValue, _maxNumber), 1)
        }
        if (rdValue <= 5900) {
            _rate = 0;
        } else if (rdValue <= 8900) {
            _rate = 1;
        } else if (rdValue <= 9400) {
            _rate = 2;
        } else if (rdValue <= 9900) {
            _rate = 3;
        } else if (rdValue <= 10000) {
            _rate = 4;
        }
    }

    function randomRarity(uint256 nonce, uint256 _inputValue)
        internal
        view
        returns (uint256 _rarity)
    {
        // return 0;
        uint256 _maxNumber = 10000;
        bytes32 _structHash;
        bytes32 _blockhash = blockhash(block.number - 1);
        uint256 gasLeft = gasleft();

        // 1
        _structHash = keccak256(
            abi.encode(_inputValue, gasLeft, nonce, _blockhash)
        );
        uint256 rdValue = uint256(_structHash);
        assembly {
            rdValue := add(mod(rdValue, _maxNumber), 1)
        }
        if (rdValue <= 6100) {
            _rarity = 0;
        } else if (rdValue <= 8600) {
            _rarity = 1;
        } else if (rdValue <= 9500) {
            _rarity = 2;
        } else if (rdValue <= 9900) {
            _rarity = 3;
        } else if (rdValue <= 10000) {
            _rarity = 4;
        }
    }
}
