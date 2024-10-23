pragma solidity ^0.8.20;

// [
//     "0xeEE4739AD49c232Ef2Bb968fC2346Edbe03c8888",
//     "0xa02e8d6fec0f376f568db5Fe42aBcFE0401066cd",
//     "0xCCba44348e644d795B8E56D39d68299C645eB2c4"
// ]

contract mutiWallet {
    mapping(address => bool) isSigner;
    mapping(uint256 => uint8) idToSigns;
    mapping(uint256 => bool) execute;
    mapping(uint256 => mapping (address => bool)) public confirms;
    uint8 public signCount;
    

    constructor(address[] memory _wallets, uint8 _signs) {
        require(_wallets.length > 0, "wallets not empty");
        require(_signs <= _wallets.length, "number of signer don't exceed input wallets total");
        for(uint i = 0; i < _wallets.length; i++) {
            isSigner[_wallets[i]] = true;
        }
        signCount = _signs;
    }
    
    function sign(address addr, uint256 _id) public {
        require(idToSigns[_id] <= signCount, "Exceeding the number of signatures");
        require(isSigner[addr], "you are not signer");
        require(confirms[_id][addr] == false, "is already signed");
        require(!execute[_id], "already execute");
        confirms[_id][addr] = true;
        idToSigns[_id] += 1;
    }

    function exceute(uint256 _id) external {
        require(idToSigns[_id] >= signCount, "More than or equal to the number of signatures");
        require(!execute[_id], "already execute");
        // do something
        execute[_id] = true;
    }

    function getSigner(address addr) external view returns(bool) {
        return isSigner[addr];
    }

    function getIdSigncount(uint256 id) external view returns(uint) {
        return idToSigns[id];
    }
}