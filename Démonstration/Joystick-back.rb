#!/usr/bin/ruby

require 'joystick'

# make sure a device was specified on the command-line
unless ARGV.size > 0
  $stderr.puts 'Missing device name.'
  exit -1
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
		@distance -= 100 
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
		@distance += 100 
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
		@angle += 50 
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
		@angle -= 50 
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

Joystick::Device.open(ARGV[0]) { |joy|
etat="rien"
ancien=joy.ev
temps=Time.now.to_f
	loop {
		if(joy.pending?)
		
			ev = joy.ev
			ancien=ev
		else
			ev=ancien
		end

		case ev.type
		when Joystick::Event::INIT
			puts 'init'
		when Joystick::Event::BUTTON
			puts "axis: #{ev.num}, #{ev.val}"
			temps=Time.now.to_f - temps.to_f
		      	if ev.num == 3 && ev.val ==1		     		
				if(etat!="avance" || temps>100)				
				etat="avance"				
				j.avance
				end
		      	elsif ev.num == 0 && ev.val ==1
		      		if(etat!="recule" || temps>100)
				etat="recule"
				j.recule
				end
		      	
		      	elsif ev.num == 2 && ev.val ==1
				if(etat!="gauche" || temps>100)
				etat="gauche"		      		
				j.tourneGauche
				end
		      	
		      	elsif ev.num == 1 && ev.val ==1
				if(etat!="droite" || temps>100)		      		
				etat="droite"				
				j.tourneDroite
				end
			
			else
				#j.reset
		      	end

		when Joystick::Event::AXIS
=begin
			if(ev.num==1 || ev.num==0)
			puts "axis: #{ev.num}, #{ev.val}"
			end
			temps=Time.now.to_f - temps.to_f
		      	if ev.num == 0 && ev.val < -30000		     		
				if(etat!="avance" || temps>100)				
				etat="avance"				
				j.avance
				end
		      	elsif ev.num == 0 && ev.val > 30000
		      		if(etat!="recule" || temps>100)
				etat="recule"
				j.recule
				end
		      	
		      	elsif ev.num == 1 && ev.val < -1600
				if(etat!="gauche" || temps>100)
				etat="gauche"		      		
				j.tourneGauche
				end
		      	
		      	elsif ev.num == 1 && ev.val >1600
				if(etat!="droite" || temps>100)		      		
				etat="droite"				
				j.tourneDroite
				end
			
			else
				#j.reset
		      	end
=end
   		 end
  	}
	
}

