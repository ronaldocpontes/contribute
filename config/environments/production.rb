Contribute::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
	# NOTE: This is enabled right now since we're only using Mongrel
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

	# Tell Devise where to link back to in its confirmation e-mails
	config.action_mailer.default_url_options = { :host => 'contribute.cas.msu.edu' }

	#Amazon Payments Configuration
	# config.amazon_cbui_endpoint = "https://authorize.payments.amazon.com/cobranded-ui/actions/start"
	# config.amazon_fps_endpoint = "https://fps.amazonaws.com/"
	config.amazon_cbui_endpoint = "https://authorize.payments-sandbox.amazon.com/cobranded-ui/actions/start"
	config.amazon_fps_endpoint = "https://fps.sandbox.amazonaws.com/"

	config.aws_access_key = "AKIAIVLAEPTVD6GUEKKQ"
	config.aws_secret_key = "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"

	#Email Configuration
	config.from_address = "Contribute <gethelp@contribute.cas.msu.edu>"
	config.admin_address = "contribute@bitlab.cas.msu.edu"

  # Procompile ckeditor js and css files
  config.assets.precompile += Ckeditor.assets
end

