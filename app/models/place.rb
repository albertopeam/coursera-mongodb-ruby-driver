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

  def Place.all(offset = 0, limit = 0)
    places = []
    Place.collection.find().skip(offset).limit(limit).each do |hash|
      places.push(Place.new(hash))
    end
    places
  end

  def Place.get_address_components(sort={}, offset=0, limit=nil)
    pipeline = []
    pipeline.push({:$unwind => '$address_components'})
    pipeline.push({:$project => {:_id => true, :address_components => true, :formatted_address => true, "geometry.geolocation" => true}})
    if !sort.empty?
      pipeline.push({:$sort => sort})
    end
    if offset > 0
      pipeline.push({:$skip => offset})
    end
    if !limit.nil?
      pipeline.push({:$limit => limit})
    end

    Place.collection.aggregate(pipeline)
  end

  def Place.get_country_names
    Place.collection.find.aggregate([
                    {:$project => {:_id => false, "address_components.long_name" =>true, "address_components.types" => true}},
                    {:$unwind => "$address_components.types"}
                    ])
  end

  def Place.find_ids_by_country_code(country_code)
    Place.collection.find.aggregate([
                          {:$match => {"address_components.types" => "country",
                                       "address_components.short_name" => country_code}},
                          {:$project => {:_id => true}}])
                          .map {|doc| doc[:_id].to_s}
  end

  def Place.create_indexes
    Place.collection.indexes.create_one({"geometry.geolocation" => Mongo::Index::GEO2DSPHERE})
  end

  def Place.remove_indexes
    Place.collection.indexes.drop_one("geometry.geolocation_2dsphere")
  end

  def Place.near(point, max_meters=0)
    Place.collection.find("geometry.geolocation" => 
                        {:$near => 
                                  {:$geometry => point.to_hash, 
                                   :$maxDistance => max_meters
                                  }
                        })
  end

  def near(max_meters=0)
    places_json = Place.near(@location, max_meters)
    places = Place.to_places(places_json)
    places
  end

  def initialize(params)
    @id = params[:_id].to_s
    @formatted_address = params[:formatted_address]
    @address_components = []
    if params[:address_components]
      params[:address_components].each do |address| 
        place = AddressComponent.new(address)
        @address_components.push(place)
      end  
    end
    @location = Point.new(params[:geometry][:geolocation])
  end

  def destroy
    mongo_id = BSON::ObjectId.from_string(@id)
    Place.collection.find(:_id => mongo_id).delete_one
  end

  def photos(offset=0, limit=nil)
    photos_hash = []
    if limit
        photos_hash = Photo.find_photos_for_place(@id).skip(offset).limit(limit)
    else
        photos_hash = Photo.find_photos_for_place(@id).skip(offset)
    end
    photos = []
    photos_hash.each do |hash|
      photos.push(Photo.new(hash))
    end
    photos
  end
end
