require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Tesla < OmniAuth::Strategies::OAuth2
      class NoAuthorizationCodeError < StandardError; end

      DEFAULT_SCOPE = "email"
      DEFAULT_API_VERSION = "1".freeze

      option :client_options, {
        site: "https://fleet-api.prd.na.vn.cloud.tesla.com/api/#{DEFAULT_API_VERSION}",
        authorize_url: "https://auth.tesla.com/oauth2/v3/authorize",
        token_url: "https://auth.tesla.com/oauth2/v3/token"
      }

      uid do
        raw_info.dig(:email)
      end

      info do
        options.fields.each_with_object({}) do |field, hash|
          hash[field] = request.params[field.to_s]
        end
      end

      def raw_info
        pp access_token
        {
          email: "drnicwilliams@gmail.com"
        }
      end
    end
  end
end

OmniAuth.config.add_camelization "tesla", "Tesla"
