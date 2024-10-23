use nftcourse/types.{Bid, VerificationKeyHash, Vote,Nft,ValueOfBid, POSIXTime}
use aiken/transaction/value.{PolicyId}
use aiken/transaction.{InlineDatum, Mint, Output, ScriptContext,  Transaction, ValidityRange}
use aiken/list
use aiken/dict.{Dict}
pub fn kiemTraNguoiDoDaVoteChua(voters: Vote, policyId: PolicyId, currentVoter: VerificationKeyHash) -> Bool{// điều kiện để vote là người đó chưa vote
    let listVoters=
    getVoterOfPolicyId(policyId, voters)
    listVoters.has_key(currentVoter)
}// done 1
pub fn kiemTraSoDuToiThieu(outputs: List<Output>, conditionOfAmount: Int)-> Bool{// amount là số dư tối thiểu của ví thỏa mãn 1 ràng buộc cho trước không?
// vì là đang kiểm tra số dư nên cần phải biết được tổng input có lượng tiền thỏa mãn không chính vì tổng tiền đầu ra bằng tổng tiền vào nên thông qua tất cả outputs chúng ta sẽ tính được tổng số dư trong ví
    // phải tìm được output tương ứng với address
    // tìm input của người đó
    totalAmout(outputs)>= conditionOfAmount?
}//dome 2
pub fn kiemTraXemTienVoteThoaMan(amountvote: Int, minVote: Int)->Bool{// kiểm tra xem lượng tiền người đó vote có thỏa mãn lượng tiền tối thiểu quy định không
    amoutVote>=minVote?
}//done 3
pub fn kiemTraXemSoDuCoLonHonLuongTienVoteKo(outputs: List<Output>, amountVoteamount: Int){
    totalAmout(outputs)>=amountVoteamount?
}//done 4
pub fn check_amount(outputs: List<Output>, price: Int) -> Bool {
  // With the amount in the output being greater than the amount passed in from the parameter
  lovelace_of(output.value) >= price?
}
pub fn kiemTraRangBuocVeGia(price: Int, amount: Int, lastPrice: Int)-> Bool{// amount là bội số
    (price - lastPrice) % amount !=0
}
pub fn kiemtrakyten(tx: Transaction, pkh: VerificationKeyHash){
    list.has(tx.extra_signatories,pkh)?
}//done 5
pub fn must_start_after(range: ValidityRange, lock_expiration_time: POSIXTime) {
  when range.lower_bound.bound_type is {
    Finite(tx_earliest_time) -> lock_expiration_time <= tx_earliest_time
    _ -> False
  }
}//done 6

pub fn totalAmout(outputs: List<Output>)-> Int{
    list.foldl(outputs, 0, fn(output,total){lovelace_of(output.value)+total})
}
pub fn getValueOfBid(policy_id: PolicyId, bid: Bid)-> Option<ValueOfBid>{
    bib.get(key: policy_id)
}
pub fn getVoterOfPolicyId(policyId: PolicyId, voters: Vote)-> Option<Dict<VerificationKeyHash,Int>>{
    voters.get(key: policyId)
}
