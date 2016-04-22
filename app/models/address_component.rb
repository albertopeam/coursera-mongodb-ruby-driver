class AddressComponent
	include ActiveModel::Model

	attr_reader :long_name, :short_name, :types

	@long_name = nil
	@short_name = nil
	@types = nil

	def initialize(params)
		@long_name = params[:long_name]
		@short_name = params[:short_name]
		@types = params[:types]
	end
end
