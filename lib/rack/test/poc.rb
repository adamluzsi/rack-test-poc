module RackTestPoc

  def self.root
    if defined?(Rails) && Rails.respond_to?(:root) && !!Rails.root
      Rails.root.to_s
    elsif !!ENV['BUNDLE_GEMFILE']
      ENV['BUNDLE_GEMFILE'].split(File::Separator)[0..-2].join(File::Separator)
    else
      Dir.pwd
    end
  end

  def self.dump_obj
    @dump_obj ||= Hash.new
  end;self.dump_obj #> eager load for multiThread

  module EXT

    def __init_dump_poc__
      $rack_test_poc_dump_export ||= -> {
        Kernel.at_exit do

          require 'yaml'
          require 'fileutils'

          dump_dir = File.join RackTestPoc.root,'test','poc'
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

      request_method_str = env['REQUEST_METHOD'].to_s.upcase

      RackTestPoc.dump_obj[uri] ||= {}
      RackTestPoc.dump_obj[uri][request_method_str] ||= {}

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
        format  = 'text/html'
        body    = last_response.body

      end

      RackTestPoc.dump_obj[uri][request_method_str]['response'] ||= {}
      RackTestPoc.dump_obj[uri][request_method_str]['request']  ||= {}

      raw_query = env.find{|k,v|
        %W[ QUERY_STRING rack.request.form_vars ].any?{|tag| k == tag && !v.nil? && v != '' }
      }[1] rescue nil

      query_hash = if raw_query
                     require 'cgi'
                     CGI.parse(raw_query).reduce({}){
                         |m,o| m.merge!(o[0]=> (o[1].length == 1 ? o[1][0] : o[1] ) )
                     }

                   else
                     {}

                   end

      RackTestPoc.dump_obj[uri][request_method_str]['request']['query'] ||= {}
      RackTestPoc.dump_obj[uri][request_method_str]['request']['query']['raw'] = raw_query
      RackTestPoc.dump_obj[uri][request_method_str]['request']['query']['object'] = query_hash
      RackTestPoc.dump_obj[uri][request_method_str]['request']['headers']= env.reduce({}){
          |m,o| m.merge!(o[0]=>o[1]) if o[0].to_s.downcase =~ /^http_/ ; m
      }

      RackTestPoc.dump_obj[uri][request_method_str]['response']['body']     = body
      RackTestPoc.dump_obj[uri][request_method_str]['response']['raw_body'] = last_response.body

      RackTestPoc.dump_obj[uri][request_method_str]['response']['status']= last_response.status
      RackTestPoc.dump_obj[uri][request_method_str]['response']['format']= format

      if env['CONTENT_TYPE']
        RackTestPoc.dump_obj[uri][request_method_str]['response']['content_type']= env['CONTENT_TYPE']

      end



      return last_response

    end
  end

end

require 'rack/test'
Rack::Test::Session.prepend RackTestPoc::EXT
