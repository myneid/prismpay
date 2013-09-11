module PrismPay

  class PrismPayReports
    # this class will manage the connection to the gateway and handle
    # transactions

    WSDL = File.expand_path("../ReportingService.xml", __FILE__)
    # WSDL = "https://trans.myprismpay.com/report/services/ReportingServices?wsdl"


    TRANS_TYPES = ["ccpreauths", "ccpostauthsales", "ccvoids",
                   "ccrefunds", "ccchargebacks", "achpreauths",
                   "achsettlements", "achreturns", "achnocs",
                   "achvoids", "achcreditsauth",
                   "achcreditsmerchantdebit", "achcreditsdebitreturn",
                   "achcreditsmerchantsettle",
                   "achcreditspaymentsettle", "achcreditsreturn",
                   "debitsales", "debitrefunds", "achlatereturns",
                   "extachpreauths", "extachsettlements",
                   "extachreturns", "extachnocs", "extachvoids",
                   "extachcreditsauth", "extachcreditssettle",
                   "extachcreditsreturn", "extachck21_auth ",
                   "extachck21_void", "extachck21_return",
                   "verfication", "ccincremental", "ccreversal"]


    CARD_TYPES = ["visa", "mastercard", "amex", "discovernetwork",
                  "jcb", "diners", "debit", "flyingj", "cfna",
                  "gemoney", "fleetone", "fuellnk", "fuelman",
                  "mastercardfleet", "visafleet", "voyager",
                  "wrightexpress"]   


    attr_accessor :acctid, :password
    attr_reader :client


    def initialize(options = {})

      merchant_info = options

      merchant_info.merge!({:login => 'TEST0'}) unless merchant_info[:login]

      @login = merchant_info[:login]
      @key = hexstr_to_str(options[:key])
      @account_key = options[:account_key]

      @client = Savon::Client.new(WSDL) # initialize savon client
    end


    def account_key
      @account_key
    end


    def ampm_hour(hour)
      hour %= 12
      return 12 if hour == 0 
      hour
    end


    ############################################################
    # These transactions are the ones that happen outside of our
    # system that we must know about and make relationships to
    # transactions that are in our system
    ############################################################

    def get_ext_ach_settled(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types => 
                         ['extachsettlements']})
    end

    def get_ext_ach_returned(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types => 
                         ['extachreturns']})
    end

    def get_ext_ach_credits_settled(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types => 
                         ['extachcreditssettle']})
    end

    def get_ext_ach_credits_returned(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types => 
                         ['extachcreditsreturn']})
    end

    def get_cc_chargebacks(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types => 
                         ['ccchargebacks']})
    end

    def get_cc_reversals(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types =>
                         ['ccreversal']})
    end

    ############################################################
    # These transactions are the ones our system currently makes use
    # of.  The only other transactions currently wrapped by
    # prismpay.rb would be of type ccpreauths.  We are not presently
    # making any calls to that though
    ############################################################

    def get_cc_sales(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types =>
                         ['ccpostauthsales']})
    end

    def get_cc_voids(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types =>
                         ['ccvoids']})

    end

    def get_cc_refunds(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types =>
                         ['ccrefunds']})

    end

    def get_ext_ach_auths(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types =>
                         ['extachpreauths']})

    end

    def get_ext_ach_credit_auths(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types =>
                         ['extachcreditsauth']})

    end

    def get_ext_ach_voids(start_date, end_date)
      get_transactions(start_date, end_date, {:trans_types =>
                         ['extachvoids']})

    end

    ############################################################
    # The remaining transactions for testing purposes
    ############################################################

    def get_cc_preauths(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['ccpreauths']})
    end

    def get_ach_preauths(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achpreauths']})
    end

    def get_ach_settlements(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achsettlements']})
    end

    def get_ach_returns(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achreturns']})
    end

    def get_ach_nocs(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achnocs']})
    end

    def get_ach_voids(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achvoids']})
    end

    def get_ach_credits_auth(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achcreditsauth']})
    end

    def get_ach_credits_merchant_debit(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achcreditsmerchantdebit']})
    end

    def get_ach_credits_debit_return(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achcreditsdebitreturn']})
    end

    def get_ach_credits_merchant_settle(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achcreditsmerchantsettle']})
    end

    def get_ach_credits_payment_settle(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achcreditspaymentsettle']})
    end

    def get_ach_credits_return(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achcreditsreturn']})
    end

    def get_debit_sales(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['debitsales']})
    end

    def get_debit_refunds(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['debitrefunds']})
    end

    def get_ach_late_returns(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['achlatereturns']})
    end

    def get_ext_ach_nocs(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['extachnocs']})
    end

    def get_ext_ach_ck21_auth(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['extachck21_auth']})
    end

    def get_ext_ach_ck21_void(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['extachck21_void']})
    end

    def get_ext_ach_ck21_return(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['extachck21_return']})
    end

    def get_verification(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['verfication']})
    end

    def get_cc_incremental(start_date, end_date)
      get_transactions(start_date, end_date,{:trans_types =>
                         ['ccincremental']})

    end
    

    ############################################################
    # The main method.  Takes two Time objects for a start and an
    # end. Also takes a hash of options which act as flags or
    # variables to affect the report.
    ############################################################

    def get_transactions(start_date, end_date, options = {})

      #variables to handle return max of sample sets
      max_rows = (options[:max_rows]) ? options[:max_rows] : 4096
      num_rows = (options[:num_rows]) ? options[:num_rows] : max_rows
      start_row = (options[:start_row]) ? options[:start_row] : 1

      # set up the flags to initially include everything
      accepted = declined = childsubids = initial_flag = 
        recurring_flag = recurringretries = sort = 1

      accepted = 0 if options[:not_accepted]
      declined = 0 if options[:not_declined]
      childsubids = 0 if options[:no_childsubids]
      initial_flag = 0 if options[:no_initials]
      recurring_flag = 0 if options[:no_recurrings]
      recurringretries = 0 if options[:no_recurring_retries]
      sort = 0 if options[:no_sort]

      # sets the test flag acceptable values are:
      # 0 = Include Live and Test Transactions.  
      # 1 = Include Live Transactions Only.  
      # 2 = Include Test Transactions Only.
      if options[:test_only] == true
        test_flag = 2
      elsif options[:test_only] == false 
        test_flag = 1
      else
        test_flag = 0
      end

      # sets the recurring_only flag... it overrides all others if true
      options[:recurring_only] ? recurring_only = 1 : recurring_only = 0

      if options[:card_types] 
        card_types = options[:card_types]
      else 
        card_types = CARD_TYPES
      end

      if options[:trans_types] 
        transaction_types = options[:trans_types]
      else 
        transaction_types = TRANS_TYPES
      end

      response = @client.request "TransactionReportInfo" do
        http.open_timeout=30
        http.read_timeout=30
        http.auth.ssl.verify_mode = :none
        soap.body do |xml|

          xml.accountkey account_key
          xml.sessionkey create_sessionkey
          xml.subid options[:subid]

          xml.startdate { |ixml|
            ixml.month "%.2d" % start_date.mon
            ixml.day "%.2d" % start_date.day
            ixml.year start_date.year
            ixml.hour "%.2d" % ampm_hour(start_date.hour)
            ixml.minute "%.2d" % start_date.min
            ixml.second "%.2d" % start_date.sec
            ixml.ampm((start_date.hour > 11) ? "PM" : "AM" )
          }

          xml.enddate { |ixml|
            ixml.month "%.2d" % end_date.mon
            ixml.day "%.2d" % end_date.day
            ixml.year end_date.year
            ixml.hour "%.2d" % ampm_hour(end_date.hour)
            ixml.minute "%.2d" % end_date.min
            ixml.second "%.2d" % end_date.sec
            ixml.ampm((end_date.hour > 11) ? "PM" : "AM" )
          }

          xml.cardtypes { |ixml|
            ixml.visa(card_types.include?("visa") ? 1 : 0)
            ixml.mastercard(card_types.include?("mastercard") ? 1 : 0)
            ixml.amex(card_types.include?("amex") ? 1 : 0)
            ixml.discovernetwork(card_types.include?("discovernetwork") ? 1 : 0)
            ixml.jcb(card_types.include?("jcb") ? 1 : 0)
            ixml.diners(card_types.include?("diners") ? 1 : 0)
            ixml.debit(card_types.include?("debit") ? 1 : 0)
            ixml.flyingj(card_types.include?("flyingj") ? 1 : 0)
            ixml.cfna(card_types.include?("cfna") ? 1 : 0)
            ixml.gemoney(card_types.include?("gemoney") ? 1 : 0)
            ixml.fleetone(card_types.include?("fleetone") ? 1 : 0)
            ixml.fuellnk(card_types.include?("fuellnk") ? 1 : 0)
            ixml.fuelman(card_types.include?("fuelman") ? 1 : 0)
            ixml.mastercardfleet(card_types.include?("mastercardfleet") ? 1 : 0)
            ixml.visafleet(card_types.include?("visafleet") ? 1 : 0)
            ixml.voyager(card_types.include?("voyager") ? 1 : 0)
            ixml.wrightexpress(card_types.include?("wrightexpress") ? 1 : 0)
          }

          xml.transactiontypes { |ixml|
            ixml.ccpreauths(transaction_types.include?("ccpreauths") ? 1 : 0)
            ixml.ccpostauthsales(transaction_types.include?("ccpostauthsales") ? 1 : 0)
            ixml.ccvoids(transaction_types.include?("ccvoids") ? 1 : 0)
            ixml.ccrefunds(transaction_types.include?("ccrefunds") ? 1 : 0)
            ixml.ccchargebacks(transaction_types.include?("ccchargebacks") ? 1 : 0)
            ixml.achpreauths(transaction_types.include?("achpreauths") ? 1 : 0)
            ixml.achsettlements(transaction_types.include?("achsettlements") ? 1 : 0)
            ixml.achreturns(transaction_types.include?("achreturns") ? 1 : 0)
            ixml.achnocs(transaction_types.include?("achnocs") ? 1 : 0)
            ixml.achvoids(transaction_types.include?("achvoids") ? 1 : 0)
            ixml.achcreditsauth(transaction_types.include?("achcreditsauth") ? 1 : 0)
            ixml.achcreditsmerchantdebit(transaction_types.include?("achcreditsmerchantdebit") ? 1 : 0)
            ixml.achcreditsdebitreturn(transaction_types.include?("achcreditsdebitreturn") ? 1 : 0)
            ixml.achcreditsmerchantsettle(transaction_types.include?("achcreditsmerchantsettle") ? 1 : 0)
            ixml.achcreditspaymentsettle(transaction_types.include?("achcreditspaymentsettle") ? 1 : 0)
            ixml.achcreditsreturn(transaction_types.include?("achcreditsreturn") ? 1 : 0)
            ixml.debitsales(transaction_types.include?("debitsales") ? 1 : 0)
            ixml.debitrefunds(transaction_types.include?("debitrefunds") ? 1 : 0)
            ixml.achlatereturns(transaction_types.include?("achlatereturns") ? 1 : 0)
            ixml.extachpreauths(transaction_types.include?("extachpreauths") ? 1 : 0)
            ixml.extachsettlements(transaction_types.include?("extachsettlements") ? 1 : 0)
            ixml.extachreturns(transaction_types.include?("extachreturns") ? 1 : 0)
            ixml.extachnocs(transaction_types.include?("extachnocs") ? 1 : 0)
            ixml.extachvoids(transaction_types.include?("extachvoids") ? 1 : 0)
            ixml.extachcreditsauth(transaction_types.include?("extachcreditsauth") ? 1 : 0)
            ixml.extachcreditssettle(transaction_types.include?("extachcreditssettle") ? 1 : 0)
            ixml.extachcreditsreturn(transaction_types.include?("extachcreditsreturn") ? 1 : 0)
            ixml.extachck21_auth(transaction_types.include?("extachck21_auth") ? 1 : 0)
            ixml.extachck21_void(transaction_types.include?("extachck21_void") ? 1 : 0)
            ixml.extachck21_return(transaction_types.include?("extachck21_return") ? 1 : 0)
            ixml.verfication(transaction_types.include?("verfication") ? 1 : 0)
            ixml.ccincremental(transaction_types.include?("ccincremental") ? 1 : 0)
            ixml.ccreversal(transaction_types.include?("ccreversal") ? 1 : 0)
          }

          xml.limitbycard((card_types.sort == CARD_TYPES.sort) ? 0 : 1 )
          xml.limitbytranstypes((transaction_types.sort == TRANS_TYPES.sort) ? 0 : 1)
          xml.childsubids(childsubids)
          xml.accepted(accepted)
          xml.declined(declined)
          xml.test(test_flag)
          xml.initial(initial_flag)
          xml.recurring(recurring_flag)
          xml.recurringonly(recurring_only)
          xml.recurringretries (recurringretries)
          xml.sort(sort)
          xml.maxrows max_rows
          xml.startrow start_row
          xml.numrows num_rows
          xml.currency('')
        end
      end
    end


    def create_sessionkey
      # this needs to be of the form Acctid:UnixTime and then
      # encrypted with @key

      unix_time = Time.now.to_i
      string = "#{@login}:#{unix_time}"
      
      encrypt_string(string)
    end


    # openssl methods for encrypting 

    def decrypt_string(hexstr)
      # maybe pass the need to convert from the hexstr
      str = hexstr_to_str(hexstr)
      retstr = ""
      cipher = OpenSSL::Cipher.new('des-ede3')
      cipher.decrypt
      cipher.key = @key
      retstr << cipher.update(str)
      retstr << cipher.final
      return retstr
    end

    def encrypt_string(str)
      # returns the hexstr for the url
      # TODO: need to uri escape the string before encrypting
      retstr = ""
      cipher = OpenSSL::Cipher.new("des-ede3")
      cipher.encrypt
      cipher.key = @key
      retstr << cipher.update(str)
      retstr << cipher.final
      retstr = str_to_hexstr(retstr)
      return retstr
    end

    def str_to_hexstr(hexstr)
      hexstr.unpack('H*').first
    end


    def hexstr_to_str(str)
      [str].pack 'H*'
    end
  end #PrismPayReports


  class ReportResults
    attr_reader :transactions

    def initialize(soap_result)
      @transactions = soap_result[:transaction_report_result][:transaction_report_details][:results][:record]
    end
  end #ReportRexults


end #module PrismPay



############################################################ 
# To write a test or sample driver you would need to do the following
############################################################ 
# pp_report = PrismPay::PrismPayReports.new({:login => 'PYDMO'})
#
# ## uses 5 days ago as start_date and now as end_date
# result = pp_report.get_transactions(Time.now - (60*60*24*5), Time.now)
# what is returned in result is what we now need to parse
############################################################


#####################################
# the resulting set is returned as an array that can be accessed
# through this variable: 
#
#  result.body[:transaction_report_result][:transaction_report_details][:results][:record]
#  

