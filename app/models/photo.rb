class Photo

	attr_accessor :id, :location
	attr_writer :contents

	@@db = nil
	@id = nil
	@location = nil
	@contents = nil

	def Photo.mongo_client
  	@@db ||= Mongoid::Clients.default
  	@@db
  end

end