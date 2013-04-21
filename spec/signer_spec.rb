require 'spec_helper'

describe AWS::CF::Signer do

  let(:key_path) { File.expand_path(File.dirname(__FILE__) + '/keys/pk-APKAIKUROOUNR2BAFUUU.pem') }

  describe "configuring with a string key" do
    let(:key_string) { File.readlines(key_path).join("") }
    let(:key_pair_id) { "ABCKEEQRNKA" }

    def configure
      AWS::CF::Signer.reset!
      AWS::CF::Signer.configure do |config|
        config.key_string = key_string
        config.key_pair_id = key_pair_id
      end
    end

    it "should be_configured" do
      configure
      AWS::CF::Signer.is_configured?.should eql(true)
    end

    context "without a key string specified" do
      let(:key_string) { nil }
      it "should raise an error specifying the key string or path is required" do
        expect { configure }.to raise_error(ArgumentError)
      end
    end

    context "without a key pair specified" do
      let(:key_pair_id) { nil }

      it "should raise an error specifying the key pair id is required" do
        expect { configure }.to raise_error ArgumentError
      end
    end

  end

  describe "configuring with a PEM file" do

    before(:each) do
      AWS::CF::Signer.reset!
      AWS::CF::Signer.configure do |config|
        config.key_path = key_path
        #config.key_pair_id  = "XXYYZZ"
        #config.default_expires = 3600
      end
    end


    describe "before default use" do

      it "should be configured" do
        AWS::CF::Signer.is_configured?.should eql(true)
      end

      it "should expire urls and paths in one hour by default" do
        AWS::CF::Signer.default_expires.should eql(3600)
      end

      it "should optionally be configured to expire urls and paths in ten minutes" do
        AWS::CF::Signer.default_expires =  600
        AWS::CF::Signer.default_expires.should eql(600)
        AWS::CF::Signer.default_expires =  nil
      end
    end

    describe "when signing a url" do

      it "should remove spaces from the url" do
        url = "http://somedomain.com/sign me"
        result = AWS::CF::Signer.sign_url(url)
        (result =~ /\s/).should be_nil
      end

      it "should not html encode the signed url by default" do
        url = "http://somedomain.com/someresource?opt1=one&opt2=two"
        result = AWS::CF::Signer.sign_url(url)
        (result =~ /\?/).should_not be_nil
        (result =~ /=/).should_not be_nil
        (result =~ /&/).should_not be_nil
      end

      it "should optionally html encode the signed url" do
        url = "http://somedomain.com/someresource?opt1=one&opt2=two"
        result = AWS::CF::Signer.sign_url_safe(url)
        (result =~ /\?/).should be_nil
        (result =~ /=/).should be_nil
        (result =~ /&/).should be_nil
      end

      it "should expire in one hour by default" do
        url = "http://somedomain.com/sign me"
        result = AWS::CF::Signer.sign_url(url)
        get_query_value(result, 'Expires').to_i.should eql((Time.now + 3600).to_i)
      end

      it "should optionally expire in ten minutes" do
        url = "http://somedomain.com/sign me"
        result = AWS::CF::Signer.sign_url(url, :expires => Time.now + 600)
        get_query_value(result, 'Expires').to_i.should eql((Time.now + 600 ).to_i)
      end

    end


    describe "when signing a path" do

      it "should not remove spaces from the path" do
        path = "/someprefix/sign me"
        result = AWS::CF::Signer.sign_path(path)
        (result =~ /\s/).should_not be_nil
      end

    end
  end
end
