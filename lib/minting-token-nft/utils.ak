use aiken/bytearray
use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{
  Input, Output, OutputReference, ScriptContext, Spend, Transaction, find_input,
  find_script_outputs,
}
use aiken/transaction/credential.{Script, ScriptCredential, VerificationKey}
use aiken/transaction/value.{AssetName, PolicyId, Value}

// reference Prefix
pub const refPrefix = #"000643b0"

// fraction Prefix
pub const fracPrefix = #"001bc280"

// PKH 
pub type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

// Script Hash
pub type ScriptHash =
  Hash<Blake2b_224, Script>

// Helper Functions //
pub fn make_token_names(tn) -> List<AssetName> {
  let tokenName: AssetName = tn
  let refTn = tokenName
  let fracTn = tokenName
  [refTn, fracTn]
}

pub fn fraction_token_prefix(tn) {
  let token_names = make_token_names(tn)
  let token_name_prefix =
    [refPrefix, fracPrefix]
  list.map2(token_name_prefix, token_names, fn(a, b) { bytearray.concat(a, b) })
}

pub fn compare_token_names(an: AssetName, tn: Option<ByteArray>) -> Bool {
  expect Some(tn) = tn
  an == tn
}

pub fn tx_signed_by(tx: Transaction, pkh: VerificationKeyHash) {
  list.has(tx.extra_signatories, pkh)
}
//Mục đích: Trả về đầu ra (output) tương ứng với đầu vào (input) của giao dịch hiện tại được xem xét bởi hợp đồng.
pub fn get_own_input(ctx: ScriptContext) -> Output {
  let oref = get_spend_ref(ctx)//lấy đối tượng OutputReference của đầu ra mà đầu vào của hợp đồng đã tiêu thụ.

  expect Some(input) =//Tìm đầu vào tương ứng trong danh sách đầu vào của giao dịch.
    ctx.transaction.inputs
      |> find_input(oref)

  let Input { .. } = input
  input.output//Trả về đầu ra của đầu vào đó.
}

pub fn get_spend_ref(ctx: ScriptContext) -> OutputReference {// Lấy OutputReference của đầu ra mà đầu vào của hợp đồng đã tiêu thụ.
  expect Spend(ownRef) = ctx.purpose//Kỳ vọng rằng mục đích của giao dịch là chi tiêu (Spend), sau đó trả về ownRef của Spend đó.
  ownRef
}

pub fn contains_single_token_of(value: Value, policy_id: PolicyId) -> Bool {
  //Mục đích: Kiểm tra xem giá trị (Value) có chứa một lượng duy nhất của token thuộc về chính sách (policy) và có đúng một token không.
  // kiểm tra xem giá trị của value có phù hợp với số lượng token có policy id tương ứng không
  let token_count = dict.values(value.tokens(value, policy_id))
  token_count == [1]
  //Đếm số lượng token thuộc chính sách được chỉ định trong giá trị và kiểm tra xem nó có bằng 1 hay không.
}

pub fn get_own_singleton_output(ctx: ScriptContext) -> Output {//Lấy đầu ra duy nhất của hợp đồng hiện tại.
  let script_hash = get_own_script_hash(ctx)//lấy mã hash của hợp đồng hiện tại
  expect has_own_singleton_output(ctx)
  expect Some(output) =//Tìm tất cả đầu ra trong giao dịch có mã hash tương ứng với mã hash của hợp đồng
    ctx.transaction.outputs
      |> find_script_outputs(script_hash)
      |> list.head()

  output//Trả về đầu ra đầu tiên trong danh sách đó
}

pub fn has_one_singleton_asset_less(in: Value, out: Value) -> Bool {
  //Kiểm tra xem giá trị đầu vào có một lượng duy nhất token của chính sách ít hơn giá trị đầu ra không.
  // kiểm tra xem có đủ token chi tiêu không
  expect Some(policy_id) =//Lấy chính sách đầu tiên từ giá trị đầu vào
    value.without_lovelace(in)
      |> value.policies()
      |> list.head()
  how_many_tokens(out, policy_id) == how_many_tokens(in, policy_id) - 1
  //So sánh số lượng token của chính sách trong giá trị đầu ra và giá trị đầu vào.
}

pub fn how_many_tokens(v: Value, p: PolicyId) -> Int {
  //Đếm số lượng token của một chính sách trong giá trị được chỉ định.
  expect Some(n) =
    value.tokens(v, p)//Lấy danh sách giá trị token của chính sách từ giá trị đầu vào.
      |> dict.values()
      |> list.head()
  n//Đếm số lượng token và trả về.
}

pub fn get_own_script_hash(ctx: ScriptContext) -> ScriptHash {
  //Lấy mã hash của hợp đồng hiện tại.
  let own_input = get_own_input(ctx)//để lấy đầu ra của đầu vào của hợp đồng hiện tại.
  expect ScriptCredential(script_hash) = own_input.address.payment_credential
  script_hash//Lấy mã hash từ địa chỉ thanh toán của đầu ra.
}
//: Kiểm tra xem giao dịch có duy nhất một đầu ra của hợp đồng hiện tại không.
pub fn has_own_singleton_output(ctx: ScriptContext) -> Bool {
  let script_hash = get_own_script_hash(ctx)//lấy mã hash của hợp đồng hiện tại

  let script_outputs =//Tìm tất cả đầu ra trong giao dịch có mã hash tương ứng với mã hash của hợp đồng.
    ctx.transaction.outputs
      |> find_script_outputs(script_hash)

  list.length(script_outputs) == 1//Kiểm tra xem danh sách đầu ra có đúng một phần tử không.
}