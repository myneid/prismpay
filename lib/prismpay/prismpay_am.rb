require 'logger'

module ActiveMerchant
  module Billing

    class PrismPayAM < Gateway
      # gateway setup
      self.supported_countries = ['US']
      self.default_currency = 'USD'
      self.supported_cardtypes = [:visa, :master, :american_express, 
                                  :discover, :diners_club, :jcb]

      # need to support test probably

      # init
      def initialize(options = { })
        requires!(options, :login)
        @options = options
        @gateway = PrismPay::PrismPay.new(options)
        super
      end

      # Transactions 
      def check_purchase(amount, check, subid, options = {})
        # Set custom fields for financial_txn_id and account_number
        options.merge!({:custom5 => @options[:financial_txn_id]})
        options.merge!({:custom6 => @options[:account_number]})
        
        result = @gateway.ach_sale(amount, check, subid, options)
        result.active_merchant_response
      end

      def credit(amount, bank_account, subid, options = {})
        result = @gateway.ach_credit(amount, bank_account, subid, options)
        result.active_merchant_response
      end

      def check_void(identification, pp_txn_id, subid, options = {})
        result = @gateway.ach_void(identification, pp_txn_id, subid, options)
        result.active_merchant_response
      end

      def check_refund(amount, identification, pp_txn_id, subid, options = {})
        result = @gateway.ach_refund(amount, identification, pp_txn_id, subid, options)
        result.active_merchant_response
      end

      def check_consumer_disbursement(amount, check, subid, options = {})
        result = @gateway.ext_ach_consumer_disbursement(amount, check, subid, options)
        result.active_merchant_response
      end

      def check_verify(check, options = {})
        result = @gateway.ach_verify(check, options)
        result.active_merchant_response
      end

      def profile_sale(amount, profile_id, last_four, subid, options = {})
        # Set custom fields for financial_txn_id and account_number
        options.merge!({:custom5 => @options[:financial_txn_id]})
        options.merge!({:custom6 => @options[:account_number]})
        
        result = @gateway.profile_sale(amount, profile_id, last_four, subid, options)
        result.active_merchant_response
      end

      def profile_credit(amount, profile_id, last_four, subid, options = {})
        result = @gateway.profile_credit(amount, profile_id, last_four, subid, options)
        result.active_merchant_response
      end

      def purchase(amount, creditcard, subid, options = { })
        result = @gateway.cc_purchase(amount, creditcard, subid, options)
        result.active_merchant_response
      end

      def authorize(amount, creditcard, subid, options ={ })
        result = @gateway.cc_authorize(amount, creditcard, subid, options)
        result.active_merchant_response
      end

      def capture(amount, identification, pp_id, options = {})
        result = @gateway.cc_capture(amount, identification, pp_id, options)
        result.active_merchant_response
      end

      def void(amount, identification, pp_txn_id, subid, options = {})
        result = @gateway.cc_void(amount, identification, pp_txn_id, subid, options)
        result.active_merchant_response
      end

      def refund(amount, identification, pp_txn_id, subid, options = {})
        result = @gateway.credit(amount, identification, pp_txn_id, subid, options)
        result.active_merchant_response
      end
    end

  end
end
