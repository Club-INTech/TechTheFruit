7# Gestion de l'asservissement en x, y
# ie les stratégies.
# Author::    Guillaume Rose  (mailto:guillaume.rose@gmail.com)
# Copyright:: Copyright (c) 2010 INTech - TechTheFruit
# License::   GPL

require "Float"
require "Fixnum"

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

                #@interface.conversionTicksDistance = 9.50
                #@interface.conversionTicksAngle = 1530,9

                @interface.changerVitesse([2000, 2000])
                # @interface.changerAcceleration([10, 10])
                # @interface.changerPWM([512, 300])
                # @interface.changerKp([0, 0])
                # @interface.changerKd([0, 0])

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
                        corrigeTrajectoire destination, :angulaire
                        # tourneDe (v.angle - position.angle)
                end

                corrigeTrajectoire destination	               

                i = 0
                while i < 400 && (distance = Vecteur.new(position, destination).norme) >= @precisionDouble
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

                if i >= 400
                        @log.debug "Problème pour atteindre la destination (timeout)"
                end

                tourneDe(destination.angle - position.angle, *condition)

                @log.debug "Fin Aller à : " + position.x.to_s + ", " + position.y.to_s  + ", " + position.angle.to_s

                true
        end

        # Corrige la trajectoire pour atteindre la destination
        def corrigeTrajectoire destination, *condition
                v = Vecteur.new(position, destination)

                angleAFaire = (v.angle - position.angle).modulo2

                if (angleAFaire > Math::PI / 2) || (angleAFaire < -Math::PI / 2)
                        consigneDistance = -1 * v.norme 
                        if (angleAFaire - Math::PI - position.angle).abs > Math::PI
                                consigneAngle = (angleAFaire + Math::PI ).modulo2
                        else
                                consigneAngle = (angleAFaire - Math::PI).modulo2 
                        end 
                else
                        consigneDistance = v.norme
                        consigneAngle = angleAFaire
                end

                if condition.empty?
                        @interface.envoiConsigne consigneDistance, consigneAngle
                else
                        tourneDe consigneAngle
                end
        end

        def evaluationConditionArret *item
                if item.include?(:bypass)
                        false
                else
                        if item.empty?
                                item = []
                        end
                        retour = @drapeauArret
                        item.each { |f|  
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
                        stop
                        return false
                else
                        @interface.envoiConsigneAngle angleDonne	               
                end

                i = 0
                while i < 100000 && (position.angle - positionInitiale - angleDonne).abs >= 0.05
                        if evaluationConditionArret(*condition)
                                @log.debug "Condition d'arrêt vérifiée pour la rotation"
                                stop
                                return false
                        end
                        i += 1
                        sleep 0.05
                end

                if i >= 100000
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
                # puts @interface.blocageTranslation || @interface.blocageRotation
                @interface.blocageTranslation || @interface.blocageRotation
        end

        def blocageTranslation
                @interface.blocageTranslation
        end

        def blocageTranslationAv
                (@interface.blocageTranslation == 1)
        end

        def blocageTranslationAr
                (@interface.blocageTranslation == -1)
        end

        def blocageRotation
                @interface.blocageRotation
        end

        def blocageRotationAv
                (@interface.blocageRotation == 1)
        end

        def blocageRotationAr
                (@interface.blocageRotation == -1)
        end

        def recalage
                @interface.changerVitesse([1000, 1000])
                
                @interface.changerPWM([300, 1023])

                goTo Position.new(-400, 0, 0), :blocageTranslation
                sleep 1
                goTo Position.new(-400, 0, 0), :blocageTranslation
                remiseAZero Position.new(170, 0, 0)
                sleep 1
                @interface.changerPWM([1023, 1023])
                # sleep 1  
                goTo Position.new(300, position.y, Math::PI/2), :bypass
                @interface.changerPWM([300, 1023])
                goTo Position.new(300, -2500, Math::PI/2), :blocageTranslation
		sleep 1
                goTo Position.new(300, -2500, Math::PI/2), :blocageTranslation
                remiseAZero Position.new(position.x, 170, Math::PI/2)
                # sleep 1
                @interface.changerPWM([1023, 1023])
                goTo Position.new(position.x, 300, Math::PI/2), :bypass
                goTo Position.new(300, 300, 0)
                
                @interface.changerVitesse([2000, 1000])
        end	

        def recalage3
                @interface.changerVitesse([1000, 1000])
                
                @interface.changerPWM([300, 1023])

                goTo Position.new(-400, 0, 0), :blocageTranslation
                sleep 1
                goTo Position.new(-400, 0, 0), :blocageTranslation
                remiseAZero Position.new(170, 0, 0)
                sleep 1
                @interface.changerPWM([1023, 1023])
                # sleep 1  
                goTo Position.new(285, -position.y, -Math::PI/2), :bypass

                @interface.changerPWM([300, 1023])
                goTo Position.new(285, 2500, -Math::PI/2), :blocageTranslation
		sleep 1
                goTo Position.new(285, 2500, -Math::PI/2), :blocageTranslation
                remiseAZero Position.new(position.x, -170, -Math::PI/2)
                # sleep 1
                @interface.changerPWM([1023, 1023])
                goTo Position.new(position.x, -295, -Math::PI/2), :bypass
                goTo Position.new(285, -295, 0)
                
                @interface.changerVitesse([2000, 1000])
        end

        def recalage2 direction, sens, coordonneeReset, avancementMax = 1500
                positionIntermediaire = position.clone

                if direction == :x
                        # Alignement
                        positionIntermediaire.angle = positionIntermediaire.angle - (positionIntermediaire.angle % 2 * Math::PI)

                        if positionIntermediaire.angle > Math::PI 
                                positionIntermediaire.angle -= 2 * Math::PI
                        end

                        positionIntermediaire.prettyprint

                        goTo positionIntermediaire

                        # Recule ou avance sans asservissement rotation
                        @interface.changerVitesse([1000, 1000])
                        @interface.changerPWM([300, 1024])

                        if sens == :positif
                                positionIntermediaire.x += avancementMax
                        else
                                positionIntermediaire.x -= avancementMax
                        end

                        positionIntermediaire.prettyprint  

                        goTo positionIntermediaire, :blocageTranslation

                        sleep 1

                        # On se cale bien 
                        puts goTo positionIntermediaire, :blocageTranslation

                        # Reset
                        remiseAZero Position.new(coordonneeReset, position.y, position.angle)
                else
                        positionIntermediaire.angle = positionIntermediaire.angle - (positionIntermediaire.angle % 2 * Math::PI) + (Math::PI / 2)

                        if positionIntermediaire.angle > Math::PI 
                                positionIntermediaire.angle -= 2 * Math::PI
                        end

                        goTo positionIntermediaire

                        @interface.changerVitesse([1000, 1000])
                        @interface.changerPWM([300, 1024])

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

                @interface.changerVitesse([3000, 3000])
                @interface.changerPWM([1024, 1024])
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

        # Sens de déplacement du robot (1 ou 0)
        def sens
                @interface.sens
        end
        
        def changerVitesse(rotation, translation)
                @interface.changerVitesse([rotation, translation])
        end
        

end
