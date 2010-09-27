# Ce fichier contient l'ensemble des fonctions accessibles par les scripts
# ie les stratégies.
# Author::    Guillaume Rose  (mailto:guillaume.rose@gmail.com)
# Copyright:: Copyright (c) 2010 INTech - TechTheFruit
# License::   GPL

require "Log"

require "Detection"
require "Position"
require "Asservissement"
require "Actionneurs"
require "Evitement.rb"

# Cette classe est le robot (couche finale). Elle contient toutes les fonctions
# accessibles par les scripts.

class Robot

        # Temps restant, décrémente de seconde en seconde
        attr_reader :tempsRestant

        # Initialise les connexions avec les liaisons série avec les Arduinos.
        # Attributions dynamiques des identifiants ttyUSB.
        def initialize positionDebut = Position.new(0, 0, 0), couleur = :jaune
                @log = Logger.instance
                @tempsRestant = 90
		
		#pas encore utilisé mais laisser car bientot ...
		@couleur=couleur
                identifiantArduino = {
                        0 => "Asservissement", 
                        1 => "Actionneurs", 
                        2 => "Evitement"
                }

                @log.info "Initialisation du robot..."

                detectionPeripherique = Detection.new(identifiantArduino).association
                @asservissement = Asservissement.new detectionPeripherique["Asservissement"], positionDebut
                @actionneurs = Actionneurs.new detectionPeripherique["Actionneurs"]
                @evitement = Evitement.new detectionPeripherique["Evitement"]

                reset

                @log.info "Initialisation finie"
                
                allumerLed
        end

        # Démarre chaque service. Si activeTimer est vrai, alors le robot
        # s'arrête au bout de 90 secondes.
        def demarrer
                @log.info "Démarrage..."

                @asservissement.demarrer
                @actionneurs.demarrer
                @evitement.demarrer

                @log.info "Robot démarré"
        end

        def demarrerTimer
                @timer = Thread.new {
                        @log.info "Démarrage du timer"
                        for i in (1..90)
                                @tempsRestant -= 1
                                sleep 1
                        end
                        @asservissement.arreter
                        @actionneurs.arreter
                        @evitement.arreter
                        @log.info "Fin du temps réglementaire"
                        exit
                }
        end
        
        def arreterTimer
                @timer.exit
        end

        # Arrêt des services
        def arreter
                @log.info "Arrêt..."

                @asservissement.arreter
                @actionneurs.arreter
                @evitement.arreter

                @log.info "Robot arrêté"
        end

        # Reset du robot
        def reset
                @log.info "Reset..."
                @asservissement.reset
                @log.info "Reset effectué"
                1
        end

        # Abscisse du robot
        def x
                @asservissement.position.x
        end

        # Ordonnée du robot
        def y
                @asservissement.position.y
        end

        # Orientation du robot par rapport à (Ox)
        def angle
                @asservissement.position.angle
        end

        # Position du robot
        def position
                @asservissement.position
        end

        #
        # Evitement
	#
	
        # Valeurs des capteurs ultrason
        def ultrasons
                @evitement.ultrasons
        end

        # Contrôle d'état des ultrason haut
        def etatHaut
                @evitement.controleEtatHaut
        end

        # Valeurs des capteurs optiques
        def optiques
                @evitement.optiques
        end

	#place sur rail gauche
	def placeSurRailGauche
		@evitement.placeSurRailGauche
	end

	#place sur rail droit
	def placeSurRailDroit
		@evitement.placeSurRailDroit
	end
	
	def placeTotal
		#placeSurRailDroit + placeSurRailGauche
		return (5-@evitement.nombreOranges)
	end

        #
        # Asservissement
        #
        
        # Desactive l'asservissement
        def desactiveAsservissement
                @log.debug "Désactive l'asservissement polaire"
                @asservissement.desactiveAsservissement
                1
        end

        # Desactive l'asservissement
        def desactiveAsservissementRotation
                @log.debug "Désactive l'asservissement polaire"
                @asservissement.desactiveAsservissementRotation
                1
        end

        # Desactive l'asservissement
        def desactiveAsservissementTranslation
                @log.debug "Désactive l'asservissement angulaire"
                @asservissement.desactiveAsservissementTranslation
                1
        end

        # Déplace le robot en x, y avec une orientation angle
        # Renvoi vrai si aucun stop durant la manoeuvre
        def goTo x, y, angle, *condition
                @log.info "Aller à : " + x.to_s + ", " + y.to_s + ", " + angle.to_s
                @asservissement.goTo Position.new(x, y, angle)
        end

        # Change l'orientation du robot par rapport à la position du robot
        def tourneDe angle
                @log.info "Tourne de : " + angle.to_s
                @asservissement.tourneDe angle
                1
        end

        # Retourne l'état des codeuses pour la calibration
        def codeuses
                @asservissement.codeuses
        end

        # Envoi un signal d'arrêt à l'arduino, sort du goTo en cours
        def stop
                @log.info("Envoi du signal d'arrêt à l'arduino")
                @asservissement.stop
                1
        end

        # Arrêt d'urgence
        def stopUrgence
                @log.info "Arrêt d'urgence"
                @asservissement.stopUrgence
                1
        end

        # Recalage du robot
        def recalage
		@asservissement.recalage                
                1
        end
        
        def recalage2
                @asservissement.recalage2 :x, :negatif, 168
                goTo 400, position.y, 0, :bypass
                @asservissement.recalage2 :y, :negatif, 168
                goTo position.x, 400, 0, :bypass
                goTo 400, -400, 0
                1                
        end
        
        def recalage3
                @asservissement.recalage3
                1
        end

        # Retourne vrai si le robot est bloqué
        def blocage?
                @asservissement.blocage
        end
        
        # Sens positif (1) ou négatif (0) du robot
        def sens
                @asservissement.sens
        end
        
        #
        # Actionneurs
        #
        
	# Allume la led du jumper
	def allumerLed
	        @actionneurs.allumerLed
	end
	
	# Retourne l'état du jumper, prise jack
	def attendreJumper
	        @log.info "Attente du jumper"
		while @actionneurs.etatJumper != 1
		        sleep 0.1
		end
		@log.info "Jumper débloqué"
	end
		
	# Vide les oranges en baissant la fourche
	def baisseFourche
                @actionneurs.baisseFourche
	end
	
	# Attrape les oranges en relevant la fourche
	def leveFourche
                @actionneurs.leveFourche
	end

	def rangeFourche
                @actionneurs.rangeFourche
	end
	
        def actionneursStopUrgence
               @actionneurs.stopUrgence
        end
	
        def rouleauDirect
                @actionneurs.rouleauDirect
        end
        
        def rouleauIndirect
		@log.debug "Envoi signal rouleau"
                @actionneurs.rouleauIndirect
        end
        
        def stopRouleau
                @actionneurs.stopRouleau
        end
        
        def selecteurGauche
                @actionneurs.selecteurGauche
        end
        
        def selecteurDroite
                @actionneurs.selecteurDroite
        end

	def selecteurMilieu
		@actionneurs.selecteurMilieu
	end
        
        def stopSelecteur
                @actionneurs.stopSelecteur
        end

	def ronald
		p = IO.popen(str = "totem '/home/intech/TechTheFruit/Démonstration/ronald mcdonald insanity.mp3'")
		
		10.times {
			tourneDe 1
			tourneDe -2
		}

		tourneDe 6

		IO.popen("killall totem")
	end
	
	def changerVitesse(rotation, translation)
	        @asservissement.changerVitesse(rotation, translation)
	end
	
end
