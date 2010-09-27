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
                @robot.attendreJumper
                                
                @robot.demarrerTimer
                @evenements.demarrer
                
                # while @robot.tempsRestant > 0
                #       @decisions.position = @robot.position
                #       @decisions.tempsRestant = @robot.tempsRestant
                #@decisions.meilleurChoix.sequence
                # end
                # 
                @robot.goTo 5000, 0, 0
                
                @robot.arreterTimer
                                
                @evenements.arreter
                @robot.arreter
        end

end
