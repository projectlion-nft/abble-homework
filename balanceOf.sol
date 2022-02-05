// Klaytn IDE uses solidity 0.4.24, 0.5.6 versions.
pragma solidity >=0.4.24 <=0.5.6;

////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
library Counters {
    // overflow 방지는 당장 필요없을 듯.
    // using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value -= 1;
    }
}
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

contract NFTSimple {
////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) private _ownedTokensCount;

    function balanceOf(address owner) public view returns (uint256) {
        // 소유자 벨리데이션은 당장 필요없을 듯.
        // require(
        //     owner != address(0),
        //     "KIP17: balance query for the zero address"
        // );

        return _ownedTokensCount[owner].current();
    }
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

    string public name = "KlayLion";

    string public symbol = "KL";
    mapping (uint256 => string) public tokenURIs;
    mapping (uint256 => address) public tokenOwner;

    // 소유한 토큰 리스트
    mapping (address => uint256[]) private _ownedTokens;
    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(from == msg.sender, "from != msg.sender");
        require(from == tokenOwner[tokenId], "you are not the owner of the token");

        _removeTokenFromList(from, tokenId);
        _ownedTokens[to].push(tokenId);

        tokenOwner[tokenId] = to;

////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

        // 만약에 받는 쪽이 실행할 코드가 있는 스마트 컨트랙트이면 코드를 실행할 것
        require(
            _checkOnKIP17Received(from, to, tokenId, _data), "KIP17: transfer to non KIP17Receiver implementer"
        );
    }

    function _checkOnKIP17Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
        bool success;
        bytes memory returndata;

        if(!isContract(to)){
            return true;
        }

        (success, returndata) = to.call(
            abi.encodeWithSelector(
                _KIP17_RECEIVED,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        if(
            returndata.length != 0 && abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED
        ) {
            return true;
        }
        return false;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account)}
        return size > 0;
    }

    function _removeTokenFromList(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length-1;
        for(uint256 i=0; i<_ownedTokens[from].length; i++){
            if(tokenId == _ownedTokens[from][i]){
                _ownedTokens[from][i] = _ownedTokens[from][lastTokenIndex];
                _ownedTokens[from][lastTokenIndex] = tokenId;
                break;
            }
        }
        _ownedTokens[from].length--;
    }
    function ownedTokens(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public returns (bool) {
        tokenOwner[tokenId] = to;
        tokenURIs[tokenId] = tokenURI;

        _ownedTokens[to].push(tokenId);

////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
        _ownedTokensCount[to].increment();
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

        return true;
    }

    function setTokenUri(uint256 id, string memory uri) public {
        tokenURIs[id] = uri;
    }
}

contract NFTMarket {
////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) private _ownedTokensCount;
////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
    mapping(uint256 => address) public seller;

    function buyNFT(uint256 tokenId, address NFTAddress) public payable returns (bool) {
        address payable receiver = address(uint160(seller[tokenId]));

        // Send 0.01 KLAY at receiver
        // 10 ** 18 PEB = 1 KLAY
        // 10 ** 16 PEB = 0.01 KLAY
        // 10 ** 9 PEB = 1 ston
        receiver.transfer(10 ** 9);
        // receiver.transfer(10 ** 18);

        NFTSimple(NFTAddress).safeTransferFrom(address(this), msg.sender, tokenId, '0x00');

////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
        _ownedTokensCount[address(this)].decrement();
        _ownedTokensCount[msg.sender].increment();
///////////////////////////////////// 과제 /////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

        return true;
    }

    function onKIP17Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        seller[tokenId] = from;
        return bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"));
    }
}