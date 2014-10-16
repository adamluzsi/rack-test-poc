module RackTestPoc

  def self.dump_obj
    @dump_obj ||= Hash.new
  end

  module EXT

    def __init_dump_poc__
      $rack_test_poc_dump_export ||= -> {
        Kernel.at_exit do

          require 'yaml'
          require 'fileutils'

          root_dir = if defined?(Rails) && Rails.respond_to?(:root) && !!Rails.root
                       Rails.root.to_s
                     elsif !!ENV['BUNDLE_GEMFILE']
                       ENV['BUNDLE_GEMFILE'].split(File::Separator)[0..-2].join(File::Separator)
                     else
                       Dir.pwd
                     end

          dump_dir = File.join root_dir,'test','poc'

          FileUtils.mkdir_p(dump_dir) unless File.exist?(dump_dir)

          unless RackTestPoc.dump_obj.empty?
            File.write File.join(dump_dir,Time.now.to_i.to_s.concat('.yaml')),
                       RackTestPoc.dump_obj.to_yaml

          end

        end;true
      }.call
    end

    def process_request(uri, env, *args)

      __init_dump_poc__

      super

      RackTestPoc.dump_obj[uri] ||= {}
      RackTestPoc.dump_obj[uri][env['REQUEST_METHOD']] ||= {}

      begin

        format = env['PATH_INFO'].split('.')[-1]
        case format

          when 'json'
            require 'json'
            body = JSON.parse last_response.body

          # when 'xml'

          else
            require 'json'
            body = JSON.parse last_response.body
            format = 'json'

        end

      rescue
        body = last_response.body

      end

      RackTestPoc.dump_obj[uri][env['REQUEST_METHOD']]['response'] ||= {}
      RackTestPoc.dump_obj[uri][env['REQUEST_METHOD']]['request']  ||= {}

      RackTestPoc.dump_obj[uri][env['REQUEST_METHOD']]['request']['query']= env['QUERY_STRING']

      RackTestPoc.dump_obj[uri][env['REQUEST_METHOD']]['response']['body']= body
      RackTestPoc.dump_obj[uri][env['REQUEST_METHOD']]['response']['status']= last_response.status
      RackTestPoc.dump_obj[uri][env['REQUEST_METHOD']]['response']['format']= format

      return last_response

    end
  end

end

require 'rack/test'
Rack::Test::Session.prepend RackTestPoc::EXT