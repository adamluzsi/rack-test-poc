Rack Test POC
=============

### Description

rack/test based poc file generator, this will make you able to export 
any data that traveled through the test, and be able to create poc 
file with that. It is even useful for creating integration test that 
is based on your api endpoints, because the export file will be 
serialized into a yaml file that contain all the endpoints that 
you just tested, and it's inputs and outputs

I my self use for documentation and cooperation purpose with other developers

### Install

#### RubyGems/gem command

  $ gem install rack-test-poc

#### Bundler/Gemfile

  gem 'rack-test-poc'

### Use

All you need to do is to require 'rack/test/poc' in your test_helper 
when you working with rack-test module,
and you good to go!

### example

```ruby

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
  
```

this will generate a yaml file with the current unix timestamp in the following format:

```yaml

---
"/": #> endpoint
  GET: #> endpoint method
    response: 
      body: #> parsed response.body
        msg: Hello Rack!
      status: 200
      format: json #> format of the response
    request:
      query: '' #> query string that been used


```
