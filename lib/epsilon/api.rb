require 'builder'
require 'net/http'
require 'uri'
#require 'xml'
require 'rexml/document'

module Epsilon
  class Api
    # The values servername, username and password need to be set with each
    # request in the HTTP-Header.
    [:servername, :username, :password, :enabled, :logger].each do |attr|
      class_eval("def self.#{attr}\n@@#{attr} ||= nil\nend")
      class_eval("def self.#{attr}=(obj)\n@@#{attr} = obj\nend\n")
    end

    class << self

      def deliver(email, template = 'default', attributes = {}, configuration = {})
        if enabled
          handle_result(post(xml(email, template, attributes, configuration)))
        else
          logger && logger.info("Sending email [#{template}] via Epsilon::Api to #{email}")
        end
      end

      # Retrieving the configuration.
      def configuration
        @@configuration ||= {}
      end

      # Setting the configuration.
      def configuration=(hash)
        raise 'Configuration needs to be a hash' unless hash.is_a?(Hash)
        @@configuration = hash
      end

      def url=(url)
        @@uri = URI.parse(url)
      end

      def uri
        @@uri ||= nil
      end

      private

      def http
        @@http ||= Net::HTTP.new(uri.host, uri.port)
      end

      def post(xml)
        http.post(uri.path, xml, {'Content-type' => 'text/xml',
                                  'Accept'       => 'text/xml',
                                  'ServerName'   => servername,
                                  'UserName'     => username,
                                  'Password'     => password})
      end

      def handle_result(result)
        if(Net::HTTPOK === result)
          doc = REXML::Document.new(result.body)
          case REXML::XPath.match(doc, '//DMResponse/Code/text()').first.to_s
          when '1' # Success
            REXML::XPath.match(doc, '//DMResponse/ResultData/TransactionStatus/TransactionID//text()').map(&:to_s)
          else # Raise using Description
            raise REXML::XPath.match(doc, '//DMResponse/Description/text()').first.to_s
          end
        else # Raise using HTTP-Message
          raise result.message
        end
      end

      # Retrieving the XML for the POST-Request
      def xml(email, template = 'default', attributes = {}, configuration = {})
        xml = Builder::XmlMarkup.new
        xml.instruct!
        xml.comment!('Created by Epsilon::Api')
        xml.RTMWeblet do |weblet|
          weblet.RTMEmailToEmailAddress do |email_to_email_address|
            # XXX Acknowledgements yet disabled
            #acknowledgements_to(email_to_email_address, configuration)
            template_info(email_to_email_address, template, configuration)
            email_to_email_address.ToEmailAddress do |to_email_address|
              to_email_address.EventEmailAddress do |event_email_address|
                event_email_address.EmailAddress(email)
                event_variables(event_email_address, attributes)
              end
            end
          end
        end
      end

      # Creates XML for Acknowledgements
      def acknowledgements_to(xml, configuration)
        if(acknowledgements_email = configuration.delete('acknowledgements_to'))
          xml.AcknowledgementsTo do |acknowledgements_to|
            acknowledgements_to.mailAddress(acknowledgements_email)
          end
        end
      end

      def template_info(xml, template, configuration)
        conf = self.configuration.merge(configuration)
        { :client_name   => 'ClientName',
          :site_name     => 'SiteName',
          :campaign_name => 'CampaignName' }.each do |key,value|
          if(var = conf[key])
            xml.tag!(value, var)
          end
        end
        xml.MailingName(template)
      end

      def event_variables(xml, variables)
        xml.EventVariables do |event_variables|
          variables.each do |key, value|
            event_variables.Variable do |variable|
              variable.Name(key.to_s)
              variable.Value(value.to_s)
            end
          end
        end
      end

    end
  end
end
