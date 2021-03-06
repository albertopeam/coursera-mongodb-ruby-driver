# Photo
#
#
# place => place_id
#
class Photo

	include ActiveModel::Model
	attr_accessor :id, :location
	attr_writer :contents

	@@db = nil
	@id = nil
	@location = nil
	@contents = nil
	@place = nil

	def Photo.mongo_client
  	@@db ||= Mongoid::Clients.default
  	@@db
  end

  def Photo.all(skip=0, limit=nil)
  	all = []
  	if limit.nil?
			all = Photo.mongo_client.database.fs.find.skip(skip).map{|doc| Photo.new(doc)}
  	else
  		all = Photo.mongo_client.database.fs.find.skip(skip).limit(limit).map{|doc| Photo.new(doc)}	
  	end
  	all
  end

  def Photo.find(id)
  	photo_hash = Photo.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(id)).first
  	if photo_hash
  		Photo.new(photo_hash)
  	else
  		nil
  	end
  end

  #
  # find_photos_for_place
  # id can be a String or a BSON::ObjectId
  #
  def Photo.find_photos_for_place(id)
  	place_id = nil
  	case
  		when id.is_a?(String)
				place_id = BSON::ObjectId.from_string(id)
  		when id.is_a?(BSON::ObjectId)
  			place_id = id
  	end
  	if place_id
  		return Photo.mongo_client.database.fs.find(:"metadata.place" => place_id)
  	else
  		return nil	
  	end
  end

  def initialize(params=nil)
  	@id = nil
  	@location = nil
  	@contents = nil
  	@place = nil
  	if params
  		@id = params[:_id].to_s
  		@location = Point.new(params[:metadata][:location]) if params[:metadata][:location]	
  		@place = params[:metadata][:place] if params[:metadata][:place]
  	end
  end

  def persisted?
  	!@id.nil?
  end

  def save
  	if !persisted?	
  		gps = EXIFR::JPEG.new(@contents).gps
			@location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
			description = {:content_type=>"image/jpeg",
	             			 :metadata => {:location => location.to_hash,
	             			 							 :place => @place}
	             			}
			@contents.rewind
			grid_file = Mongo::Grid::File.new(@contents.read, description)
			id = Photo.mongo_client.database.fs.insert_one(grid_file)
			@id = id.to_s
		else
			new_location = Point.new(:lng => @location.longitude, :lat => @location.latitude)
			description = {:content_type=>"image/jpeg",
	             			 :metadata => {:location => new_location.to_hash,
	             			 							 :place => @place}
	             			}
			grid_file = Photo.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id))
			grid_file.update_one(description)			
  	end
  	@id
  end

  def contents 
  	f = Photo.mongo_client.database.fs.find_one({:_id => BSON::ObjectId.from_string(@id)})
  	if f 
      buffer = ""
      f.chunks.reduce([]) do |x,chunk| 
          buffer << chunk.data.data 
      end
      return buffer
    end 
  end

  def destroy
  	Photo.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
  end


  def find_nearest_place_id(max_meters)
  	result = Place.near(@location, max_meters).projection(:_id => 1).limit(1)
  	if result.count > 0
  		return result.first[:_id]
  	else
  		return nil	
  	end
  end

  def place
  	if @place
  		return Place.find(@place.to_s)
  	else
  		return nil
  	end
  end

  def place=(object)
  	case
			when object.is_a?(Place)
  			@place = BSON::ObjectId.from_string(object.id)
  		when object.is_a?(String)
				@place = BSON::ObjectId.from_string(object)
  		when object.is_a?(BSON::ObjectId)
  			@place = object
  		else
  			@place = nil
  	end
  end

end