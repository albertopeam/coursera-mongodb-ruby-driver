class Point
  include ActiveModel::Model

	attr_accessor :longitude, :latitude

	@longitude = nil
	@latitude = nil

	def initialize(params)
		set_coordinates(params)
	end

	def to_hash
		{type: "Point", coordinates: [@longitude, @latitude]}
	end

	private
		def set_coordinates(params)
			if is_geo_json_point?(params)
				set_geo_json_point(params)
			else	
				set_lat_lng(params)
			end
		end

		def is_geo_json_point?(params)
			params.has_key?(:type) && params.has_key?(:coordinates)
		end

		def set_geo_json_point(params)
			@longitude = params[:coordinates][0]
			@latitude = params[:coordinates][1]
		end

		def set_lat_lng(params)
			@longitude = params[:lng]
			@latitude = params[:lat]
		end

end
