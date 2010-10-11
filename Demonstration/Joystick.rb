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
		@distance -= 150 # en fait c'est tourner a gauche 
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
		@distance += 150 # en fait c'est tourner a droite
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
		@angle += 300 # en fait c'est avancer
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
		@angle -= 300 # en fait c'est reculer
		if @angle >= 0
			angleFormate = @angle.to_i.to_s.rjust(8, "0")
			ecrire "a" + angleFormate
		else
			angleFormate = (-@angle).to_i.to_s.rjust(8, "0")
			ecrire "f" + angleFormate
		end
		puts @angle
	end

	def baisseBras
		#ecrire "
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

class Con
attr_accessor :type, :val, :num
	def initialize
		@type=1
		@val=0
		@num=0
	end

end
j = Jouet.new

Joystick::Device.open(ARGV[0]) { |joy|
evtemp=""
begin
	evtemp=joy.ev
end while(evtemp.type!=Joystick::Event::BUTTON)
ev=Con.new
ev.type=evtemp.type
ev.val=evtemp.val
ev.num=evtemp.num
#ev=evtemp

temps=Time.now.to_f
	loop {
		#puts "-3-: " + ev.type.to_s
		if(joy.pending?)
			evtemp = joy.ev
			if(evtemp.type==Joystick::Event::BUTTON)
				#puts "-1-: " + ev.type.to_s
				ev.type=evtemp.type
				ev.val=evtemp.val
				ev.num=evtemp.num
				#ev=evtemp
				#puts ev.type
			end
			#puts ev.type
		else
			#puts ev.type
		end

			puts "bouton: #{ev.num}, #{ev.val}"
			 diff=Time.now.to_f - temps.to_f
			#puts "-2-: " + ev.type.to_s
		      	if ev.num == 3 && ev.val ==1		     		
				if(diff>0.1)
				temps=Time.now.to_f				
				#j.avance
				j.tourneGauche
				end

		      	elsif ev.num == 0 && ev.val ==1
		      		if(diff>0.1)
				temps=Time.now.to_f
				#j.recule
				j.tourneDroite
				end
		      	
		      	elsif ev.num == 2 && ev.val ==1
		      		if(diff>0.1)	
				temps=Time.now.to_f	      		
				j.avance
				end
		      	
		      	elsif ev.num == 1 && ev.val ==1
		      		if(diff>0.1)
				temps=Time.now.to_f	
				j.recule
				end
		      	elsif ev.num == 5 && ev.val ==1
		      		if(diff>0.1)
				temps=Time.now.to_f	
				j.levebras
				end
			
			elsif ev.val==0
				puts "on arrete"
		      	end
  	}
}

