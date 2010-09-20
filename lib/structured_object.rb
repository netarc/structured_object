require 'i18n'

class StructuredObject
  class << self
    # The source root is the path to the root directory of the StructuredObject gem.
    def source_root
      @@source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end

# Default I18n to load the en locale
I18n.load_path << File.expand_path("../../templates/locales/en.yml", __FILE__)

require 'structured_object/version'
