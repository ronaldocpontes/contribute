require 'amazon/fps/signatureutilsforoutbound'

module Amazon
module FPS

#Disclaimer: ruby made me add if <expression> return true else return false; otherwise I received a void value expression?
class AmazonValidator
	#if the contribution in the session controller is not available, there is no tokenID returned, the status code was not successful, or the signature could not be verfied	
	def self.invalid_multi_token_response?(url, session, params)
		if session[:contribution].nil? or params[:tokenID].nil? or invalid_multi_token_status?(params[:status]) or !valid_cbui_response?(params, url)
			return true
		else
			return false
		end
	end

	#if the project in the session controller is not available, there is no tokenID return, the status code is not a successful one, or the signature could not be verified
	def self.invalid_recipient_response?(url, session, params)
		if session[:project].nil? or params[:tokenID].nil? or params[:status] != "SR" or !valid_cbui_response?(params, url)
			return true
		else
			return false
		end
	end

	#if the response contains errors or the transaction status was not a success
	def self.invalid_cancel_response?(response)
		return !response["Errors"].nil?
	end

	#if the response contains errors or no transaction status
	def self.get_transaction_status(response)
		if !response['Errors'].nil? or response['PayResult'].nil? or response['PayResult']['TransactionStatus'].nil?
			return ContributionStatus::FAILURE
		else
			return ContributionStatus.string_to_status(response['PayResult']['TransactionStatus'])
		end
	end

	def self.get_error(response)
		if response['Errors'].nil? or response['Errors']['Error'].nil? or response['Errors']['Error']['Code'].nil?
			raise "Could not parse amazon error"
		end

		error_code = response['Errors']['Error']['Code']
		error = AmazonError.find_by_error(error_code)
		if error.nil?
			error = AmazonError.unknown_error(error_code)
		end

		return error
	end

protected
	#this verifies that the signature returned came from amazon
	def self.valid_cbui_response?(params, url_end_point)
		access_key = Rails.application.config.aws_access_key
		secret_key = Rails.application.config.aws_secret_key
		utils = Amazon::FPS::SignatureUtilsForOutbound.new(access_key, secret_key)

		#This is rails garbage we don't need to send to amazon
		params.delete("controller")
		params.delete("action")

		return utils.validate_request(:parameters => params, :url_end_point => url_end_point, :http_method => "GET")	
	end

	#these are acceptable status codes for the payment method
	def self.invalid_multi_token_status?(status)
		if status != "SA" and status != "SB" and status != "SC"
			return true
		else
			return false
		end
	end
end

end
end
