require 'sass'
require 'sass/script/functions'
require 'sass-rails'

module ActiveAdmin
  module Sass
    module Helpers

      if Rails::VERSION::MAJOR == 4
        include Sprockets::SassFunctions
      else
        include ::Sass::Rails::Helpers
      end

      # Provides a helper in SASS to ensure that the paths to image
      # assets are always correct across Rails versions.
      #
      # Example:
      #
      #   background: url(active_admin_image_path('some_image.png')) 0 0 repeat-x;
      #
      # Will result in:
      #
      #   background: url("/images/active_admin/some_image.png") 0 0 repeat-x;
      #
      # Or in Rails 3.1 with asset pipeline enabled:
      #
      #   background: url("/assets/active_admin/some_image.png") 0 0 repeat-x;
      #
      # @param [Sass::Script::String] asset the path to the image after */active_admin/
      #
      # @return [Sass::Script::String] path to the image
      #
      def active_admin_image_path(asset)
        if ActiveAdmin.use_asset_pipeline?
          if Rails::VERSION::MAJOR == 4
            asset_path(::Sass::Script::String.new("active_admin/#{asset.value}"))
          else
            asset_path(::Sass::Script::String.new("active_admin/#{asset.value}"), ::Sass::Script::String.new('image'))
          end
        else
          ::Sass::Script::String.new("/images/active_admin/#{asset.value}", true)
        end
      end

    end
  end
end

# Install for use in Sass
Sass::Script::Functions.send :include, ActiveAdmin::Sass::Helpers
