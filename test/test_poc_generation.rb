require 'yaml'
require 'timeout'
require 'minitest/autorun'
require_relative '../lib/rack/test/poc'

describe 'POCTest' do

  specify 'it should be made able to made a poc at exiting from the process' do

    $stdout.puts `bundle exec ruby #{File.join __dir__,'test_description.rb'}`

    begin

      Timeout.timeout 5 do
        sleep(0.1) until File.exist?(File.join __dir__,'poc')
      end

      true
    rescue;nil
    end.must_be_instance_of TrueClass

    path = Dir.glob( File.join __dir__,'poc','*.{yml,yaml}' ).sort{
        |a,b| a.split(File::Separator)[-1].split('.')[0] <=> b.split(File::Separator)[-1].split('.')[0]
    }[-1]

    poc_object = YAML.load File.read(path)
    poc_object.must_be_instance_of Hash
    poc_object.each_pair do |endpoint,options|

      endpoint.must_be_instance_of String
      endpoint[0].must_be :==, '/'

      options.must_be_instance_of Hash
      options.keys.first.must_be_instance_of String
      options.values.each do |rest_options|
        rest_options.must_be_instance_of Hash
        rest_options['response'].must_be_instance_of Hash
        rest_options['response']['body'].wont_be :==, nil
        rest_options['response']['status'].class.must_be :<=,Numeric
        rest_options['response']['format'].must_be_instance_of String
        rest_options['request']['query']['raw'].must_be_instance_of String
        rest_options['request']['query']['object'].must_be_instance_of Hash

      end



    end

  end

end