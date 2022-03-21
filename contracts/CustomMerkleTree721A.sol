// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Helpers/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ERC721ACustom is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum MintStatus {
        CLOSED,
        PRESALE_LIVE,
        PUBLIC_SALE_LIVE
    }
    string public baseExtension = ".json";
    string public _baseTokenURI;
    uint256 public constant SUPPLY_MAX = 10000;
    uint256 public constant PRESALE_MAX = 2000;
    uint256 public constant RESERVE_MAX = 100;
    uint256 public constant PRICE = 0.06 ether;
    uint256 public constant MAX_MINT_PRESALE = 2;
    uint256 public constant MAX_MINT_PER_WALLET = 3;
    uint256 public reservedTeamTokens;

    // Mint Status variable:
    MintStatus public state;

    // Merklet Root Hash for presale list:
    bytes32 public merkleRootHash;

    // Only permit External Owned Accounts to interact with respective functions
    modifier callerIsEOA() {
        require(
            msg.sender == tx.origin,
            "Custom: Contract Interaction Not Permitted"
        );
        _;
    }

    constructor(string memory _baseUri) ERC721A("Custom", "CUSTOM") {
        _baseTokenURI = _baseUri;

        // Mint and burn tokenId 0:
        _safeMint(address(this), 1);
        _burn(0);
    }

    function reserveTeamTokens(address _to, uint256 _quantity)
        external
        onlyOwner
    {
        require(
            reservedTeamTokens + _quantity <= RESERVE_MAX,
            "Custom: Team Tokens Already Minted"
        );
        reservedTeamTokens += _quantity;
        _safeMint(_to, _quantity);
    }

    function mint(uint256 _quantity) external payable callerIsEOA {
        require(
            state == MintStatus.PUBLIC_SALE_LIVE,
            "Custom: Public Sale Not Live"
        );
        require(
            totalSupply() + _quantity <= SUPPLY_MAX,
            "Custom: Max Supply Exceeded"
        );
        require(
            quantityMinted(msg.sender) + _quantity <= MAX_MINT_PER_WALLET,
            "Custom: Mint Quantity Per Wallet Exceeded"
        );

        _safeMint(msg.sender, _quantity);
        // Refund if excess is returned AND checks for enough balance sent over:
        refundIfOver(PRICE * _quantity);
    }

    function presaleMint(bytes32[] calldata _merkleProof, uint256 _quantity)
        external
        payable
        callerIsEOA
    {
        require(state == MintStatus.PRESALE_LIVE, "Custom: Presale Not Live");
        require(
            totalSupply() + _quantity <= SUPPLY_MAX,
            "Custom: Max Supply Exceeded"
        );
        require(_quantity <= MAX_MINT_PRESALE, "Custom: ");
        require(
            quantityMinted(msg.sender) + _quantity <= MAX_MINT_PER_WALLET,
            "Custom: Mint Quantity Per Wallet Exceeded"
        );

        // Querying Address via Merkle Tree Construction from Whitelisted Addresses
        bytes32 merkleLeaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRootHash, merkleLeaf),
            "Custom: Proof Invalid, Not on Presale List"
        );

        _safeMint(msg.sender, _quantity);
        refundIfOver(PRICE * _quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Custom: Insufficient ETH for mint");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setSaleState(MintStatus _state) external onlyOwner {
        state = _state;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRootHash = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRootHash;
    }

    // Retrieve quantity minted by a particular address -> balanceOf()
    function quantityMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    // Retrieve ownership information on a tokenId:
    function getOwnershipInfo(uint256 _tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        // Return tuple of ownership data from ERC721A:
        return _ownershipOf(_tokenId);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
