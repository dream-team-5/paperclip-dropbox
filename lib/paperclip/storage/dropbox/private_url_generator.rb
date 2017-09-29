require "paperclip/storage/dropbox/url_generator"
module Paperclip
  module Storage
    module Dropbox
      class PrivateUrlGenerator < UrlGenerator
        def file_url(style)
          path = @attachment.path(style)
          @attachment.dropbox_client_v2.get_temporary_link(path).link
        end
      end
    end
  end
end
