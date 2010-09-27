# Ce fichier contient la classe d'interfaçage de l'asservissement. Elle permet 
# une communication avec l'Arduino d'asservissement.
# Author::    Guillaume Rose  (mailto:guillaume.rose@gmail.com)
# Copyright:: Copyright (c) 2010 INTech - TechTheFruit
# License::   GPL

require "SerieThread"
require "Log"

require "Position"

# Cette classe convertit les consignes en commandes en ticks. Elle hérite des
# fonctions permettant la liaison série.
#--
#  * Ajouter des mutex entre callback et l'envoi de position (problème de timing possible)
#++

class InterfaceAsservissement < SerieThread

        # Contient la position du robot à chaque instant
        attr_accessor :position

        # Constantes permettant la conversion en coordonnées polaires et 
        # cartésiennes
        attr_accessor :conversionTicksDistance, :conversionTicksAngle

        # * Initialise la liaison série avec un périphérique à une vitesse donnée
        # * Définit les valeurs par défaut aux constantes
        def initialize(peripherique = "/dev/ttyUSB0", vitesse = 57600, positionParDefaut = Position.new(0, 0, 0))
                super(peripherique, vitesse)

                @log = Logger.instance

                @position = positionParDefaut

                @conversionTicksDistance = 9.7316
                @conversionTicksAngle = 1530.9

                @offsetAngulaire = positionParDefaut.angle
                @offsetG = @conversionTicksAngle * positionParDefaut.angle / 2
                @offsetD = -1 * @offsetG

                @encodeurPrecedentG = @offsetG
                @encodeurPrecedentD = @offsetD

                @blocageTranslation = 0
                @blocageRotation = 0
                
                @skip = false
                
                @old_cmd = []
        end

        # Surcharge de la fonction callback héritée de SerieThread afin de 
        # calculer à chaque nouvelle réception de données la nouvelle position
        # du robot.
        def callback retour
                if @skip
                        donnees = retour.split(" ")
                        @skip = false if donnees[0].to_i == 0 && donnees[1].to_i == 0
                else
                        donnees = retour.split(" ")

                        return false if donnees.size != 4

                        encodeurG = @offsetG + donnees[0].to_i
                        encodeurD = @offsetD + donnees[1].to_i

                        @blocageTranslation = donnees[2].to_i
                        @blocageRotation = donnees[3].to_i

                        distance = (encodeurG - @encodeurPrecedentG + encodeurD - @encodeurPrecedentD) / @conversionTicksDistance
                        return false if distance > 1000

                        @position.x += distance * Math.cos(@position.angle)
                        @position.y += distance * Math.sin(@position.angle)

                        @position.angle = (encodeurG - encodeurD) / (@conversionTicksAngle)

                        puts donnees.inspect
                        # puts @position.inspect

                        @encodeurPrecedentG = encodeurG
                        @encodeurPrecedentD = encodeurD
                        # @log.debug "Réception codeuses : " + donnees.inspect

                end
        end

        # Envoi d'une consigne en distance et en angle au robot relatif par
        # rapport à sa position courante
        def envoiConsigne distance, angle		
                a = ((angle - @offsetAngulaire) * @conversionTicksAngle + @encodeurPrecedentG - @encodeurPrecedentD).to_i
                d = (distance * @conversionTicksDistance + @encodeurPrecedentG + @encodeurPrecedentD).to_i

                distanceFormate, angleFormate, commandeDistance, commandeAngle = formatageConsigne d, a
                return if distanceFormate == -1
                ecrire commandeAngle + angleFormate
                ecrire commandeDistance + distanceFormate
        end

        # Envoi d'une consigne en distance et en angle absolue
        def envoiConsigneBrute distance, angle
                distanceFormate, angleFormate, commandeDistance, commandeAngle = formatageConsigne distance, angle
                return if distanceFormate == -1

                ecrire commandeAngle + angleFormate
                ecrire commandeDistance + distanceFormate
        end

        # Envoi d'une consigne en angle
        def envoiConsigneAngle angle
                a = ((angle - @offsetAngulaire) * @conversionTicksAngle + @encodeurPrecedentG - @encodeurPrecedentD).to_i
                distanceFormate, angleFormate, commandeDistance, commandeAngle = formatageConsigne 0, a
                return if distanceFormate == -1
                ecrire commandeAngle + angleFormate
        end

        # Envoi d'une consigne en distance
        def envoiConsigneDistance distance
                d = (distance * @conversionTicksDistance + @encodeurPrecedentG + @encodeurPrecedentD).to_i
                distanceFormate, angleFormate, commandeDistance, commandeAngle = formatageConsigne d, 0
                return if distanceFormate == -1
                ecrire commandeDistance + distanceFormate
        end

        # Demande au robot d'activer l'envoi des données de roues codeuses sur
        # la liaison série
        def activeOdometrie
                ecrire "c"
        end

        # Désactive l'envoi de données
        def desactiveOdometrie
                ecrire "d"
        end

        # Bascule l'état de l'asservissement d'un état vers un autre 
        # (tout ou rien)
        def desactiveAsservissementRotation
                ecrire "i"
        end

        def desactiveAsservissementTranslation
                ecrire "h"
        end

        def desactiveAsservissement
                ecrire "h"
                ecrire "i"
        end

        # Reset du périphérique
        # * Désactivation de l'odométrie
        # * Remise à zéro des consignes et des codeuses
        def reset
                desactiveOdometrie
                ecrire "j"
        end

        # Remise à zéro des codeuses et de la consigne
        def remiseAZero nouvellePosition
                ecrire "j"
                
                @skip = true
                
                @position = nouvellePosition
                
                @offsetAngulaire = nouvellePosition.angle
                @offsetG = @conversionTicksAngle * nouvellePosition.angle / 2
                @offsetD = -1 * @offsetG

                @encodeurPrecedentG = @offsetG
                @encodeurPrecedentD = @offsetD
        end

        # Formate les consignes afin de les transmettre
        def formatageConsigne distance, angle
                if angle > 0
                        commandeAngle = "a"
                else
                        commandeAngle = "f"
                        angle *= -1
                end

                if distance > 0
                        commandeDistance = "b"
                else
                        commandeDistance = "g"
                        distance *= -1
                end

                new_cmd = [distance.to_i.to_s.rjust(8, "0"), angle.to_i.to_s.rjust(8, "0"), commandeDistance, commandeAngle]
                if @old_cmd != new_cmd
                        new_cmd
                        @old_cmd = new_cmd
                else
                        false
                end
        end

        # Renvoi l'état des codeuses gauche et droite
        def codeuses
                [@encodeurPrecedentG, @encodeurPrecedentD]
        end

        # Renvoi l'état des asservissements
        def blocage
                [@blocageTranslation, @blocageRotation]
        end

        # Renvoi vrai si l'asservissement en translation est bloqué
        def blocageTranslation
                (@blocageTranslation != 0)
        end

        # Renvoi vrai si l'asservissement en rotation est bloqué
        def blocageRotation
                (@blocageRotation != 0)
        end

        # Arrêt progressif du robot
        def stop
                ecrire "n"
        end

        # Arrêt brutal du robot
        def stopUrgence
                ecrire "o"
        end

        # Change la vitesse du robot
        def changerVitesse(valeur)
                valeur = [0, 0] if valeur.size != 2
                ecrire "l" + valeur[0].to_s.rjust(8, "0")
                ecrire "r" + valeur[1].to_s.rjust(8, "0")
        end

        # Change l'accélération du robot
        def changerAcceleration(valeur)
                valeur = [0, 0] if valeur.size != 2
                ecrire "k" + valeur[0].to_s.rjust(8, "0")
                ecrire "q" + valeur[1].to_s.rjust(8, "0")
        end
        
        def changerPWM(valeur)
                valeur = [0, 0] if valeur.size != 2
                ecrire "p" + valeur[0].to_s.rjust(8, "0")
                ecrire "t" + valeur[1].to_s.rjust(8, "0")
        end
        
        def changerKp(valeur)
                valeur = [0, 0] if valeur.size != 2
                ecrire "m" + valeur[0].to_s.rjust(8, "0")
                ecrire "s" + valeur[1].to_s.rjust(8, "0")
        end

end
