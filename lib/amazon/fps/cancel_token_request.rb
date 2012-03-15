require 'net/http'
require 'amazon/fps/base_fps_request'

module Amazon
module FPS

class CancelTokenRequest < BaseFpsRequest
  def send(multi_use_token)
		params = get_default_parameters()

		params["Action"] = "CancelToken"
		params["TokenId"] = multi_use_token

		uri = URI.parse(@service_end_point)
    signature = Amazon::FPS::SignatureUtils.sign_parameters({:parameters => params, 
                                            :aws_secret_key => @secret_key,
                                            :host => uri.host,
                                            :verb => @http_method,
                                            :uri  => uri.path })
    params[Amazon::FPS::SignatureUtils::SIGNATURE_KEYNAME] = signature

		return self.class.get(@service_end_point, :query => params)
	end
end

end
end
