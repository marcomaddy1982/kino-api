# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # A user's phone number and name, sent on register. `name` is matched exactly
  # (at any nesting level, e.g. "session.name") so it doesn't also hide
  # unrelated keys that merely contain the word.
  :phone, /\A(?:.*\.)?name\z/
]
