require "CarteTechTheFruit.rb"
require "sdl.rb"

class Visualisateur

	public 

	# on initialise la SDL, crée la carte, on indique un chemin et on affiche le tout
	def initialize
		SDL.init( SDL::INIT_VIDEO )
		#on fait un ecran "diviseur" fois plus petit que la taille du terrain, @diviseur sera utilise pour l'affichage à l'échelle
		@diviseur=4
		@ecran = SDL::setVideoMode(3000/@diviseur,2100/@diviseur,16,SDL::HWSURFACE)


		if @ecran== false
			puts "problème d'initialisation de la video"
		end

		@ma_carte = CarteTechTheFruit.new

		a=rand(3000)
		b=rand(2100)
		c=rand(3000)
		d=rand(2100)
		ab=Point.new(a,b)
		cd=Point.new(c,d)
		puts "ab=" + ab.inspect.to_s + "cd=" + cd.inspect.to_s 
		depart=Point.new(200,350)
		destination = Point.new(600, 1222)
		a= @ma_carte.goTo(ab,cd)
		puts a.inspect
		puts a.length
		#@ma_carte.goTo(Point.new(200,300),Point.new(2700,300))
		#@ma_carte.goTo(depart,destination)
		#@ma_carte.bloquerZone(Point.new(1050,1000),1)
		#@ma_carte.bloquerZone(Point.new(1500,700),1)
		#@ma_carte.goTo(depart,destination)
		#ma_carte.goTo(Point.new(200,300),Point.new(2700,300))
		demarrer
	end

	# on rerentre dans la boucle infinie d'affichage
	def demarrer
		@on_continu=true
		boucle
	end

	# NOTES pour l'instant cette fonction ne sert a rien tant que l'on a pas de thread
	def arreter
		@on_continu=false
	end

	private

	# on dessine à l'infinie
	def boucle
		while @on_continu
			while event = SDL::Event2.poll
				@ecran.updateRect(0,0,0,0)
				case event
				when SDL::Event2::Quit
					@on_continu=false
				else
					dessiner
				end
			end
		end
	end

	# on appelle la fonction afficher de tous les objets de la listeObjets
	def dessiner
		vert=@ecran.mapRGB(0,255,0)
		@ecran.fillRect(0,0,3000/@diviseur,2100/@diviseur,vert)
		for typeObjet in @ma_carte.listeObjets
			for elem in typeObjet
				elem.afficher(@ecran,@diviseur)
			end
		end
		@ecran.updateRect(0,0,0,0)
	end

	# NOTES n'est pour l'instant jamais appelée
	def finalize
		SDL.quit
	end
end

k=Visualisateur.new
