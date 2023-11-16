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
    end
  end
end

OmniAuth.config.add_camelization "tesla", "Tesla"
