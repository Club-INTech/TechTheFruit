require 'thread'
require "serialport"

class SerieThread

	def initialize(peripherique = "/dev/ttyUSB0", vitesse = 57600)
		port_str = peripherique
		baud_rate = vitesse
		data_bits = 8
		stop_bits = 1
		parity = SerialPort::NONE

		@sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
		
		#@semaphore = Mutex.new
	end
	
	def ecrire action
		@sp.write action
	end
	
	def demarrer
		@thread = Thread.new {
			while true
				retour = ""
				caractere = ""
				begin
					if ((caractere = @sp.getc) != nil) 
						retour << caractere.chr
					end
				end while caractere != 10
			
				retour = retour.split("\r\n").first
				
				callback retour
			end
		}
	end
	
	def callback retour
		puts retour
	end
	
	def attendreFin
		@thread.join
	end
	
	def arreter
		@thread.exit
	end
	
end

=begin
liaisonSerie = SerieThread.new "/dev/ttyUSB2"
liaisonSerie.demarrer
puts "Démarre"
liaisonSerie.ecrire "c"
sleep 2
liaisonSerie.ecrire "d"
puts "Arrêt"
sleep 1
liaisonSerie.arreter
=end
