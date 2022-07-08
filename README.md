# PriceFeed
A Chainlink DirectRequest DON smart contract


## Setup

You'll need setup a .env file or setup environment 

    RINKEBY_RPC_URL=
    PRIVATE_KEY=
    ETHERSCAN_KEY=

## Deploy

To deploy the PriceFeed contract run the following

    forge script script/Contract.s.sol:ContractScript \
                --rpc-url $RINKEBY_RPC_URL \
                --private-key $PRIVATE_KEY \
                --broadcast --verify \
                --etherscan-api-key $ETHERSCAN_KEY -vvvv
