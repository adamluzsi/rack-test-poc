
require 'rack'

class APP
  def self.call(env)
    # [200, {"Content-Type" => "application/json"}, '{"msg":"Hello Rack!","data":{"key":"value"}}']
    [200, {"Content-Type" => "text/html"}, 'true']
  end
end

require 'rack/test/poc'
require 'minitest/autorun'

describe 'AppTest' do

  include Rack::Test::Methods

  def app
    APP
  end

  specify 'some rack test!' do

    header('Accept-Version','v1')
    get '/',one_param: 'data' #> at this point poc data generated for '/'

    #> bla bla bla some code here

    last_response.body #> '{"msg":"Hello Rack!"}'

    # resp = JSON.parse(last_response.body)
    # resp['msg'].desc 'Hy'
    # resp['data']['key'].desc 'bye'

    last_response.body.desc 'boolean response'


  end


end