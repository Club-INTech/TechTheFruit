require "Position"

class Strategie
        
        attr_reader :temps, :points, :depart
        
        def initialize(temps, points, depart)
                @temps = temps
                @points = points
                @depart = depart
        end
        
        def donnerRessources robot, carte
                @robot = robot
                @carte = carte
        end
        
        def sequence
                1
        end
        
        def condition
                true
        end
        
end