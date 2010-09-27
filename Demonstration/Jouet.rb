Shoes.setup do
	gem 'serialport'
end

require "SerieThread.rb"

class Jouet < SerieThread

	attr_reader :distance, :angle

	def initialize
		super("/dev/ttyUSB0", 57600)
		
		@distance = 0
		@angle = 0
		
		demarrer
		puts "Démarre"
		ecrire "d"
	end
	
	def callback retour
		#@codeuseG = retour.split(" ").first
		#@codeuseD = retour.split(" ").last
	end
	
	def avance
		puts "Avance"
		@distance -= 1000 
		if @distance >= 0
			distanceFormate = @distance.to_i.to_s.rjust(8, "0")
			ecrire "b" + distanceFormate
		else
			distanceFormate = (-@distance).to_i.to_s.rjust(8, "0")
			ecrire "g" + distanceFormate
		end
		puts @distance
	end

	def recule
		puts "Recule"
		@distance += 1000 
		if @distance >= 0
			distanceFormate = @distance.to_i.to_s.rjust(8, "0")
			ecrire "b" + distanceFormate
		else
			distanceFormate = (-@distance).to_i.to_s.rjust(8, "0")
			ecrire "g" + distanceFormate
		end
		puts @distance
	end
	
	def tourneGauche
		puts "Tourne"
		@angle += 500 
		if @angle >= 0
			angleFormate = @angle.to_i.to_s.rjust(8, "0")
			ecrire "a" + angleFormate
		else
			angleFormate = (-@angle).to_i.to_s.rjust(8, "0")
			ecrire "f" + angleFormate
		end
		puts @angle
	end
	
	def tourneDroite
		puts "Tourne"
		@angle -= 500 
		if @angle >= 0
			angleFormate = @angle.to_i.to_s.rjust(8, "0")
			ecrire "a" + angleFormate
		else
			angleFormate = (-@angle).to_i.to_s.rjust(8, "0")
			ecrire "f" + angleFormate
		end
		puts @angle
	end
	
	def reset
		puts "Reset"
		ecrire "e"
		ecrire "b00000000"
		ecrire "a00000000"
		@angle = 0
		@distance = 0
	end
	
end

j = Jouet.new

Shoes.app do
	keypress do |k|
		j.avance if k == :up
		j.recule if k == :down
		j.tourneGauche if k == :left
		j.tourneDroite if k == :right
		j.reset if k == :escape
	end
end
