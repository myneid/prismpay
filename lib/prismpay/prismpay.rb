#require 'logger'

module PrismPay

  class PrismPay 
    # this class will manage the connection to the gateway and handle
    # transactions

    # WSDL = "https://trans.myprismpay.com/MPWeb/services/TransactionService?wsdl"
    WSDL = File.expand_path("../TransactionService.xml", __FILE__)

    ACH_CHECK_ACCT_TYPE = {"checking" => 1, "savings" => 2}
    ACH_SEC_CODES = %w(POP, ARC, TEL, PPD, ICL, RCK, BOC, CCDN)

    attr_accessor :acctid, :password
    attr_reader :client

    def initialize(options = {})
     # logger = Logger.new('c:/prismpay/calls.log', 'daily')
      #logger.level = Logger::DEBUG
      
     # Savon.configure do |config|
     #   config.logger = logger
    #  end
      
      merchant_info = options
      merchant_info.merge!({:login => 'TEST0'}) unless merchant_info[:login]

      if merchant_info.respond_to?("has_key?")
        @acctid = merchant_info[:login] if merchant_info.has_key?(:login)
        @password = merchant_info[:password] if merchant_info.has_key?(:password)
      end

      #@client = Savon::Client.new(WSDL) # initialize savon client
      @client = Savon.client(wsdl: WSDL)
    end

    
    ############################################################
    # Profile SOAP methods:
    # ##########################################################

    def profile_sale(amount, profile_id, last_four, subid, options = {})
      # response = @client.request :process_profile_sale do
      response = @client.request 'processProfileSale' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_profile_sale(amount, profile_id, last_four, subid, options)
      end
      PrismCreditResponse.new(response)
    end

    def profile_credit(amount, profile_id, last_four, subid, options = {})
      # response = @client.request :process_profile_sale do
      response = @client.request 'processProfileCredit' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_profile_credit(amount, profile_id, last_four, subid, options)
      end
      PrismCreditResponse.new(response)
    end


    def profile_retrieve(options = {})
      # process a profile retrieve request
      # response = @client.request :process_profile_retrieve do 
      response = @client.request 'processProfileRetrieve' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_profile_retrieve(options)
      end
    end

    ############################################################
    # CreditCard SOAP methods:
    # ###########################################################

    def cc_purchase(amount, creditcard, subid, options ={})
      # process a credit card sale and right now return the savon response
      # The savon response needs to be mapped back into the proper response 
      # fields 
      
      # need to merge the gateway instance options with the options

      # response = @client.request :process_cc_sale do 
      #abort("Message goes here :D") 
      #response = @client.request 'processCCSale' do
      response = @client.call :processCCSale do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_cc_sale_auth(amount, creditcard, subid, options)
      end

      PrismCreditResponse.new(response)

    end

	def cc_add_cardonfile(amount, creditcard, subid, options = {})
	response = @client.request 'AddCOF' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_cc_sale_auth(amount, creditcard, subid, options)
      end

      PrismCreditResponse.new(response)
	end
    def cc_token_purchase(amount, creditcard, subid, options ={})
      # process a credit card sale and right now return the savon response
      # The savon response needs to be mapped back into the proper response 
      # fields 
      
      # need to merge the gateway instance options with the options

      # response = @client.request :process_cc_sale do 
      #abort("Message goes here :D") 
      response = @client.request 'processCCSale' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_cc_sale_auth(amount, creditcard, subid, options)
      end

      PrismCreditResponse.new(response)

    end
    
    def cc_token_authorize(amount, creditcard, subid, options = {})
      # reserve funds for future captures
      # response = @client.request :process_cc_auth do 
      response = @client.request 'processCCAuth' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_cc_sale_auth(amount, creditcard, subid, options)
      end

      PrismCreditResponse.new(response)
    end


    def cc_authorize(amount, creditcard, subid, options = {})
      # reserve funds for future captures
      # response = @client.request :process_cc_auth do 
      response = @client.request 'processCCAuth' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_cc_sale_auth(amount, creditcard, subid, options)
      end

      PrismCreditResponse.new(response)
    end


    def cc_capture(amount, authorization, pp_txn_id, options = {})
      # Captures reservered funds from previous auths
      # need to put some validation into these methods before 
      # making the call to the build methods

      # response = @client.request :process_cc_post do
      response = @client.request 'processCCPost' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_cc_capture(amount, authorization, pp_txn_id, options)
      end

      PrismCreditResponse.new(response)
    end


    def cc_void(amount, identification, pp_txn_id, subid, options = {})
      # voids previous transactions
      # response = @client.request :process_cc_void do 
      response = @client.request 'processCCVoid' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_cc_void(amount, identification, pp_txn_id, subid, options)
      end

      PrismCreditResponse.new(response)
    end


    def credit(amount, identification, pp_txn_id, subid, options = {})
      # applies credit back against previous transaction
      # response = @client.request :process_credit do 
      response = @client.request 'processCredit' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_credit(amount, identification, pp_txn_id, subid, options)
      end

      PrismCreditResponse.new(response)
    end

    ############################################################
    # ACH Methods
    ############################################################
    # These should be for normal ACH transactions ie: transactions
    # coming from a client into a prismpay vendor.
    ############################################################

   def ach_sale(amount, bank_account, subid, options = {})
      # response = @client.request :process_ext_ach_sale do
      #@client.request.http.open_timeout = 30
      response = @client.request 'processACHSale' do
        http.open_timeout = 30
        http.read_timeout = 30
        http.auth.ssl.verify_mode = :none
        soap.body &build_ext_ach_sale_disburse(amount, bank_account, subid, options)
      end

      PrismCreditResponse.new(response)
    end

    def ach_credit(amount, bank_account, subid, options = {})
       response = @client.request 'processACHCredit' do
         http.open_timeout=30
         http.read_timeout=30
         http.auth.ssl.verify_mode = :none
         soap.body &build_ach_credit(amount, bank_account, subid, options)
       end

       PrismCreditResponse.new(response)
    end

    def ach_verify(bank_account, options = {}) 
      response = @client.request 'processACHVerification' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_ext_ach_sale_disburse(0, bank_account, nil, options)
      end

      PrismCreditResponse.new(response)
    end
    ############################################################
    # ACH Ext Check Sale
    ############################################################
    # These will be used for checks coming in which will have
    # disbursments to a third party as well
    ############################################################
    
    def ext_ach_sale(amount, bank_account, subid, options = {})
      # response = @client.request :process_ext_ach_sale do 
      response = @client.request 'processExtACHSale' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_ext_ach_sale_disburse(amount, bank_account, subid, options)
      end

      PrismCreditResponse.new(response)
    end

    ############################################################
    # ext_ach_void doesn't work in generic testing accounts
    ############################################################
    def ach_void(identification, pp_txn_id, subid, options = {})
      # response = @client.request :process_ext_ach_void do 
      response = @client.request 'processVoid' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_ext_ach_refund_void(nil, identification, pp_txn_id, subid, options)
      end

      PrismCreditResponse.new(response)
    end

    def ach_refund(amount, identification, pp_txn_id, subid, options = {})
      # response = @client.request :process_ext_ach_credit do  
      response = @client.request 'processCredit' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_ext_ach_refund_void(amount, identification, pp_txn_id, subid, options)
      end

      PrismCreditResponse.new(response)
    end

    def ext_ach_consumer_disbursement(amount, bank_account, subid, options = {})
      # response = @client.request :process_ext_ach_consumer_disbursement do 
      response = @client.request 'processExtACHConsumerDisbursement' do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body &build_ext_ach_sale_disburse(amount, bank_account, subid, options)
      end

      PrismCreditResponse.new(response)
    end



    # helper methods
    private 

    def build_address(addr, type= "bill")
      # receives a hash that contains the keys for active_merchant 
      # address and type which should be 'bill' or 'ship'
      # returns a str to be eval and included in xml builder block
      
      if type != "bill" && type != "ship"
        type = "bill" 
      end
      
      retstr = 
        "xml.#{type}address('xsi:type' => 'urn:address'){ 
          xml.addr1 '#{addr[:address1]}'
          xml.addr2 '#{addr[:address2]}'
          xml.city '#{addr[:city]}'
          xml.state '#{addr[:state]}'
          xml.zip '#{addr[:zip]}'
          xml.country '#{addr[:country]}'
        }"
    end

    def build_recur(recur)

      retstr = 
        "xml.recurring('xsi:type' => 'urn:Recur'){
             xml.create '#{recur[:create]}'
             xml.billingcycle '#{recur[:billingcycle]}'
             xml.billingmax '#{recur[:billingmax]}'
             xml.start '#{recur[:start]}'
             xml.amount '#{recur[:amount]}'
           }"
    end

    def build_profile_retrieve(options = {})
      xml_block = Proc.new { |xml|
        xml.miscprocess("xsi:type" => "urn:ProfileRetrieve"){ 
          xml.acctid @acctid
          xml.merchantpin @password if @password
          xml.subid options[:subid] if options[:subid]
          xml.last4digits options[:last_four] 
          xml.userprofileid options[:profileid] 
          xml.merchantpin options[:merchantpin] if options[:merchantpin]
          xml.ipaddress
        }
      }

      return xml_block
    end

    def build_credit(amount, id, pp_txn_id, subid, options)
      xml_block = Proc.new { |xml|
        xml.miscprocess("xsi:type" => "urn:VoidCreditPost"){ 
          xml.acctid @acctid
          xml.merchantpin @password if @password
          xml.amount amount
          xml.orderid pp_txn_id
          xml.subid subid if subid
          xml.historyid id
          xml.ipaddress
        }
      }

      return xml_block
    end

    def build_cc_void(amount, auth, pp_txn_id, subid, options)
      # needs to have orderid and amount in options
      xml_block = Proc.new {|xml|
        xml.miscprocess("xsi:type" => "urn:VoidCreditPost"){ 
          xml.acctid @acctid
          xml.merchantpin @password if @password
          xml.amount amount
          xml.orderid pp_txn_id
          xml.subid subid if subid
          xml.historyid auth
          xml.ipaddress
        }
      }

      return xml_block
    end

    def build_cc_capture(amount, auth, pp_txn_id, options)
      # as of now auth is historyid and we need :orderid set in options
      xml_block = Proc.new {|xml|
        xml.miscprocess("xsi:type" => "urn:VoidCreditPost"){ 
          xml.acctid @acctid
          xml.merchantpin @password if @password
          xml.amount amount
          xml.orderid pp_txn_id
          xml.historyid auth
          xml.merchantordernumber auth
          xml.memo options[:memo] if options[:memo]
          xml.merchantpin auth
          xml.ipaddress
        }
      }
      return xml_block
    end

    def build_cc_sale_auth(amount, credit_card, subid, options)
      # return a proc object to be used as a block for builder 
      # passed to response.body {|xml| my xml block}

      missing_fields_for_options = {
        :acctid => '', 
        :merchantpin => '', 
        :subid => subid
      }

      # to map the active_merchant option keys to prismpay
      active_merchant_credit_card = {
        :first_name => '', 
        :last_name => '',
        :month => '', 
        :number => '',
        :type => '',
        :verification_value => '', 
        :year => '',
        :recur => ''
      }

      active_merchant_option_map = {
        :order_id => :merchantordernumber,
        :ip => :ipaddress,
        :customer => '',      # customer info
        :invoice => '',       # invoice
        :merchant => '',      # name of merchant offering the product
        :description => '',   # A description of the transaction
        :email => :email,     # The email address of the customer
        :currency => :currencycode, 
        :address => '',  # if this is set it is both billing and shipping
        :recur => { # recurring payment
          :create => '',
          :billingcycle => '',
          :billingmax => '',
          :start => '',
          :amount => amount,
        },     
        :billing_address => {
          :name => '',
          :company => '',
          :address1 => '',
          :address2 => '',
          :city => '',
          :state => '',
          :country => '',
          :zip => '',
          :phone => ''
        },
        :shipping_address => {
          :name => '',
          :company => '',
          :address1 => '',
          :address2 => '',
          :city => '',
          :state => '',
          :country => '',
          :zip => '',
          :phone => ''
        }
      }

      if options.has_key?(:address)
        bill_address = ship_address = options[:address]
      else
        # assigns nil to variables if keys aren't present 
        bill_address = options[:billing_address] 
        ship_address = options[:shipping_address]
      end

      xml_block  = Proc.new{ |xml| 
        xml.ccinfo("xsi:type" => "urn:CreditCardInfo") { 
          xml.acctid @acctid
          xml.merchantpin @password if @password
          # xml.merchantpin options[:password] if options.has_key?(:password)
          # xml.subid "xsi:nil" => "true"
          xml.ccname "#{credit_card.first_name} #{credit_card.last_name}"
          # xml.swipedata "xsi:nil" => "true"
          # xml.cardpresent "xsi;nil" => "true"
          # xml.cardreaderpresent "xsi:nil" => "true"
          # xml.voiceauth "xsi:nil" => "true"
          # xml.track1 "xsi:nil" => "true"
          # xml.track2 "xsi:nil" => "true"
          xml.ccnum credit_card.number
          xml.cctype credit_card.type
          xml.expmon credit_card.month
          xml.expyear credit_card.year
          xml.cvv2 credit_card.verification_value
          xml.amount amount
          xml.merchantordernumber options[:order_id] if options.has_key?(:order_id) # or invoice?
          # xml.companyname  # says its our companyname 
          eval(build_address(bill_address)) if bill_address 
          eval(build_address(ship_address, "ship")) if ship_address
          xml.email options[:email] if options.has_key?(:email)
          # xml.dlnum 
          # xml.ssnum 
          xml.phone bill_address[:phone] if bill_address
          # xml.dobday
          # xml.dobmonth
          # xml.dobyear 
          # xml.memo 
          # xml.customizedemail("xsi:type" => "urn:customEmail"){ #method
          #   xml.emailto "vpat@comcast.net"
          #   xml.emailfrom "null@atsbank.com"
          #   xml.emailsubject "Transaction Service Test"
          #   xml.emailtext "This is just a test"
          # }
          #abort(options.recurring)  
          
          
          if credit_card.recur.to_s == '1'
           xml.recurring("xsi:type" => "urn:Recur") { #nees method
             xml.create 1
             xml.billingcycle 2
             xml.billingmax -1
             xml.start 1
             xml.amount amount
           }
          else
            #abort(credit_card.recur.to_s)
          end 
          xml.memo options[:memo] if options[:memo]
          xml.ipaddress options[:ip]  # req field ... nil if !(exists?)
          # xml.accttype ---> #have no clue
          # xml.merchantpin ----> #believe this is password
          # xml.currencycode 
          # xml.industrycode ----> # no clue
          # xml.dynamicdescriptor ---> carries onto receipt for VITAL auths
          # xml.profileactiontype # no clue
          # xml.manualrecurring #number 1 if manual recurring
        }
      }

      return xml_block
    end


    def build_profile_sale(amount, profile_id, last_four, subid, options)
      # as of now auth is historyid and we need :orderid set in options
    
      xml_block = Proc.new {|xml|
        xml.miscprocess("xsi:type" => "urn:MPTransProcess"){ 
          xml.acctid @acctid
          xml.merchantpin @password if @password
          xml.subid subid if subid
          xml.last4digits last_four
          xml.userprofileid profile_id
          xml.memo options[:memo] if options[:memo]
          xml.amount amount
          xml.ipaddress
          xml.customizedfields("xsi:type" => "urn:CustomFields") {
            xml.custom1 options[:custom1] if options[:custom1]
            xml.custom2 options[:custom2] if options[:custom2]
            xml.custom3 options[:custom3] if options[:custom3]
            xml.custom4 options[:custom4] if options[:custom4]
            xml.custom5 options[:custom5] if options[:custom5]
            xml.custom6 options[:custom6] if options[:custom6]
          }
        }
      }
      return xml_block
    end

    def build_profile_credit(amount, profile_id, last_four, subid, options)
      # as of now auth is historyid and we need :orderid set in options

      xml_block = Proc.new {|xml|
        xml.miscprocess("xsi:type" => "urn:MPTransProcess"){
          xml.acctid @acctid
          xml.merchantpin @password if @password
          xml.last4digits last_four
          xml.subid subid if subid
          xml.userprofileid profile_id
          xml.memo options[:memo] if options[:memo]
          xml.amount amount
          xml.ipaddress
        }
      }
      return xml_block
    end

    def build_ach_credit(amount, bank_account, subid, options)
      acct_type = "#{bank_account.account_holder_type} " +
          "#{bank_account.account_type}"

      # as of now auth is historyid and we need :orderid set in options
      xml_block = Proc.new {|xml|
        xml.miscprocess("xsi:type" => "urn:ACHInfo", "xmlns:urn" => "url:MPTransProcess"){
          xml.acctid @acctid
          xml.merchantpin(@password) if @password
          xml.subid subid if subid
          xml.ckname bank_account.name
          xml.firstname bank_account.first_name
          xml.lastname bank_account.last_name
          xml.ckaba bank_account.routing_number
          xml.ckacct bank_account.account_number
          xml.ckno(bank_account.cknumber) if bank_account.number
          xml.memo options[:memo] if options[:memo]
          xml.amount amount
          if bank_account.account_holder_type =~ /business/i
            xml.cktype('CCD')
          else
            xml.cktype('PPD')
          end
          xml.ckaccttypedesc acct_type
          xml.companyname options[:companyname]
          xml.ipaddress
        }
      }

      return xml_block
    end

    def build_ext_ach_sale_disburse(amount, bank_account, subid, options)
      # should probably pass in the companyname under options
      acct_type = "#{bank_account.account_holder_type} " +
        "#{bank_account.account_type}"

      xml_block = Proc.new { |xml|
        xml.ckinfo("xsi:type" => "urn:ACHInfo"){
          xml.acctid @acctid
          xml.merchantpin(@password) if @password
          xml.subid subid if subid
          xml.ckname bank_account.name
          xml.firstname bank_account.first_name
          xml.lastname bank_account.last_name
          xml.ckaba bank_account.routing_number
          xml.ckacct bank_account.account_number
          xml.ckno(bank_account.cknumber) if bank_account.number
          xml.memo options[:memo] if options[:memo]
          xml.amount amount
          if bank_account.account_holder_type =~ /business/i
            xml.cktype('CCD')
          else 
            xml.cktype('PPD')
          end
          xml.ckaccttypedesc acct_type
          xml.companyname options[:companyname]
          xml.ipaddress
          xml.customizedfields("xsi:type" => "urn:CustomFields") {
             xml.custom1 options[:custom1] if options[:custom1]
             xml.custom2 options[:custom2] if options[:custom2]
             xml.custom3 options[:custom3] if options[:custom3]
             xml.custom4 options[:custom4] if options[:custom4]
             xml.custom5 options[:custom5] if options[:custom5]
             xml.custom6 options[:custom6] if options[:custom6]
          }
        }
      }

      return xml_block
    end

    def build_ext_ach_refund_void(amount, auth, pp_txn_id, subid, options)
      # should probably pass in the companyname under options
      xml_block = Proc.new { |xml|
       # xml.ckinfo("xsi:type" => "urn:ACHInfo"){
        xml.miscprocess("xsi:type" => "urn:VoidCreditPost"){
          xml.acctid @acctid
          xml.subid subid if subid
          xml.merchantpin(@password) if @password
          xml.orderid pp_txn_id
          xml.historyid auth
          xml.amount amount if amount
          xml.ipaddress
        }
      }

      return xml_block
    end



  end # class PrismPay 


  class BankAccount
    # mimic ActiveMerchant check object for compatibility, tesing, and
    # stand alone purposes
    
    attr_accessor :first_name, :last_name, :account_number, :routing_number,
    :account_holder_type, :account_type, :cknumber

    def number=(n)
      @cknumber = n
    end

    def number
      @cknumber
    end

    def [](method)
      eval ("self.#{method}")
    end
    
    def []=(method, rval)
      eval ("self.#{method} = rval")
    end

    def name
      [@first_name, @last_name].join(' ')
    end

    def name=(n)
      names = n.split(' ')
      @first_name = names[0]
      @last_name = names[1]
    end

    def initialize(checkinfo = {})
      if checkinfo.respond_to?("has_key?")
        @account_number = checkinfo[:account_number] if checkinfo.has_key?(:account_number)
        @name = checkinfo[:name] if checkinfo.has_key?(:name)
        @routing_number = checkinfo[:routing_number] if checkinfo.has_key?(:routing_number)
        @cknumber = checkinfo[:number] if checkinfo.has_key?(:number)
        @account_type = checkinfo[:account_type] if checkinfo.has_key?(:account_type)
        @account_holder_type = checkinfo[:account_holder_type] if checkinfo.has_key?(:account_holder_type)
      end
    end

  end # BankAccount

  class CreditCard
    # credit card information... mimic ActiveMerchant
    attr_accessor :number, :month, :year, :first_name, 
    :verification_value, :type, :last_name, :recur

    def [](method)
      eval ("self.#{method}")
    end

    def name
      join(@first_name, @last_name)
    end

    def name=(n)
      names = n.split(' ')
      @first_name = names[0]
      @last_name = names[1]
    end

    def []=(method, rval)
      eval ("self.#{method} = rval")
    end

    def initialize(ccinfo = {})
      if ccinfo.respond_to?("has_key?")
        @number = ccinfo[:number] if ccinfo.has_key?(:number)
        @month = ccinfo[:month] if ccinfo.has_key?(:month)
        @year = ccinfo[:year] if ccinfo.has_key?(:year)
        @name = ccinfo[:name] if ccinfo.has_key?(:name)
        @verification_value = ccinfo[:verification_value] if ccinfo.has_key?(:verification_value)
        @type = ccinfo[:type] if ccinfo.has_key?(:type)
        @recur = ccinfo[:recur] if ccinfo.has_key?(:recur)
      end
    end
  end # CreditCard

end #module PrismPay 


# #####################
# # Demo driver 
# #####################

# cc = CreditCard.new({})
# cc.number = 5454545454545454
# cc.month = 7
# cc.year = 14
# cc.name = "JohnDoe Soap"
# cc.verification_value = 123
# cc.type = "Visa"

# addr2 = { 
#   :name => "Fathead Don",
#   :address1 => "1501 S Delany Ave",
#   :city => "Orlando",
#   :state => "FL",
#   :zip => "32806",
#   :country => "US"
# }

# options = {
#   :login => "TEST0",
#   :order_id => Time.now.strftime("%y%m%d%H%M%S"),
#   :address => addr2
# }

# gateway = PrismPay.new(options)

# purchase_amount = "23.32"

# response = gateway.cc_purchase(purchase_amount, cc, options)

# ########################################
# # NOTE
# ########################################
# # as of now the cc_purchase and cc_auth method will return the soap
# # response object from the client that objects meaningful values are
# # accessible from response.body[:multi_ref].keys()

# response = gateway.credit_sale(purchase_amount, credit_card)

# puts "The unparsed authcode is #{response.body[:multi_ref][:authcode]}"

