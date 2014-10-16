
require 'rack'

class APP
  def self.call(env)
    [200, {"Content-Type" => "application/json"}, '{"msg":"Hello Rack!"}']
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

    get '/' #> at this point poc data generated for '/'

    #> bla bla bla some code here

    last_response.body #> '{"msg":"Hello Rack!"}'

  end


end