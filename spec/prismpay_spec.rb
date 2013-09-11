require 'prismpay'
require 'builder'

########################################
# Helper Functions
########################################

def save_auth_trans(orderid, historyid, amount)
  # mechanism for saving hist id for testing auth/capture
  File.open("./data~", "at") {|f|
    f.puts "#{orderid}:#{historyid}:#{amount}"
  }
end

def save_void_trans(orderid, historyid, amount)
  # mechanism for saving hist id for testing auth/capture
  File.open("./void~", "at") {|f|
    f.puts "#{orderid}:#{historyid}:#{amount}"
  }
end

def save_refund_trans(orderid, historyid, amount)
  # mechanism for saving hist id for testing auth/capture
  File.open("./credit~", "at") {|f|
    f.puts "#{orderid}:#{historyid}:#{amount}"
  }
end

def get_last_trans(file)
  # gets the values of the last auth transaction needed for void or refund
  ret = {}
  File.open(file, "rt"){|f|
    str = f.gets
    str.chomp!
    ret[:order_id], ret[:historyid], ret[:amount] = str.split ":"
  }
  ret
end

def processed_trans(line, file)
  # loads histid numbers of auth transactions into an array
  # removes the captured transaction and then rewrites the file
  arr = []
  File.open(file, "rt") {|f|
    arr = f.readlines
  }
  arr = arr - [line]          
  File.open(file, "wt") { |f|
    f.puts(arr)
  }
end

def builder_wrapper()
  # this should wrap the proc object the same way the 
  # savon.request call would.
  bld = Builder::XmlMarkup.new  
  yield (bld)
  return bld.target!
end

############################################################
# Start Tests
############################################################

describe PrismPay::PrismPay, "#cc_purchase" do 
  it "returns successful sale for sane values" do 
    amount = "10.00"
    cc = PrismPay::CreditCard.new({})
    cc.number = 5454545454545454
    cc.month = 7
    cc.year = 14
    cc.name = "JohnDoe Soap"
    cc.verification_value = 123
    cc.type = "Visa"

    addr2 = { 
      :name => "Fathead Don",
      :address1 => "1501 S Delany Ave",
      :city => "Orlando",
      :state => "FL",
      :zip => "32806",
      :country => "US"
    }

    options = {
      :login => "TEST0",
      :order_id => Time.now.strftime("%y%m%d%H%M%S"),
      :address => addr2
    }

    gateway = PrismPay::PrismPay.new(options)

    purchase_amount = "23.32"

    response = gateway.cc_purchase(purchase_amount, cc, options).soap_response

    save_void_trans(response.body[:multi_ref][:orderid],
               response.body[:multi_ref][:historyid], 
               purchase_amount)

    response.body[:multi_ref][:status].should =~ (/Approved/)
  end
end

describe PrismPay::PrismPay, "#cc_authorize" do 
  it "returns successful auth for sane values and saves orderid" do 
    amount = "10.00"
    cc = PrismPay::CreditCard.new({})
    cc.number = 5454545454545454
    cc.month = 7
    cc.year = 14
    cc.name = "JohnDoe Soap"
    cc.verification_value = 123
    cc.type = "Visa"

   addr2 = { 
      :name => "Fathead Don",
      :address1 => "1501 S Delany Ave",
      :city => "Orlando",
      :state => "FL",
      :zip => "32806",
      :country => "US"
    }

    options = {
      :login => "TEST0",
      :order_id => Time.now.strftime("%y%m%d%H%M%S"),
      :address => addr2
    }

    gateway = PrismPay::PrismPay.new(options)

    purchase_amount = "23.32"

    response = gateway.cc_authorize(purchase_amount, cc, options).soap_response

    save_auth_trans(response.body[:multi_ref][:orderid],
               response.body[:multi_ref][:historyid], 
               purchase_amount)

    response.body[:multi_ref][:status].should =~ (/Approved/)
  end
end


describe PrismPay::PrismPay, "#build_address" do 
  addr1 = {
    :name => "testee mcgee",
    :company => "widgets R us",
    :address1 => "1 s orange ave",
    :address2 => "st: 406",
    :city => "Orlando",
    :state => "FL",
    :zip => "32801",
    :country => "US"
  }

  addr2 = { 
    :name => "Fathead Don",
    :address1 => "1501 S Delany Ave",
    :city => "Orlando",
    :state => "FL",
    :zip => "32806",
    :country => "US"
  }

  gw = PrismPay::PrismPay.new(addr1)

  private_method = gw.method(:build_address)

  it "should return string" do 
    private_method.call(addr1).class.should eq(String)
  end
  
  it "should return bill block for bad type" do 
    private_method.call(addr1).should =~ /billaddress/
    private_method.call(addr1, {}).should =~ /billaddress/
    private_method.call(addr1, "junk").should =~ /billaddress/
  end

  it "should return ship string for ship type" do 
    private_method.call(addr1, "ship").should =~ /shipaddress/
  end
  
end

describe PrismPay::PrismPay, "#build_cc_sale_auth" do 
  amount = "10.00"
  cc = PrismPay::CreditCard.new({})
  cc.number = 5454545454545454
  cc.month = 7
  cc.year = 14
  cc.name = "JohnDoe Soap"
  cc.verification_value = 123
  cc.type = "Visa"

  addr2 = { 
    :name => "Fathead Don",
    :address1 => "1501 S Delany Ave",
    :city => "Orlando",
    :state => "FL",
    :zip => "32806",
    :country => "US"
  }

  options = {
    :login => "TEST0",
    :order_id => Time.now.strftime("%y%m%d%H%M%S"),
    :address => addr2
  }


  it "should return xml builder block for sale/auth" do 
    gw = PrismPay::PrismPay.new(options)
    private_method = gw.method(:build_cc_sale_auth)
    private_method.call(amount, cc, options).class.should eq(Proc)
  end
  
  it "should take 1 arg" do 
    gw = PrismPay::PrismPay.new(options)
    private_method = gw.method(:build_cc_sale_auth)
    myproc = private_method.call(amount, cc, options)
    myproc.arity.should > 0
  end

  it "should create xml object when passed to builder" do 
    gw = PrismPay::PrismPay.new(options)
    private_method = gw.method(:build_cc_sale_auth)
    myproc = private_method.call(amount, cc, options)
    str = builder_wrapper(&myproc)
    str.should =~ /^<ccinfo[^&]*<\/ccinfo>$/ #match the object
  end
  
end

describe PrismPay::PrismPay, "build_cc_void" do 
  it "should return xml builder block for void" do 
    gw = PrismPay::PrismPay.new({})
    priv_method = gw.method(:build_cc_void)
    priv_method.call("", "", "",{}).class.should eq(Proc)
  end
  
end

describe PrismPay::PrismPay, "build_cc_capture" do 
  it "should return xml builder block for capture"  do 
    gw = PrismPay::PrismPay.new({})
    priv_method = gw.method(:build_cc_capture)
    priv_method.call("", "", "",{}).class.should eq(Proc)
  end
end

describe PrismPay::PrismPay, "build_credit" do 
  it "should return xml builder block for refund" do 
    gw = PrismPay::PrismPay.new({})
    priv_method = gw.method(:build_credit)
    priv_method.call("", "", "", {}).class.should eq(Proc)
  end
end

describe PrismPay::PrismPay, "cc_capture" do 
  it "should capture an auth successfully with sane values" do 
    options = { }
    values = get_last_trans("./data~")
    options[:login] = "TEST0"
    orderid = values[:order_id]
    authcode = values[:historyid]
    amount = values[:amount]

    gw = PrismPay::PrismPay.new(options)
    
    response = gw.cc_capture(amount, authcode, orderid, options).soap_response

    response.body[:multi_ref][:status].should =~ /Approved/

    if response.body[:multi_ref][:status] =~ /Approved/
      processed_trans "#{orderid}:#{authcode}:#{amount}\n", "./data~"
    end
  end
end

describe PrismPay::PrismPay, "cc_void" do 
  it "should void a sale" do 
    options = { }
    values = get_last_trans("./void~")
    options[:login] = "TEST0"
    orderid = values[:order_id]
    authcode = values[:historyid]
    amount = values[:amount]


    gw = PrismPay::PrismPay.new(options)
    
    response = gw.cc_void(amount ,authcode, orderid, options).soap_response

    response.body[:multi_ref][:status].should =~ /Approved/

    if response.body[:multi_ref][:status] =~ /Approved/
      processed_trans "#{orderid}:#{authcode}:#{amount}\n", "./void~"
    end
  end
end

describe PrismPay::PrismPay, "credit" do 
  it "should refund a sale" do 

    amount = "10.00"
    cc = PrismPay::CreditCard.new({})
    cc.number = 5454545454545454
    cc.month = 7
    cc.year = 14
    cc.name = "JohnDoe Soap"
    cc.verification_value = 123
    cc.type = "Visa"

    addr2 = { 
      :name => "Fathead Don",
      :address1 => "1501 S Delany Ave",
      :city => "Orlando",
      :state => "FL",
      :zip => "32806",
      :country => "US"
    }

    options = {
      :login => "TEST0",
      :order_id => Time.now.strftime("%y%m%d%H%M%S"),
      :address => addr2
    }

    gateway = PrismPay::PrismPay.new(options)

    response = gateway.cc_purchase(amount, cc, options).soap_response

    save_refund_trans(response.body[:multi_ref][:orderid],
               response.body[:multi_ref][:historyid], 
               amount)
    

    values = get_last_trans("./credit~")
    authcode = values[:historyid]

    options[:orderid] = oid = values[:order_id]
    response = gateway.credit(values[:amount], authcode, options).soap_response

    response.body[:multi_ref][:status].should =~ /Approved/

    if response.body[:multi_ref][:status] =~ /Approved/
      processed_trans "#{oid}:#{authcode}:#{amount}\n", "./credit~"
    end
  end
end

describe PrismPay::PrismPay, "ext_ach_sale", :bfd => true do 

  ba = PrismPay::BankAccount.new
  ba[:name] = "George Jones"
  ba[:account_number] = "999999999"
  ba[:routing_number] = "999999999"
  ba[:account_holder_type] = 'personal'
  ba[:account_type] = 'checking'

  amount = "1.11"

  options = {
    :login => "TEST0",
    :order_id => Time.now.strftime("%y%m%d%H%M%S"),
  }

  gateway = PrismPay::PrismPay.new(options)


  it "should transact sale with a call to ext_ach_sale" do
    
    response = gateway.ext_ach_sale(amount, ba, options).soap_response
    response.body[:multi_ref][:status].should =~ /Approved/

    save_refund_trans(response.body[:multi_ref][:orderid],
                      response.body[:multi_ref][:historyid], 
                      amount)

    amount2 = 5.54
    
    response = gateway.ext_ach_sale(amount2, ba, options).soap_response

    save_void_trans(response.body[:multi_ref][:orderid],
                    response.body[:multi_ref][:historyid], 
                    amount)


  end


  it "should transact an ext_ach_consumer_disbursement"  do
    
    response = gateway.ext_ach_consumer_disbursement(amount, ba, options).soap_response
    response.body[:multi_ref][:status].should =~ /Approved/


  end


  it "should void a previous transaction" do 
    values = get_last_trans("./void~")

    orderid = values[:order_id]
    authcode = values[:historyid]
    amount = values[:amount]

    response = gateway.ext_ach_void(authcode, orderid).soap_response
    response.body[:multi_ref][:status].should =~ /Approved/

    if response.body[:multi_ref][:status] =~ /Approved/
      processed_trans "#{orderid}:#{authcode}:#{amount}\n", "./void~"
    end

  end


  it "should refund a transaction" do 
    values = get_last_trans("./credit~")

    orderid = values[:order_id]
    authcode = values[:historyid]
    amount = values[:amount]

    response = gateway.ext_ach_refund(amount, authcode, orderid).soap_response
    response.body[:multi_ref][:status].should =~ /Approved/

    if response.body[:multi_ref][:status] =~ /Approved/
      processed_trans "#{orderid}:#{authcode}:#{amount}\n", "./credit~"
    end

  end

end

