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

  def initialize(params=nil)
  	@id = nil
  	@location = nil
  	@contents = nil
  	if params
  		@id = params[:_id].to_s
  		@location = Point.new(params[:metadata][:location]) if params[:metadata][:location]	
  	end
  end

  def persisted?
  	!@id.nil?
  end

  def save
  	if !persisted?
  		gps = EXIFR::JPEG.new(@contents).gps
  		location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)

  		description = {:content_type=>"image/jpeg",
               			 :metadata => {:location => location.to_hash}
               			}
			grid_file = Mongo::Grid::File.new(@contents.read, description)
			id = Photo.mongo_client.database.fs.insert_one(grid_file)

			@id = id.to_s
			@location = location
  	end
  end

  def contents
  	
  end

  def destroy
  	Photo.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
  end

end