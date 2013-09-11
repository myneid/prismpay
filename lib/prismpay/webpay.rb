module PrismPay

  class Form
    attr_reader :action, :id, :postback

    def initialize(hash)
      # takes a hash of form {action => {formid => url}}
      # this is not ideal could come up with a much cleaner way...
      # brains resources going elsewhere for now though

      @action = hash.keys.first
      @id = hash[@action].keys.first
      @postback = hash[@action][@id]
    end

  end # Form

  class WebpayPostback
    # parent class for postbacks comming from transactions processed
    # through the prismpay webpay interface
  end # WebpayPostback

  class AddProfilePB < WebpayPostback
    # specifics to addprofile postback
  end # AddProfilePB

  class CreditSalePB < WebpayPostback
    # specific to creditsale postback
  end # CreditSalePB

  class Webpay
    # class to provide an interface to the prismpay webpay interface
    # Somewhat problematic in that it is closely linked to webforms
    # right now mainly providing methods necessary to implement a form


    # an incomplete action map.. these are going to be what we are 
    # initially using to map some symbols to their corresponding 
    # webpay cgi actions
    CGI_ACTIONS = { :profile_add => 'profile_add', 
      :cc_sale => 'ns_quicksale_cc'}

    POST_URL = "https://trans.merchantpartners.com/cgi-bin/WebPay.cgi"

    attr_reader :session_id

    def initialize(config_file = "")
      # make sure the file exists... if not wreck
      # instance variables: form/postback_list, session_id, acct_id, 
      # password, subid, encryption_key

      myopts = YAML.load_file(config_file)
      @login = myopts["login"]
      @session_id = myopts["session_id"]
      @key = hexstr_to_str(myopts["key"])
      @password = myopts["password"]  # assigns nil if not in config
      @subid = myopts["subid"]        # assigns nil if not in config

      # example of form_ids hash

      # this could use some rethinking Went this route because it was
      # the cleanest looking yaml config file

      # form_ids = { action => {form_id1 => postback_url},
      #              action => {form_id2 => postback_url}}

      @form_ids = []            # list of Form objs
      myopts["form_ids"].each {|action, hash|
        # ugly way to do this... No time to worry about that now though
        @form_ids << Form.new({action => hash} )
      }
    end


    ########################################
    # TODO: mega repitition.. good place to apply DRY in refactoring
    # and do some things ruby is awesome at using the action map
    ########################################

    def profile_add_form_id
      form = nil
      @form_ids.each{|x|
        form = x if x.action == 'profile_add'
      }
      build_encrypted_form_id form.id
    end

    def profile_add_postback
      form = nil
      @form_ids.each{|x|
        form = x if x.action == 'profile_add'
      }
      encrypt_string(form.postback)
    end

    def cc_sale_postback
      form = nil
      @form_ids.each{|x|
        form = x if x.action == 'cc_sale'
      }
      encrypt_string(form.postback)
    end

    def cc_sale_form_id(amount)
      form = nil
      @form_ids.each{|x|
        form = x if x.action == 'cc_sale'
      }
      build_encrypted_form_id form.id, amount
    end

    ########################################
    # TODO end the of the last refactor note
    ########################################


    def get_formid(hexstr)
      # returns the formid string to be used when composing our formid
      # strings. Receives a hexstring generated from their web based
      # form creation cms
      str = decrypt_string(hexstr)
      str.split(":")[2]
    end


    # This is kinda silly fast fix for something
    # problematic because we don't have the @key 

    # def self.decrypt_string(hexstr)
    #   # maybe pass the need to convert from the hexstr
    #   str = [hexstr].pack 'H*'
    #   retstr = ""
    #   cipher = OpenSSL::Cipher.new('des-ede3')
    #   cipher.decrypt
    #   cipher.key = @key
    #   retstr << cipher.update(str)
    #   retstr << cipher.final
    #   return retstr
    # end


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

    def build_encrypted_form_id(formid, amount="")
      # build the encrypted formid hexstr
      # acctid:subid:formid:amount:
      str = "#{@login}:#{@subid}:#{formid}:#{amount}:"
      encrypt_string(str)
    end

    def build_customdata(options = {})
      # build encrypted string for customdata field
      # the values of this need to be url_encrypted
      str = ""
      unless options.empty?
        # build the string
        options.each{|key, val|
          str << "&" unless str.empty?
          str << "#{ERB::Util::url_encode(key)}="
          str << "#{ERB::Util::url_encode(val)}"
        }
        str = url_encrypt_string(str)
      end
      return str 
    end

    def url_encrypt_string(str)
      str = ERB::Util::url_encode(str) 
      encrypt_string(str)
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

  end # class Webpay

end #module PrismPay