// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Payments} from "./utils/Payments.sol";

error ObsoleteExtension(uint16);
error NoRequestMade(uint256);
error WrongFulfillAddress();
error ExtenstionNotExists(uint16);
error InitAlreadyReceived();

contract Cardpool is ERC1155, VRFConsumerBaseV2Plus, Payments {
    uint256 private _subId;
    bytes32 private _keyHash;
    uint16 private _confirmations;
    uint32 private _callbackGasLimit;
    uint256 _packPrice;
    uint256 _initialSetPrice;
    Card[] _initialSet;

    struct MintRequest {
        address minter;
        uint32 extension;
        bool exists;
    }

    struct ExtensionData {
        uint8 commonCount;
        uint8 rareCount;
        uint8 epicCount;
        bool exists;
        bool obsolete;
    }

    struct UserCards {
        bool initReceived;
        uint32[] ids;
        mapping(uint32 => uint256) cards;
    }

    struct Card {
        uint32 id;
        uint256 quantity;
    }

    mapping(uint256 => MintRequest) ongoingRequests;
    mapping(address => UserCards) cardsPerUser;
    mapping(uint32 => ExtensionData) extensions;

    constructor(
        address token,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subId,
        uint16 confirmations,
        uint32 callbackGasLimit,
        uint256 packPrice,
        uint256 initialSetPrice,
        string memory uri
    ) VRFConsumerBaseV2Plus(vrfCoordinator) Payments(token) ERC1155(uri) {
        _keyHash = keyHash;
        _subId = subId;
        _confirmations = confirmations;
        _callbackGasLimit = callbackGasLimit;
        _packPrice = packPrice;
        _initialSetPrice = initialSetPrice;
    }

    function mintPack(
        uint16 extensionId,
        address to,
        bool native
    ) public returns (uint256) {
        ExtensionData memory extension = extensions[extensionId];
        if (!extension.exists) {
            revert ExtenstionNotExists(extensionId);
        }
        if (extension.obsolete) {
            revert ObsoleteExtension(extensionId);
        }

        processPayment(_packPrice, msg.sender);

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: _keyHash,
                subId: _subId,
                requestConfirmations: _confirmations,
                callbackGasLimit: _callbackGasLimit,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: native})
                )
            })
        );
        ongoingRequests[requestId] = MintRequest(to, extensionId, true);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal virtual override {
        if (msg.sender != address(s_vrfCoordinator)) {
            revert WrongFulfillAddress();
        }
        MintRequest storage request = ongoingRequests[requestId];
        if (!request.exists) {
            revert NoRequestMade(requestId);
        }
        uint32 extensionId = request.extension;
        ExtensionData storage extension = extensions[extensionId];

        uint256 number = randomWords[0];
        uint32[] memory randoms = splitUint256ToUint32Array(number);

        // first is a rare
        uint32 rare = randoms[0];

        uint32 rarityMask = 7;

        uint32 rarity = rare & rarityMask;
        rare = rare >> 3;
        uint32 card;

        if (rarity == 0) {
            // epic
            uint32 id = uint32(rare % extension.epicCount);
            card = createMythicCard(id);
        } else {
            // rare
            uint32 id = uint32(rare % extension.rareCount);
            card = createRareCard(id);
        }

        uint32[] memory cards = new uint32[](8);
        cards[0] = card;

        for (uint i = 1; i < randoms.length; i++) {
            uint32 card = uint32(randoms[i] % extension.commonCount);
            cards[i] = card;
        }

        uint256[] memory cardsERC1155 = new uint256[](8);
        uint256[] memory values = new uint256[](8);

        for (uint i = 0; i < cards.length; i++) {
            uint32 fullCard = addExtension(cards[i], extensionId);
            cardsERC1155[i] = fullCard;
            values[i] = 1;
        }

        _mintBatch(request.minter, cardsERC1155, values, "");
    }

    function createMythicCard(uint32 id) internal pure returns (uint32) {
        return (2 << 8) + id;
    }

    function createRareCard(uint32 id) internal pure returns (uint32) {
        return (1 << 8) + id;
    }

    function addExtension(
        uint32 id,
        uint32 extension
    ) internal pure returns (uint32) {
        return (extension << 16) + id;
    }

    function mintInitial(address to) public {
        UserCards storage userCards = cardsPerUser[to];
        if (userCards.initReceived) {
            revert InitAlreadyReceived();
        }
        processPayment(_initialSetPrice, msg.sender);
        uint256[] memory mintIds = new uint256[](_initialSet.length);
        uint256[] memory mintQuantities = new uint256[](_initialSet.length);
        for (uint i = 0; i < _initialSet.length; i++) {
            Card storage card = _initialSet[i];
            mintIds[i] = card.id;
            mintQuantities[i] = card.quantity;
        }
        _mintBatch(to, mintIds, mintQuantities, "");
        userCards.initReceived = true;
    }

    function burn(uint32 id, uint256 amount) public {
        super._burn(msg.sender, uint256(id), amount);
    }

    function burnBatch(uint256[] memory ids, uint256[] memory amounts) public {
        super._burnBatch(msg.sender, ids, amounts);
    }

    // TODO: override transfers to update local storages

    function retireExtension(uint16 extension) public onlyOwner {
        extensions[extension].obsolete = true;
    }

    function rollbackRetirement(uint16 extension) public onlyOwner {
        extensions[extension].obsolete = false;
    }

    function addExtenstion(
        uint16 extension,
        uint8 commonCount,
        uint8 rareCount,
        uint8 mythicCount
    ) public onlyOwner {
        extensions[extension] = ExtensionData(
            commonCount,
            rareCount,
            mythicCount,
            true,
            false
        );
    }

    function splitUint256ToUint32Array(
        uint256 value
    ) public pure returns (uint32[] memory) {
        uint32[] memory result = new uint32[](8); // 256 bits / 32 bits = 8 elements

        for (uint i = 0; i < 8; i++) {
            // Extract 32 bits starting from the least significant bits
            result[7 - i] = uint32(value >> (i * 32));
        }

        return result;
    }

    function userCards(address user) public view returns (Card[] memory) {
        UserCards storage cardset = cardsPerUser[user];
        Card[] memory result = new Card[](cardset.ids.length);
        for (uint i = 0; i < cardset.ids.length; i++) {
            uint32 id = cardset.ids[i];
            uint256 quantity = cardset.cards[id];
            result[i] = Card(id, quantity);
        }

        return result;
    }

    function updatePackPrice(uint256 newPrice) public onlyOwner {
        _packPrice = newPrice;
    }

    function updateInitialSetPrice(uint256 newPrice) public onlyOwner {
        _initialSetPrice = newPrice;
    }

    function updateInitialSet(Card[] calldata newSet) public onlyOwner {
        for (uint i = 0; i < newSet.length; i++) {
            _initialSet.push(newSet[i]);
        }
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override {
        super._update(from, to, ids, values);
        if (to != address(0)) {
            UserCards storage cardsetTo = cardsPerUser[to];
            for (uint i = 0; i < ids.length; i++) {
                uint32 id = uint32(ids[i]);
                uint256 quantityPre = cardsetTo.cards[id];
                if (quantityPre == 0) {
                    cardsetTo.ids.push(id);
                }
                cardsetTo.cards[id] = quantityPre + values[i];
            }
        }
        if (from != address(0)) {
            UserCards storage cardsetFrom = cardsPerUser[to];
            for (uint i = 0; i < ids.length; i++) {
                uint32 id = uint32(ids[i]);
                uint256 quantityPre = cardsetFrom.cards[id];
                if (quantityPre == values[i]) {
                    for (uint256 j = 0; i < cardsetFrom.ids.length; i++) {
                        if (cardsetFrom.ids[j] == id) {
                            // Move the last element to the position of element to remove
                            cardsetFrom.ids[j] = cardsetFrom.ids[
                                cardsetFrom.ids.length - 1
                            ];
                            // Remove the last element
                            cardsetFrom.ids.pop();
                        }
                    }
                }
                cardsetFrom.cards[id] = quantityPre - values[i];
            }
        }
    }

    // TODO: override uri()
}
