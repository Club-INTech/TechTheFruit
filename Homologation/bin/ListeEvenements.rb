require "GestionEvenements"
require "Log"
require "Position"

# Utiliser @log, @robot, et @carte
class ListeEvenements < GestionEvenements

        def setup
                @compteur = 0
        end
        
        def evTimer
                if @compteur > 0
                        @compteur -= 1
                end
        end

        def evArretUrgence
                # return
                if @compteur > 0
                        return true
                end
                
                capteurs = @robot.ultrasons
                
                @log.debug capteurs.inspect
                
                # if capteurs[0] >= 10 && capteurs[0] <= 200
                #         @log.debug "Obstacle AvG"
                #         
                #         sens = @robot.sens
                #         positionBloquee = @robot.position.clone
                #         positionBloquee.x += capteurs[0] * Math.cos(@robot.position.angle)
                #         positionBloquee.y += capteurs[0] * Math.sin(@robot.position.angle)
                #         
                #         if !@carte.estBloque? positionBloquee
                #                 @carte.bloquerZone(positionBloquee, 10)
                #                 @robot.stop
                #         end
                # end
                if capteurs[1] > 10 && (capteurs[1] >= 5000 || capteurs[1] <= 400) && @robot.tempsRestant > 5 && @carte.quelleZone(@robot.position) != 24
                        @log.debug "Obstacle AvM"
                        
                        sens = @robot.sens
                        positionBloquee = @robot.position.clone
                        positionBloquee.x += (capteurs[1]/2) * Math.cos(@robot.position.angle)
                        positionBloquee.y += (capteurs[1]/2) * Math.sin(@robot.position.angle)
                        
                        if positionBloquee.existe? && !@carte.estBloque?(positionBloquee)
                                @carte.bloquerZone(positionBloquee, 10)
                                @robot.stop
                        end
                end
                # if capteurs[2] >= 10 && capteurs[2] <= 200
                #         @log.debug "Obstacle AvD"
                #         
                #         sens = @robot.sens
                #         positionBloquee = @robot.position.clone
                #         positionBloquee.x += capteurs[2] * Math.cos(@robot.position.angle)
                #         positionBloquee.y += capteurs[2] * Math.sin(@robot.position.angle)
                #         
                #         if !@carte.estBloque? positionBloquee
                #                 @carte.bloquerZone(positionBloquee, 10)
                #                 @robot.stop
                #         end
                # end
                if capteurs[3] >= 10 && capteurs[3] <= 400
                        # @log.debug "Obstacle Ar"
                        # @robot.stop
                end		
        end

        def evStockageTomates
                if (@robot.placeTotal >= 4)
                        @robot.rouleauIndirect
                else
                        if (@robot.placeSurRailGauche < @robot.placeSurRailDroit)
                                @robot.selecteurDroite
                        else
                                @robot.selecteurGauche
                        end
                end
        end

        # def evBlocage
        #         if @compteur > 0
        #                 return true
        #         end
        #         
        #         # @log.debug "Blocage ? -> " + @robot.blocage?.to_s
        #         if @robot.blocage?
        #                 sens = @robot.sens
        #                 zoneBloquee = @robot.position.clone
        #                 # @carte.bloquerZone(zoneBloquee, 10)
        #                 
        #                 @compteur = 50    
        #         end
        # end

end
