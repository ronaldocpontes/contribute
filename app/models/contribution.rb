require 'amazon/fps/pay_request'
require 'amazon/fps/get_transaction_status_request'
require 'amazon/fps/cancel_token_request'
require 'amazon/fps/amazon_validator'
require 'amazon/fps/response_error'

MIN_CONTRIBUTION_AMT = 1
UNDEFINED_PAYMENT_KEY = 'TEMP'


class Contribution < ActiveRecord::Base
	belongs_to :project
	belongs_to :user

	validates :payment_key, :presence => true
	validates_numericality_of :amount, :greater_than_or_equal_to => MIN_CONTRIBUTION_AMT, :message => "must be at least $1"
	validates_numericality_of :amount, :only_integer => true, :message => "must be a whole dollar amount (no cents please)" 
	validates :project_id, :presence => :true
	validates :user_id, :presence => :true

	attr_accessible :project_id, :user_id, :amount, :payment_key

	def initialize(attributes = nil, options = {})
		super
		self.status = ContributionStatus::NONE
		self.retry_count = 0
	end

  def amount=(val)
    write_attribute(:amount, val.to_s.gsub(/,/, ''))
  end


  def cancel
    request = Amazon::FPS::CancelTokenRequest.new(self.payment_key)
    response = request.send

		cancel_status = Amazon::FPS::AmazonValidator.get_cancel_status(response)

		puts 'cancel_status', ContributionStatus.status_to_string(cancel_status)
    #If it was successful, we'll mark the record as cancelled
    if cancel_status == ContributionStatus::SUCCESS
			puts 'cancelled successfully'
      self.status = ContributionStatus::CANCELLED
			self.retry_count = 0
			EmailManager.contribution_cancelled(self).deliver
    else
			puts 'failed cancellation'
			error = Amazon::FPS::AmazonValidator.get_error(response)

			#Handle status based on error type
			if error.retriable
				puts 'retriable'
				self.status = ContributionStatus::RETRY_CANCEL
				self.retry_count = self.retry_count + 1
			elsif error.error == AmazonError::UNKNOWN
				puts 'unknown error'
				#TODO do what we do with pay
			else
				puts 'unretriable'
				self.status = ContributionStatus::FAILURE
				#email whomever needs to be
			end
    end

    self.save
  end


  def execute_payment
    request = Amazon::FPS::PayRequest.new(self.payment_key, self.project.payment_account_id, self.amount)

		response = request.send 
		transaction_status = Amazon::FPS::AmazonValidator.get_transaction_status(response)

		puts 'transaction_status', ContributionStatus.status_to_string(transaction_status)
		if transaction_status == ContributionStatus::SUCCESS
			puts 'successful payment'
      self.status = ContributionStatus::SUCCESS
			self.retry_count = 0
			EmailManager.contribution_successful(self).deliver

			self.transaction_id = response['PayResult']['TransactionId'] unless response['PayResult'].nil?
		elsif transaction_status == ContributionStatus::PENDING
			puts 'pending'
			self.status = ContributionStatus::PENDING
			self.retry_count = 0
			self.transaction_id = response['PayResult']['TransactionId'] unless response['PayResult'].nil?
		else
			puts 'failed payment'
			error = Amazon::FPS::AmazonValidator.get_error(response)

			if error.retriable
				puts 'retriable'
				self.status = ContributionStatus::RETRY_PAY
				self.retry_count = self.retry_count + 1
			elsif error.error == AmazonError::UNKNOWN
				puts 'unknown error'
				self.status = ContributionStatus::FAILURE
				#TODO: email appropriate people that we don't know what happened
				#if error.email_user
				#email user custom I don't know what happened, here's how to fix it
				#if error.email_admin
				#email admin to put the error in the amazon_errors table
			else
				puts 'we screwed up error'
				self.status = ContributionStatus::FAILURE
				#TODO: email appropriate people the template
				#if error.email_user
				#email error.message + here's how to redo your contribution
				#if error.email_admin
				#an error occured on either the project owner or our application, error.description, error.message.  This is very bad.  Here is the information contribution.project contribution.project.user, this will have to be solved manually
			end
    end

    self.save
  end

	def check_status
		request = Amazon::FPS::GetTransactionStatusRequest.new(self.transaction_id)
		response = request.send

		if !response['Errors'].nil? or response['GetTransactionStatusResult'].nil? or response['GetTransactionStatusResult']['TransactionStatus'].nil?
			return ContributionStatus::FAILURE
		end

		return ContributionStatus.string_to_status(response['GetTransactionStatusResult']['TransactionStatus'])
	end

	def destroy
		EmailManager.project_deleted_to_contributor(self).deliver
		self.cancel	
	end
end
