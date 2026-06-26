class CamelCaseTransformer < Blueprinter::Transformer
  def transform(hash, _object, _options)
    hash.transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
  end
end

Blueprinter.configure do |config|
  config.datetime_format = ->(datetime) { datetime&.iso8601 }
  config.default_transformers = [ CamelCaseTransformer ]
end
