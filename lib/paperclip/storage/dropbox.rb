require "dropbox_api"
require "active_support/core_ext/hash/keys"
require "paperclip/storage/dropbox/path_generator"
require "paperclip/storage/dropbox/generator_factory"
require "paperclip/storage/dropbox/credentials"


module Paperclip
  module Storage
    module Dropbox
      def self.extended(base)
        base.instance_eval do
          @options[:dropbox_options] ||= {}
          @options[:path] = nil if @options[:path] == self.class.default_options[:path]
          @options[:dropbox_visibility] ||= "public"

          @path_generator = PathGenerator.new(self, @options)
        end
      end

      def flush_writes
        @queued_for_write.each do |style, file|
          dropbox_client_v2.upload(path(style), file.read)
        end
        after_flush_writes
        @queued_for_write.clear
      end

      def flush_deletes
        @queued_for_delete.each do |path|
          case path
          when String
            dropbox_client_v2.delete(path)  
          when Array
            path.uniq.each { |p| dropbox_client_v2.delete(p) }
          end
        end
        @queued_for_delete.clear
      end

      def url(style_or_options = default_style, options = {})
        options.merge!(style_or_options) if style_or_options.is_a?(Hash)
        style = style_or_options.is_a?(Hash) ? default_style : style_or_options
        url_generator.generate(style, options)
      end

      def path(style = default_style)
        path = @path_generator.generate(style)
        path = File.join("Public", path) if public_dropbox?
        path
      end

      def copy_to_local_file(style = default_style, destination_path)
        File.open(destination_path, "wb") do |file|
          dropbox_client_v2.download(path(style)) do |content|
            file.write content
          end
        end
      end

      def exists?(style = default_style)
        return false if not present?
        metadata = dropbox_client_v2.get_metadata(path(style)).to_hash
        not metadata.nil? and not metadata["is_deleted"] and metadata[".tag"] != "deleted"
      rescue DropboxApi::Errors::NotFoundError
        false
      end

      def dropbox_client_v2
        @dropbox_client_v2 ||= DropboxApi::Client.new(dropbox_credentials[:access_token])
      end


      def dropbox_credentials
        @dropbox_credentials ||= begin
          creds = fetch_credentials
          creds[:access_type] ||= 'dropbox'
          creds
        end
      end

      def url_generator
        @url_generator = GeneratorFactory.build_url_generator(self, @options)
      end

      def public_dropbox?
        dropbox_credentials[:access_type] == "dropbox" &&
          @options[:dropbox_visibility] == "public"
      end

      private

      def fetch_credentials
        credentials = @options[:dropbox_credentials].respond_to?('call') ? @options[:dropbox_credentials].call(self) : @options[:dropbox_credentials]

        environment = defined?(Rails) ? Rails.env : @options[:dropbox_options][:environment]
        Credentials.new(credentials).fetch(environment)
      end

      class FileExists < RuntimeError
      end
    end
  end
end
