# Ce fichier contient les fonctions qui permettent de modifier l'état de la carte
# et d'obtenir le chemin pour aller d'un point A à un point B
# Author::    Clément Bethuys  (mailto:clement.bethuys@laposte.net)
# Copyright:: Copyright (c) 2010 INTech - TechTheFruit
# License::   GPL

require "Dijkstra"
require "Point"
require "Vecteur"
require "Lissage"
require "Log"

# C'est l'aire de jeu, avec les fonctions pour la modifier et trouver son chemin dedans
# C'est une classe virtuelle, toujours appeler CarteTechTheFruit qui sa classe fille
class Carte
  
	public

	attr_accessor :listeObjets

	# Crée les structures permettant d'acceuillir les différents objets d'une classe fille
        def initialize
	 	@log = Logger.instance

		@liste_epis= Array.new
		@liste_tomates= Array.new
		@liste_zones_depart= Array.new
		@liste_pente= Array.new
		@liste_chemins= Array.new
		@listeObjets =[@liste_zones_depart,@liste_pente,@liste_epis,@liste_tomates,@liste_chemins]
		@graphe = Dijkstra.new
        end

	# Renvoie le meilleur chemin non lissé pour aller de "posA" à "posB".
	# "posA" est la position de départ du robot et "posB" est la position d'arrivée
	def goTo(posA,posB,pas_intermediaire=true,lisser=false)
		zoneA=quelleZone(posA)
		zoneB=quelleZone(posB)
		if (zoneA==zoneB)
			@log.debug "on est dans la même zone"
			a=[posB]
			if(onPeutPasCouper(posA,posB)) then a.insert(0,@graphe.noeuds[zoneA]) end
			return a
		end	
		a=@graphe.chemin(zoneA,zoneB,pas_intermediaire)
		if(onPeutPasCouper(posA,@graphe.noeuds[zoneA]))
			a.insert(0,posA)
		else a[0]=posA end
		if(not onPeutPasCouper(posB,a[a.length-2]))
			a.pop
		end
		a.push(posB)
                # @log.debuckelbteclementg a.inspect.to_s
		if(lisser)then return a end ## pour l'instant je m'occupe pas du lissage		
		@liste_chemins.push(Chemin.new(a))
		return a
	end

	# Ajoute une tomate en à la position "position" si "securité"=true enlève toute autre tomate déjà présente dans un rayon "rayon"
        def ajouterTomate(position,securise=false,rayon=22)
		if(securise)
			enleverTomate(position,rayon)
		end
		@liste_tomates.push(Tomate.new(position))
        end
        
	# Enlève toute tomate à la position "position" présente dans un rayon "rayon"
	def enleverTomate(position,rayon=22)
		numTomate=numObjetLePlusProche(@liste_tomates,position,rayon)
		numTomate.each{ |num|
		@liste_tomates.delete_at(num)
		}
	end
	
	# Ajoute une arrete entre deux noeuds déjà crées
        def ajouterArrete(noeudDepart,noeudArrivee)
		@graphe.ajoutArrete(noeudDepart,noeudArrivee)
        end

	# enlève une arrete entre deux noeuds
	def enleverArrete(noeudDepart,noeudArrivee)
		@graphe.suppArrete(noeudDepart,noeudArrivee)
        end
        
	# Ajoute un épis en à la position "position" si "securité"=true enlève tout autre épis déjà présent dans un rayon "rayon"
        def ajouterEpis(position, securise=false, rayon=22)
		if(securise)
			enleverEpis(position,rayon)
		end
		@liste_epis.push(Epis.new(position))
        end
        
	# Enlève tout épis à la position "position" présente dans un rayon "rayon"
        def enleverEpis(position, rayon = 22)
		numEpis=numObjetLePlusProche(@liste_epis,position,rayon)
		numEpis.each{ |num|
		@liste_epis.delete_at(num)
		}
        end

	# Assigne la distance "distance" entre les zones "premier" et "second" 
	def modifierArrete(premier,second,distance)
		@graphe.modifArrete(premier,second,distance)
	end

	# Bloque toute entree dans la Zone ou "position" se trouve pour une durée "duree"
	def bloquerZone(position,duree)
		zone=quelleZone(position)
		sauv= Array.new
		@graphe.arretes[zone].each_key{ |clef|
		sauv.push(clef)
		sauv.push(@graphe.arretes[clef][zone])
		}
		Thread.new {
		@graphe.arretes[zone].each_key{ |clef| @graphe.arretes[clef][zone]=10000}
		sleep(duree)
		for i in (0 .. sauv.length/2-1)
			clef=sauv[2*i]			
			valeur=sauv[2*i+1]
			@graphe.arrete[clef][zone]=valeur
		end
		}
	end

	# Renvoie la liste des Objets appartenant à "listeObjets" qui sont "decalage" proche de la position "position"
	def numObjetLePlusProche(listeObjets,position,decalage)
		liste=Array.new
		listeObjets.each_index { |index|
			distance=Vecteur.new(listeObjets[index].position,position).norme
			if( distance < decalage)
				liste.push(index)
			end
		}
		return liste
	end

	# renvoie la zone dans laquelle position ce trouve
	def quelleZone(position)
		@graphe.quelleZone(position)
	end

	private

	# Rajoute le noeud numero "numero" qui a pour centre "position"
	# et une fonction "procedure" qui renvoie true uniquement si on lui passe un point à l'intérieur de cette zone
	def ajouterNoeud(numero,position,procedure)
		@graphe.ajoutNoeud(numero,position,procedure)
	end

	# Utilisée pour déterminer si le point "pos" est au dessus ou en dessous de la droite formée par (x1,y1) et (x2,y2).
	# Renvoie un nombre positif si c'est au dessus et négatif si c'est en dessous
	def f(pos,x1,y1,x2,y2)
		return y1 +(y2-y1).to_f/(x2-x1).to_f*(pos-x1)
	end
	
	# Renvoie true si entre "position" et "pointEntree" on est suceptible de rencontrer un épis.
	# Teste en "précision" points et tient compte d'une margeSupplémentaire
	def onPeutPasCouper(position,pointEntre,precision=3,margeSupplementaire=5)
		for i in (0 .. precision)
		barycentre=position*i.to_f/precision + pointEntre*(precision-i).to_f/precision
		if( not numObjetLePlusProche(@liste_epis,barycentre,25+170+margeSupplementaire).empty?) then return true end
		end
		return false
	end
end
