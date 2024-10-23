use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value.{AssetName, PolicyId, lovelace_of, quantity_of}
use aiken/dict.{Dict}

pub type POSIXTime =
  Int
pub type VerificationKeyHash = Hash<Blake2b_224, VerificationKey>
pub type Vote =
    Dict<PolicyId, Dict<VerificationKeyHash, Int>>

pub type Nft =
    Dict<PolicyId, VerificationKeyHash>

pub type ValueOfBid{
    author: VerificationKeyHash, // Người tạo NFT
    poster: VerificationKeyHash, // người ra giá 
    winer: VerificationKeyHash, // người đang thắng
    bidder: VerificationKeyHash, // người đang sở hữu NFT
    curentMoney: Int, // giá hiện tại đang đấu giá
    //bidMoney: Int, // giá đấu giá lên
    minAmount: Int, // số dư tối thiểu của ví 
   // currentTime: PosixTime,// thời gian hiện tại người đang đưa giá lên
    //lastTime: PosixTime // thời gian người đưa giá lên trước đó
}
pub type Bid =
    Dict<PolicyId, ValueOfBid>
