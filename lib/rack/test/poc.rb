require 'minitest/unit'

module RackTestPoc

  module ObjectExt

    def is_for(description_text)
      return unless RackTestPoc.last_poc

      old_body = RackTestPoc.last_poc['response']['body']['object']
      RackTestPoc.last_poc['response']['body']['description'] ||= ->{

        begin
          JSON.parse(old_body.to_json) #> hard clone
        rescue
          old_body.dup rescue old_body
        end

      }.call

      RackTestPoc.description_helper(self,description_text)

      nil

    end

  end

  ::Object.__send__ :include, ObjectExt

  class << self

    def desc_comp_search(container,object,description_text)
      case container

        when Array
          if container.index(object)
            container[container.index(object)]= description_text
          else
            container.each do |element|
              desc_comp_search(element,object,description_text)
            end
          end

        when Hash
          if container.key(object)
            container[container.key(object)]= description_text
          else
            container.each { |k,v| desc_comp_search(v,object,description_text) }
          end

      end
    end

    def description_helper(object,description_text)
      case container = RackTestPoc.last_poc['response']['body']['description']

        when Array,Hash
          desc_comp_search(container,object,description_text)

        else
          RackTestPoc.last_poc['response']['body']['description']=description_text

      end

    end

    def root
      if defined?(Rails) && Rails.respond_to?(:root) && !!Rails.root
        Rails.root.to_s
      elsif !!ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'].split(File::Separator)[0..-2].join(File::Separator)
      else
        Dir.pwd
      end
    end

    def dump_object
      @dump_object ||= Hash.new
    end

    def last_poc=(last_poc)
      @last_poc=last_poc
    end

    def last_poc
      @last_poc
    end

  end
  self.dump_object #> eager load for multiThread

  module EXT

    def __init_dump_poc__
      $rack_test_poc_dump_export ||= -> {
        Kernel.at_exit do

          require 'yaml'
          require 'fileutils'

          dump_dir = File.join RackTestPoc.root,'test','poc'
          FileUtils.mkdir_p(dump_dir) unless File.exist?(dump_dir)

          unless RackTestPoc.dump_object.empty?
            File.write File.join(dump_dir,Time.now.to_i.to_s.concat('.yaml')),
                       RackTestPoc.dump_object.to_yaml

          end

        end;true
      }.call
    end

    def process_request(uri, env, *args)

      if RackTestPoc.last_poc && RackTestPoc.last_poc['response']['body']['description']

        RackTestPoc.last_poc['response']['body']['description']

      end

      __init_dump_poc__

      super

      request_method_str = env['REQUEST_METHOD'].to_s.upcase

      RackTestPoc.dump_object[uri] ||= {}
      RackTestPoc.dump_object[uri][request_method_str] ||= {}

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

      RackTestPoc.dump_object[uri][request_method_str]['response'] ||= {}
      RackTestPoc.dump_object[uri][request_method_str]['request']  ||= {}

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

      RackTestPoc.dump_object[uri][request_method_str]['request']['query'] ||= {}
      RackTestPoc.dump_object[uri][request_method_str]['request']['query']['raw'] = raw_query
      RackTestPoc.dump_object[uri][request_method_str]['request']['query']['object'] = query_hash
      RackTestPoc.dump_object[uri][request_method_str]['request']['headers'] = @headers

      RackTestPoc.dump_object[uri][request_method_str]['response']['body']= {}

      RackTestPoc.dump_object[uri][request_method_str]['response']['body']['object'] = body
      RackTestPoc.dump_object[uri][request_method_str]['response']['body']['raw'] = last_response.body

      # RackTestPoc.dump_object[uri][request_method_str]['response']['headers']= env.reduce({}){
      #     |m,o| m.merge!(o[0]=>o[1]) if o[0].to_s.downcase =~ /^http_/ ; m
      # }

      RackTestPoc.dump_object[uri][request_method_str]['response']['status']= last_response.status
      RackTestPoc.dump_object[uri][request_method_str]['response']['format']= format

      # if env['CONTENT_TYPE']
      #   RackTestPoc.dump_object[uri][request_method_str]['response']['content_type']= env['CONTENT_TYPE']
      # end

      RackTestPoc.last_poc = RackTestPoc.dump_object[uri][request_method_str]

      return last_response

    end
  end

end

require 'rack/test'
Rack::Test::Session.prepend RackTestPoc::EXT
