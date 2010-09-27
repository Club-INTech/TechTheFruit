#!/usr/bin/ruby -I../lib

require "CarteTechTheFruit"

require "Position"
require "Log"

class Robot
        def initialize
                @position = Position.new
        end

        def position
                @position
        end
        def goTo x, y, angle
                @position = Position.new x, y, angle
                @position.prettyprint
                true
        end
end

        
        def calculAngle(liste)
                n = []
                n.push liste.first
                angleP = liste.first.angle
                for i in (1..liste.size - 2)
                        angle = Vecteur.new(liste[i-1], liste[i+1]).angle
                        if angle == angleP
                                n.pop
                        end
                        n.push Position.new(liste[i].x, liste[i].y, angle)
                        angleP = angle
                end
                n
        end

destination = Position.new(2625, 1886, 0)
carte = CarteTechTheFruit.new
robot = Robot.new

log = Logger.instance

# carte.bloquerZone(Position.new(100, 1000, 0), 10)

points = calculAngle([robot.position] + carte.goTo(robot.position, destination)) - [robot.position]
points.each { |point|  p point }
exit
while !points.empty?
        prochainPoint = points.first
        retour = robot.goTo prochainPoint.x, prochainPoint.y, 0
        if !retour
                log.debug "Obstacle détecté"
                nouvelleListe = carte.goTo(robot.position, destination)
                if nouvelleListe.first == prochainPoint
                        # Aller retour
                        log.debug "Aucune issue"
                        sleep(1)
                else
                        # Nouveau chemin
                        log.debug "Issue trouvée"
                        points = nouvelleListe
                end
        else
                points -= [prochainPoint] 
        end
end

# points.each { |point|  p point }
