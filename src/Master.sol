// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/openzeppelin/token/SafeERC20.sol";
import "./interfaces/ICentralRegistry.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IProxy.sol";
import "./LeveragedNFT.sol";
import "./interfaces/IFactory.sol";

contract Master {

    error ImplementationNotFound();
    error InvalidPositionType();
    error InvalidMarginType();

    using SafeERC20 for IERC20;

    ICentralRegistry public centralRegistry;
    IFactory public factory;

    enum PositionType {
        LONG,
        SHORT
    }

    enum MarginType {
        QUOTE,
        BASE
    }


    constructor() {
        
    }

   function createPosition(   
        string calldata _implementation,
        address _quoteToken,
        address _baseToken,
        uint256 _collateralAmount,
        uint256 _flashLoanAmount,
        uint256 _minTokenOut,
        uint256 _moneyMarketBorrowAmount
    ) public returns(uint256 tokenId, address proxyAddress) {

        ICentralRegistry.Implementation memory implementation_ = centralRegistry.implementations(_implementation);
        address implementationAddress = implementation_.implementation;
        IMaster.PositionType positionType_ = implementation_.positionType;
        IMaster.MarginType marginType_ = implementation_.marginType;

        if (implementationAddress == address(0)) revert ImplementationNotFound();

        IERC20 quoteToken = IERC20(_quoteToken);

        // create a long position
        if (positionType_ == IMaster.PositionType.LONG) {  

            // create long position with quote token as margin
            if (marginType_ == IMaster.MarginType.QUOTE) {

                quoteToken.safeTransferFrom(msg.sender, address(this), _collateralAmount);

                // deploy a new proxy contract, mint a new NFT
                (tokenId, proxyAddress) = factory.createProxy(msg.sender, implementationAddress, _quoteToken, _baseToken);

                quoteToken.safeIncreaseAllowance(proxyAddress, _collateralAmount);

                // add to the position
                IProxy(proxyAddress).addToPosition(_collateralAmount, _flashLoanAmount, _minTokenOut, _moneyMarketBorrowAmount);
            } 
            // create long position with base token as margin
            else if (marginType_ == IMaster.MarginType.BASE) {

            }
            else {
                revert InvalidMarginType();
            }
        }
        // create short position
        else if (positionType_ == IMaster.PositionType.SHORT) {
        }
    
    }


    function addToPosition(uint256 _tokenId) public {

    }

    function removeFromPosition(uint256 _tokenId) public {

    }

    function closePosition(uint256 _tokenId) public {

    }

}