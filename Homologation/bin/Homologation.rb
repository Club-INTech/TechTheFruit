require "Log"

require "Robot"
require "Decisions"
require "CarteTechTheFruit"

class RobotMagique
        
        def initialize(positionInitiale, listeEvenements, repStrategie)
                @carte = CarteTechTheFruit.new
                
                @robot = Robot.new(positionInitiale) 
                @robot.demarrer
                
                @evenements = listeEvenements.new(@robot, @carte)
               
                @decisions = Decisions.new
                @decisions.donnerRessources(@robot, @carte)
                @decisions.chargeRepertoire repStrategie
        end
        
        def demarrer 
                # Bleu : recalage3 et changer signe angle + y
                @robot.recalage
                
                @robot.attendreJumper
                                
                @robot.demarrerTimer
                @evenements.demarrer
                
                # while @robot.tempsRestant > 0
                #       @decisions.position = @robot.position
                #       @decisions.tempsRestant = @robot.tempsRestant
                #@decisions.meilleurChoix.sequence
                # end

                @robot.attendreJumper
                @robot.demarrerTimer

                if @robot.goTo 600, 722, 0.4
                        @robot.rouleauDirect

                        if @robot.goTo 2625, 1847, 1.57
                                @robot.stopRouleau
                                @robot.rouleauIndirect
                        end

                end

		sleep 2
                
                @robot.arreterTimer
                                
                @evenements.arreter
                @robot.arreter
        end

end
