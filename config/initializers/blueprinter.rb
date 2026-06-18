Blueprinter.configure do |config|
  config.datetime_format = ->(datetime) { datetime&.iso8601 }

  config.transformer_default_value = nil

  config.transformers = [Blueprinter::Transformers::CamelCaseTransformer]
end
