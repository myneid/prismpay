module PrismPay
  class PrismCreditResponse
    # this class will be responsible for handling the SOAP response
    def initialize(prism_savon_result_obj)

      # keys from successful response were :status, :result, :historyid,
      # :orderid, :refcode, :authcode, :total, :merchantordernumber, 
      # :transdate, :paytype, :duplicate
      @result = prism_savon_result_obj
    end

    def soap_response
      @result
    end

    def active_merchant_response
      params = options = { }

      # options[:avs_result]
      # options[:cvv_result]
      message = @result.body[:multi_ref][:status]

      if @result.body[:multi_ref][:status] =~ /approved/i
        success = true
      else
        decl = parse_auth(@result.body[:multi_ref][:authcode])
        message = "#{decl[:result]}: #{decl[:info]}"
        success = false
      end

      options[:authorization] = @result.body[:multi_ref][:historyid]
      params[:order_id] = @result.body[:multi_ref][:orderid]

      ActiveMerchant::Billing::Response.new(success, message, 
                                            params, options)
    end

    def parse_auth(authstr)
      # parses the authorization specification string returned by prismpay

      trasaction_types = %w(SALE, AVSALE, AUTH, AVSAUTH, POST, AVSPOST, 
                        VOICEPOST, VOID, CREDIT)
      
      approval_fields = [:transaction_type, :auth_code, :ref_number, 
                         :batch_number, :transaction_id, :avs_code, 
                         :auth_net_message, :cvv_code, :partial_auth]

      decline_fields = [:result, :decline_code, :info]

      # first digit of the decline code has these meanings
      decline_code_map = {
        '0' => "Authorizing network declined the transaction",
        '1' => "Gateway declined the transaction",
        '2' => "Authorizing network returned an error, forcing a decline",
        '3' => "Gateway returned an error, forcing a decline"
      }

      # map cvv and avs response codes to meanings
      avs_map = { 'A'=> "Street addresses matches, but the ZIP code does " +
        "not. The first five numerical characters contained in the " +
        "address match. However, the ZIP code does not match.",

        'E' => "Ineligible transaction. The card issuing institution is " +
        "not supporting AVS on the card in question. N Neither address " +
        "nor ZIP matches. The first five numerical characters contained " +
        "in the address do not match, and the ZIP code does not match. ",

        'R'=> "Retry (system unavailable or timed out).",

        'S' => "Card type not supported. The card type for this " +
        "transaction is not supported by AVS. AVS can verify " +
        "addresses for Visa cards, MasterCard, proprietary cards, and " +
        "private label transactions.",

        'U' => "Address information unavailable. The address information "+
        "was not available at the issuer.",

        'W' => "9 digit ZIP code match, address does not. The nine digit " +
        "ZIP code matches that stored at the issuer. However, the first " +
        "five numerical characters contained in the address do not match.",

        'X' => "Exact match (9 digit zip and address) Both the nine digit " +
        "postal ZIP code as well as the first five numerical characters " +
        "contained in the address match.",

        'Y' => "Address and 5 digits zip match. Both the five digit " +
        "postal ZIP code as well as the first five numerical characters " +
        "contained in the address match.",

        'Z' => "5 digit ZIP matches, but the address does not. The five " +
        "digit postal ZIP code matches that stored at the VIC or card " +
        "issuer's center. However, the first five numerical characters " +
        "contained in the address do not match.",

        'B' => "Street address matches for international transaction. " +
        "Postal Code not verified due to incompatible formats.",

        'C' => "Street address and Postal Code not verified for " +
        "international transaction due to incompatible format.",

        'D' => "Street address and Postal Code match for international " +
        "transaction.",

        'P' => "Postal Code match for international transaction. Street " +
        "address not verified due to incompatible formats."
      } # end avs_map

      cvv_map = { " "=> "cvv not requested", 
        'M' => "cvv Match",
        'N' => "cvv not matched", 
        'P' => "Not processed", 
        'S' => "cvv should be on card, but it indicated the value not present",
        'U' => "Issuer doesn't support cvv2",
        'X' => "Service provider did not respond"
      }
      
      hash = {}
      fields = authstr.split /:/
      if fields.size > 3          # approval
        approval_fields.each_index{|x| hash[approval_fields[x]] = fields[x]}
      else 
        decline_fields.each_index{|x| hash[decline_fields[x]] = fields[x] }
      end
      hash
    end

  end # PrismCreditResponse
end #module PrismPay
