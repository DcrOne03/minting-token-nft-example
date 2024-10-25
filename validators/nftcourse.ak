use aiken/bytearray
use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{InlineDatum, Mint, ScriptContext,  Transaction}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value
use nftcourse/okapi as ok
// reference Prefix
const refPrefix = #"000643b0"// tiền tố của loại tài sản ref

// fraction Prefix
const fracPrefix = #"001bc280"//tiền tố của loại tài sản frac

// PKH 
type VerificationKeyHash =//Hash của khóa xác thực
  Hash<Blake2b_224, VerificationKey>

// type TokenDatum{// datum của token
//     name: ByteArray,
//     image: ByteArray,
//     mediaType: ByteArray,
// }
type TokenDatum {
  a: Int,
}
type DisDatum{// datum của Distro (liên quan đến quá trình phân phối theo như mình hiểu đây là quá trình đốt tài sản)
    a:Int,
}
type MintAction{// đây là type để mint
    a: Int,// redeemer value
    b: Int,// numner of fractionalies tokens
    tn: ByteArray// token name
}

// Helper Functions //
  //asset name
fn make_token_names(tn) -> List<value.AssetName>{// hàm tạo tên tài sản trả về 1 list các tên tài sản
    let tokeName: value.AssetName = tn// chuyển đổi kiểu token name là kiểu AssetName
    let refTn = tokeName // gán tham chiếu của token name là token name
    let fracTn = tokeName //gán frac của token name là token name
    //return
    [refTn, fracTn]
}
fn fration_token_prefix(tn){// hàm này dùng để tạo tiền tố cho tên tài sản phân đoạn
    let token_names= make_token_names(tn)
    let token_name_prefix = [refPrefix, fracPrefix]// khởi tạo 1 mảng chứa 2 tiền tố của tài sản
    list.map2(// nối 2 chuỗi tạo ra tài sản
        token_name_prefix,
        token_names,
        fn(a,b){bytearray.concat(a,b)}// token name của 2 thằng là giống nhau nhưng sau đó sẽ khác nhau tiền tố
    )
}

fn compare_token_names(an: value.AssetName, tn: Option<ByteArray>) -> Bool{//Option<T> là một kiểu dữ liệu đặc biệt, cung cấp một cách để biểu diễn giá trị có thể có hoặc không
    
    expect Some(tn) = tn // được sử dụng để kiểm tra một điều kiện. Nếu điều kiện không đúng, nó sẽ kết thúc chương trình với một thông báo lỗi.
    // là một cách viết ngắn gọn cho việc kiểm tra xem tn có giá trị không nil hay không. Nếu tn là Some (có giá trị), thì nó sẽ gán giá trị đó cho tn. Nếu tn là None (nil), chương trình sẽ kết thúc và thông báo lỗi.
    an==tn
}
fn tx_signed_by(tx: Transaction, pkh: VerificationKeyHash){// kiểm tra kí
    list.has(tx.extra_signatories,pkh)
}
validator(owner: VerificationKeyHash){//locking Validator
    //Token Minting Policy
    fn mint(r: MintAction,c: ScriptContext)-> Bool{
        let ScriptContext { transaction, purpose }= c// lấy ra các biến transaction,purpore từ ScriptContext

        expect Mint(policy_id) = purpose// lấy Policy_id từ mục đích giao dịch mint(purpose)
        
        let Transaction{mint, outputs, ..}=transaction// lấy một số dữ liệu mint, output,extra... từ transaction

        expect [(ref_asset_name, ref_amount), (frac_asset_name, frac_amount)]= // trả về 1 mảng gồm 2 phần dict gồm key_name và amount
            mint
            |> value.from_minted_value
            |>value.tokens(policy_id)
            |>dict.to_list()

        expect tx_signed_by(transaction,owner)     //tx signed by owner
        when r.a is{// nếu mục tiêu của action là 1
            1-> { 
                // mint 1x 100 Prefix Token// thực hiện mint 1 token với tên là 100 prefixtoken
                //sent to loking Validator or sent to output
                // hàm này kiểm tra xem có ít nhất 1 tài sản trong output có thỏa mãn các điều kiện không
                expect list.any(outputs,fn(output){//Hàm list.any trong Cadence là một hàm dùng để kiểm tra xem có phần tử nào trong danh sách thỏa mãn điều kiện cho trước không
                    // Hàm này kiểm tra xem có ít nhất một phần tử trong danh sách outputs thoả mãn điều kiện được xác định bởi hàm đầu vào (fn(output)). Nếu có ít nhất một phần tử thỏa mãn điều kiện, thì list.any trả về true, ngược lại trả về false.
                    // kiểm tra xem trong các outputs đầu vào có thỏa mãn được các điều kiện được xác định trong hàm fn()
                    expect InlineDatum(datum)= output.datum //expect InlineDatum(datum) = output.datum: Điều này khai báo một biến datum và gán giá trị của output.datum cho nó. InlineDatum là một kiểu dữ liệu, và hàm này kiểm tra xem giá trị của output.datum có phải là một InlineDatum hay không. Nếu không phải, sẽ xảy ra lỗi.
                    // gán output.datum thành datum và kiểm tra xem nó có phải kiểu InlineDatum không
                    expect datum: TokenDatum = datum//expect datum: TokenDatum = datum: Tương tự, điều này kiểm tra xem giá trị của datum có phải là một TokenDatum hay không. Nếu không phải, sẽ xảy ra lỗi.
                    value.quantity_of(output.value, policy_id, ref_asset_name)== 1// kiểm tra đầu ra output.value có số lượng tài sản có bằng 1 hay không với policyid và refassetname cho trước
                    //alue.quantity_of(output.value, policy_id, ref_asset_name) == 1: Điều kiện này kiểm tra xem giá trị của output.value có số lượng token của tài sản có tên là ref_asset_name và thuộc chính sách có policy_id có bằng 1 hay không. Nếu điều kiện này không đúng, hàm trả về false, ngược lại trả về true.
                })//Tổng cộng, đoạn mã trên đang kiểm tra xem trong danh sách outputs, có ít nhất một phần tử nào đó mà output.datum là một InlineDatum kiểu TokenDatum và output.value chứa đúng một token của tài sản có tên là ref_asset_name và thuộc chính sách có policy_id không.
                // mint 1000x 444 Prefix Token
                // send to distribution Validator or delivered to one output
                expect list.any(outputs, fn(output){
                    value.quantity_of(output.value,policy_id,frac_asset_name)==1000
                    // might want to mint a different amount of fracs /NFT
                })
                //enforce token name
                let token_name_list = fration_token_prefix(r.tn)// dùng hàm fration_token_prefix để tạo tên tài sản( hàm kia dùng để nối tiền tố tài sản và tên tài sản)

                let ref_tn_check = // kiểm tra tên tài sản ref
                    compare_token_names(ref_asset_name,list.at(token_name_list,0))
                //compare ref name to token name list
                let frac_tn_check = // kiểm tra tên tài sản frac
                    compare_token_names(frac_asset_name,list.at(token_name_list,1))
                //compare frac names to token name list
                // tn = token_name
                ref_amount ==1 && frac_amount == r.b && ref_tn_check && frac_tn_check
            }

            // tx signed by owner
            _-> {
                let token_name_list = fration_token_prefix(r.tn)

                let ref_tn_check = 
                    compare_token_names(ref_asset_name,list.at(token_name_list,0))
                //compare ref name to token name list
                let frac_tn_check = 
                    compare_token_names(frac_asset_name,list.at(token_name_list,1))
                //compare frac names to token name list
                // tn = token_name
                ref_amount ==-1 && frac_amount == -r.b && ref_tn_check && frac_tn_check
            }
            // burn -1 RefToken && -1000 FracToken
            //tx signed by owner
        }
    }
}
// Quy trình chương trình ở đây là một hợp đồng thông minh trong ngôn ngữ lập trình Cadence, sử dụng để thực hiện các hành động liên quan đến việc "mint" (đúc tạo) và "burn" (đốt cháy) các loại tài sản token. Dưới đây là mô tả chi tiết cho mỗi phần của chương trình:

// Khi r.a là 1 (Minting Action):

// Thực hiện mint 1 token với tên là "100 Prefix Token". Token này có thể được gửi đến Locking Validator hoặc được gửi đến đầu ra của giao dịch (output).

// Sử dụng hàm list.any để kiểm tra xem có ít nhất một đầu ra nào đó trong danh sách outputs thỏa mãn điều kiện được xác định bởi hàm fn(output). Trong trường hợp này, điều kiện đó là:

// InlineDatum(datum) = output.datum: Kiểm tra xem giá trị của output.datum có phải là một InlineDatum không.
// datum: TokenDatum = datum: Kiểm tra xem datum có phải là kiểu TokenDatum không.
// value.quantity_of(output.value, policy_id, ref_asset_name) == 1: Kiểm tra xem giá trị của output.value có số lượng token của tài sản có tên là ref_asset_name và thuộc chính sách có policy_id bằng 1 hay không.
// Thực hiện mint 1000 token với tên là "444 Prefix Token". Token này có thể được gửi đến Distribution Validator hoặc được gửi đến một đầu ra của giao dịch.

// Sử dụng hàm list.any để kiểm tra xem có ít nhất một đầu ra nào đó trong danh sách outputs thỏa mãn điều kiện: value.quantity_of(output.value, policy_id, frac_asset_name) == 1000.

// Sử dụng hàm fration_token_prefix(r.tn) để tạo danh sách các tên tài sản:

// Tên tài sản đầu tiên (ref_asset_name) được so sánh với phần tử đầu tiên của danh sách token_name_list.
// Tên tài sản thứ hai (frac_asset_name) được so sánh với phần tử thứ hai của danh sách token_name_list.
// Kiểm tra các điều kiện sau:

// ref_amount == 1: Số lượng token của tài sản có tên là ref_asset_name phải bằng 1.
// frac_amount == r.b: Số lượng token của tài sản có tên là frac_asset_name phải bằng giá trị của r.b.
// ref_tn_check && frac_tn_check: Cả hai kiểm tra tên tài sản (ref_asset_name và frac_asset_name) phải đúng.
// Khi r.a không phải là 1 (Hành động khác):

// Sử dụng hàm fration_token_prefix(r.tn) để tạo danh sách các tên tài sản tương tự như trên.

// Kiểm tra các điều kiện sau:

// ref_amount == -1: Số lượng token của tài sản có tên là ref_asset_name phải bằng -1.
// frac_amount == -r.b: Số lượng token của tài sản có tên là frac_asset_name phải bằng giá trị đối của r.b.
// ref_tn_check && frac_tn_check: Cả hai kiểm tra tên tài sản (ref_asset_name và frac_asset_name) phải đúng.
// Hành động này có thể đại diện cho việc "burn" (đốt cháy) -1 RefToken và -1000 FracToken, và giao dịch phải được ký bởi chủ sở hữu (owner).
// các bước để mint tài sản:
// b1: Khai báo lấy dữ liệu từ mô tả giao dịch, lấy các thông số của giao dịch, bao gồm mục đích, các thông số của giao dịch như đầu ra, chữ kí, tham số mint(các thông tin của mint?)
// b2: lấy ra tên tài sản của tài sản muốn mint, và kí hiệu mint(amount của loại tài sản ví dụ ref là 1 còn frac là 1000)// thông số mint là thông số được lấy từ giao dịch
// b3: Kiểm tra kí
//b4:khớp mẫu thông điệp của action 
    //nếu là 1 thì thực hiện xác thực một số các logic:
        //-- kiểm tra xem đầu ra giao dịch có đáp ứng được 1 số điều kiện không (điều kiện của tài sản mint bao gồm tên,policyid,số lượng tài sản)// tức là lấy tài sản muốn mint
        //-- Tương tự đối với hai loại tài sản ref và frac
        //-- Thực hiện kiểm tra về tên, so sánh tên, kí hiện Amount
    // nếu không phải 1 thì thực hiện một số logic:

type LockAction{
    a: Int,
    b: Int
}
//Ref Token Locking Validator
validator(owner: VerificationKeyHash, cs: value.PolicyId) {
  fn lock(d: TokenDatum, r: LockAction, c: ScriptContext) -> Bool {
    when r.a is {
       1 -> True
       //{
    //     let out = ok.get_own_singleton_output(c)
    //     ok.contains_single_token_of(out.value, cs) && tx_signed_by(
    //       c.transaction,
    //       owner,
    //     )
    //   }
      _ -> True 
      //tx_signed_by(c.transaction, owner)
    }
  }
}
type DisAction{
    a: Int,
    b: Int
}
//Distribution Validator// giai dot tai san
validator(owner: VerificationKeyHash){
    fn distro(d: DisDatum, r: DisAction, c: ScriptContext) -> Bool {
        when r.a is{
            1 -> True
    //         {
    //             let out = ok.get_own_singleton_output(c)
    //             let in = ok.get_own_input(c)

    //             ok.has_one_singleton_asset_less(in.value, out.value)
    //   }
            // has one output
            // has one asset less
            _ -> True
            //tx_signed_by(c.transaction, owner)
            //tx signed by "Owner"
        }
    }
}
//done