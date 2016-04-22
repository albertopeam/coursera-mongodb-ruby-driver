class Place
  include Mongoid::Document
  @@db = nil

  def Place.mongo_client
  	@@db ||= Mongoid::Clients.default
  	@@db
  end

  def Place.collection
  	Place.mongo_client[:places]
  end

	def Place.load_all(file_path) 
		file = File.read(file_path)
    hash = JSON.parse(file)
    Place.collection.insert_many(hash)
  end
end
