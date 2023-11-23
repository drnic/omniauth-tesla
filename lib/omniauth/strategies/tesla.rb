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
        token_url: "https://auth.tesla.com/oauth2/v3/token",
        auth_scheme: :request_body
      }
      option :token_params, {
        audience: "https://fleet-api.prd.na.vn.cloud.tesla.com" # TODO: config
      }

      uid do
        raw_info.dig(:email)
      end

      info do
        raw_info
      end

      def raw_info
        {
          email: "drnicwilliams@gmail.com",
          full_name: "Dr Nic Williams"
        }
        # @raw_info ||= JSON.parse(access_token.get("/api/1/users/me").body)
      end

      # Just vanillia callback path without query string
      def callback_url
        full_host + callback_path
      end
    end
  end
end

OmniAuth.config.add_camelization "tesla", "Tesla"

# client = OmniAuth::Strategies::Tesla.new(nil, OmniAuth::Strategies::Tesla.new(nil).options.client_options).client
# token = OAuth2::AccessToken.new(client, File.read("access_token.txt"), refresh_token: File.read("refresh_token.txt"))
# token.refresh(client_id: ENV["TESLA_CLIENT_ID"])
# -> not working / not timing out
#
# JSON.parse(token.get("/api/1/vehicles").body)
#
