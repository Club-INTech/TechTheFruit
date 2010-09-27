# Gestion de l'asservissement en x, y
# ie les stratégies.
# Author::    Guillaume Rose  (mailto:guillaume.rose@gmail.com)
# Copyright:: Copyright (c) 2010 INTech - TechTheFruit
# License::   GPL

require "Log"

require "Point"
require "Vecteur"

require "InterfaceAsservissement"

# Cette classe gère l'asservissement

class Asservissement

        # Précision du goTo : cercle à partir duquel on n'envoit plus de 
        # nouvelle consigne
        attr_accessor :precisionSimple

        # Précision du goTo : cercle à partir duquel on déblocage le déroulement
        # de la stratégie
        attr_accessor :precisionDouble

        # Initialise l'asservissement à partir d'un périphérique série, valeurs 
        # par défaut pour la précision
        def initialize peripherique, positionParDefaut = Position.new(0, 0, 0)
                @log = Logger.instance

                if peripherique == nil
                        raise "Pas de carte pour Asservissement" 
                end

                @log.debug "Asservissement sur " + peripherique

                @precisionSimple = 50
                @precisionDouble = 20

                @drapeauArret = false

                @interface = InterfaceAsservissement.new peripherique, 57600, positionParDefaut
                @interface.demarrer

                # changerVitesse([0, 0])
                # changerAcceleration([0, 0])
                # changerPWM([0, 0])
                # changerKp([0, 0])

                @log.debug "Asservissement prêt"
        end

        # Position du robot
        def position
                @interface.position
        end

        # Reset l'Arduino et active l'odométrie
        def demarrer
                @log.debug "Activation de l'odométrie"
                @interface.activeOdometrie
        end

        # Arrête le robot
        def arreter
                @log.debug "Arrêt de l'asservissement"
                @interface.stopUrgence

                @log.debug "Désactivation de l'odométrie"
                @interface.desactiveOdometrie
        end

        # Reset l'odométrie, des consignes et des codeuses sur l'arduino
        def reset
                @interface.reset
        end

        # Remise à zéro de l'arduino, changement de la position du robot
        def remiseAZero nouvellePosition = Position.new(0, 0, 0)
                @log.debug "Remise à zéro des consignes et des codeuses"
                @interface.remiseAZero nouvellePosition
        end

        # Se déplace en absolu à la destination indiquée
        def goTo destination, *condition
                @drapeauArret = false

                if evaluationConditionArret(*condition)
                        stop
                        @log.debug "Condition d'arrêt vérifiée"
                        return false
                end

                # Zone 51 ...
                v = Vecteur.new(position, destination)
                if v.norme < 500
                        tourneDe((v.angle - position.angle) % (2 * Math::PI), *condition)
                end

                corrigeTrajectoire destination	               

                i = 0
                while i < 200 && (distance = Vecteur.new(position, destination).norme) >= @precisionDouble
                        # En cas de stop, on arrête de corriger la position
                        # On sort alors du goTo
                        if evaluationConditionArret(*condition)
                                stop
                                @log.debug "Blocage ou arrêt, on sort du goTo"
                                return false
                        end

                        if distance >= @precisionSimple
                                corrigeTrajectoire destination
                        end

                        i += 1
                        sleep 0.05
                end

                if i >= 200
                        @log.debug "Problème pour atteindre la destination (timeout)"
                end

                tourneDe(destination.angle - position.angle, *condition)

                @log.debug "Fin Aller à : " + position.x.to_s + ", " + position.y.to_s  + ", " + position.angle.to_s

                true
        end

        # Corrige la trajectoire pour atteindre la destination
        def corrigeTrajectoire destination
                v = Vecteur.new(position, destination)

                angleAFaire = (v.angle - position.angle) % (2 * Math::PI)

                if angleAFaire > Math::PI 
                        angleAFaire -= 2 * Math::PI
                end

                if (angleAFaire > Math::PI / 2) || (angleAFaire < -Math::PI / 2)
                        consigneDistance = -1 * v.norme 
                        if (angleAFaire - Math::PI - position.angle).abs > Math::PI
                                consigneAngle = angleAFaire + Math::PI 
                        else
                                consigneAngle = angleAFaire - Math::PI 
                        end 
                else
                        consigneDistance = v.norme
                        consigneAngle = angleAFaire
                end

                @interface.envoiConsigne consigneDistance, consigneAngle
        end

        def evaluationConditionArret *eval
                if eval.include?(:bypass)
                        false
                else
                        if eval.empty?
                                eval = []
                        end
                        retour = @drapeauArret
                        eval.each { |f|  
                                retour |= send(f)
                        }
                        retour
                end
        end

        # Tourne relativement à la position du robot
        #--
        # Timeout 5sec pour faire la rotation, à changer
        #++
        def tourneDe angleDonne, *condition
                positionInitiale = position.angle

                if evaluationConditionArret(*condition)
                        return false
                else
                        @interface.envoiConsigneAngle angleDonne	               
                end

                i = 0
                while i < 50 && (position.angle - positionInitiale - angleDonne).abs >= 0.05
                        if evaluationConditionArret(*condition)
                                @log.debug "Condition d'arrêt vérifiée pour la rotation"
                                stopUrgence
                                return false
                        end
                        i += 1
                        sleep 0.1
                end

                if i >= 50
                        @log.debug "Problème pour atteindre la rotation (timeout)"
                end

                @log.debug "Rotation finie"

                true
        end

        # Désactive l'asservissement
        def desactiveAsservissement
                @interface.desactiveAsservissementTranslation
                @interface.desactiveAsservissementRotation
        end

        # Désactive l'asservissement en translation
        def desactiveAsservissementTranslation
                @interface.desactiveAsservissementTranslation
        end

        # Désactive l'asservissement en rotation	
        def desactiveAsservissementRotation
                @interface.desactiveAsservissementRotation
        end

        # Renvoi l'état des codeuses
        def codeuses
                @interface.codeuses
        end

        # Renvoi l'état du robot, bloqué ou non
        def blocage
                tableau = @interface.blocage
                if tableau[0] != 0 || tableau[1] != 0
                        true
                else
                        false
                end
        end

        def blocageTranslation
                @interface.blocageTranslation
        end

        def blocageRotation
                @interface.blocageRotation
        end

        def recalage
                desactiveAsservissementRotation
                goTo Position.new(-1000, 0, 0), :blocageTranslation
                sleep 1
                goTo Position.new(-1000, 0, 0), :blocageTranslation
                remiseAZero Position.new(147.5, 0, 0)
                sleep 1
                desactiveAsservissementRotation
                goTo Position.new(300, position.y, Math::PI/2), :bypass
                
                desactiveAsservissementRotation
                goTo Position.new(300, -1000, Math::PI/2), :blocageTranslation
                sleep 1
                goTo Position.new(300, -1000, Math::PI/2), :blocageTranslation
                remiseAZero Position.new(position.x, 147.5, Math::PI/2)
                sleep 1
                desactiveAsservissementRotation
                goTo Position.new(position.x, 300, 0), :bypass
                goTo Position.new(300, 300, 0), :bypass
        end	

	def recalage2 direction, sens, coordonneeReset, avancementMax = 1000
                positionIntermediaire = position.clone
                
                if direction == :x
                        positionIntermediaire.angle = positionIntermediaire.angle - (positionIntermediaire.angle % 2 * Math::PI)
                        positionIntermediaire.prettyprint
                        puts goTo positionIntermediaire
                        
                        desactiveAsservissementRotation

                        if sens == :positif
                                positionIntermediaire.x += avancementMax
                        else
                                positionIntermediaire.x -= avancementMax
                        end
                        positionIntermediaire.prettyprint                        
                        puts goTo positionIntermediaire, :blocageTranslation
                        
                        sleep 1
                        
                        puts goTo positionIntermediaire, :blocageTranslation

                        remiseAZero Position.new(coordonneeReset, position.y, position.angle)
                else
                        positionIntermediaire.angle = positionIntermediaire.angle - (positionIntermediaire.angle % 2 * Math::PI) + (Math::PI / 2)
                        goTo positionIntermediaire
                        
                        desactiveAsservissementRotation

                        if sens == :positif
                                positionIntermediaire.y += avancementMax
                        else
                                positionIntermediaire.y -= avancementMax
                        end
                        
                        goTo positionIntermediaire, :blocageTranslation
                        
                        sleep 1
                        
                        goTo positionIntermediaire, :blocageTranslation

                        remiseAZero Position.new(position.x, coordonneeReset, position.angle)
                end
                
                desactiveAsservissementRotation
	end


        # Arrêt progressif du robot
        def stop
                @drapeauArret = true
                @interface.stop
        end

        # Arrêt brutal du robot
        def stopUrgence
                @drapeauArret = true
                @interface.stopUrgence
        end
        
        def changerVitesse(valeur)
                @interface.changerVitesse(valeur)
        end

        # Change l'accélération du robot
        def changerAcceleration(valeur)
                @interface.changerAcceleration(valeur)
        end
        
        def changerPWM(valeur)
                @interface.changerPWM(valeur)
        end
        
        def changerKp(valeur)
                @interface.changerKp(valeur)
        end
        
end
