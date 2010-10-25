require 'builder'
require 'net/https'
require 'uri'
#require 'xml'
require 'rexml/document'

module Epsilon
  class Api
    class << self

      # These values need to be set with each request in the HTTP-Header.
      attr_accessor :servername, :username, :password, :enabled, :logger

      # Retrieving the configuration.
      attr_accessor :configuration

      def deliver(email, campaign, template, attributes = {}, configuration = {})
        if enabled
          handle_result(post(xml(email, campaign, template, attributes, configuration)))
        else
          logger && logger.info("Sending email [#{campaign}/#{template}] via Epsilon::Api to #{email}")
        end
      end

      def url=(url)
        @@uri = URI.parse(url)
      end

      def uri
        @@uri ||= nil
      end

      def proxy_url=(url)
        @@proxy_uri = URI.parse(url)
      end

      def proxy_uri
        @@proxy_uri ||= ENV['http_proxy'] ? URI.parse(ENV['http_proxy']) : nil
      end

      private

      def http
        @http ||= proxy_uri ?
          Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port) :
          Net::HTTP
      end

      def post(xml)
        http.start(uri.host, uri.port) do |agent|
           agent.post(uri.path, xml, {'Content-type' => 'text/xml',
                                      'Accept'       => 'text/xml',
                                      'ServerName'   => servername,
                                      'UserName'     => username,
                                      'Password'     => password})
        end
      end

      def handle_result(result)
        if(Net::HTTPOK === result)
          doc = REXML::Document.new(result.body)
          # Is there a better way than using REXML::Xpath.match to find text-node within XML?
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
      def xml(email, campaign, template, attributes = {}, configuration = {})
        xml = Builder::XmlMarkup.new
        xml.instruct!
        xml.comment!('Created by Epsilon::Api')
        xml.RTMWeblet do |weblet|
          weblet.RTMEmailToEmailAddress do |email_to_email_address|
            # XXX Acknowledgements yet disabled
            #acknowledgements_to(email_to_email_address, configuration)
            template_info(email_to_email_address, campaign, template, configuration)
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

      def template_info(xml, campaign, template, configuration)
        conf = self.configuration.merge(configuration).merge({ :campaign_name => campaign })
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
        unless variables.empty?
          xml.EventVariables do |event_variables|
            variables.each do |key, value|
              event_variables.Variable do |variable|
                variable.Name("eventvar:#{key.to_s}")
                variable.Value(value.to_s)
              end
            end
          end
        end
      end

    end
  end
end
