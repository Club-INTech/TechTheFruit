# Ce fichier contient la classe Vecteur.
# Author::    Guillaume Rose  (mailto:guillaume.rose@gmail.com)
# Copyright:: Copyright (c) 2010 INTech - TechTheFruit
# License::   GPL

require "Point"

# Cette classe définit les fonctions de base sur les vecteurs.

class Vecteur

	# Un vecteur est défini par son dx et dy
	attr_accessor :x, :y
	
	# Initialisation avec 2 points, départ et arrivée.
	def initialize p, q
		@x = q.x - p.x
		@y = q.y - p.y
	end
	
	# Calcule la norme du vecteur
	def norme
		Math.sqrt(@x**2 + @y**2)
	end

	# Calcule l'angle du vecteur par rapport à l'axe (Ox)
	def angle
		Math.atan2 @y, @x
	end

end
