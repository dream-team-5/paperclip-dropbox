require "dropbox_api"

module Paperclip
  module Dropbox
    module Rake
      extend self

      def authorize(app_key, app_secret, access_type)
        authenticator = DropboxApi::Authenticator.new(app_key, app_secret)

        puts "Visit this URL: #{ authenticator.authorize_url}"
        print "And after you approved the authorization enter the token here: "
        code = STDIN.gets.strip

        auth_bearer = authenticator.get_token(code) #=> #<OAuth2::AccessToken ...>`
        auth_bearer.token #=> "VofXAX8D..."

        dropbox_client = DropboxApi::Client.new(auth_bearer.token)
        account_info = dropbox_client.get_current_account

        puts <<-MESSAGE

Authorization was successful. Here you go:

access_token: #{auth_bearer.token}
user_id: #{account_info.to_hash["account_id"]}
name: #{account_info.to_hash["name"]["display_name"]}
        MESSAGE
      end

    end
  end
end
