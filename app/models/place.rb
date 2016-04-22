class Place
  include ActiveModel::Model

  attr_accessor :id, :formatted_address, :location, :address_components

  @@db = nil
  @id = nil
  @formatted_address = nil
  @location = nil
  @address_components = nil

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

  def Place.find_by_short_name(short_name)
    Place.collection.find("address_components.short_name" => short_name)
  end

  def Place.to_places(collection_view)
    places = []
    collection_view.each do |hash|
      places.push(Place.new(hash))
    end
    places
  end

  def Place.find(id)
    bson_id = BSON::ObjectId.from_string(id)
    hash = Place.collection.find(:_id => bson_id).first
    Place.new(hash) if hash
  end

  def initialize(params)
    @id = params[:_id].to_s
    @formatted_address = params[:formatted_address]
    @address_components = []
    params[:address_components].each do |address| 
      place = AddressComponent.new(address)
      @address_components.push(place)
    end
    @location = Point.new(params[:geometry][:geolocation])
  end
end
