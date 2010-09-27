require "Strategie"
require "Vecteur"

require "Log"

class RamasseNosOranges < Strategie

        def initialize
                # temps requis, points gagnés, position de départ
                super(25, 1600, Position.new(20, 20, 0))
                
                @log = Logger.instance
        end
        
        def condition
                false
        end
        
        def sequence
                loop {
                        deplacement 1500, 1222, 0
                        deplacement 300, 300, 0
                }
        end
        
        def deplacement(x, y, angle)
                destination = Position.new(x, y, angle)
                points = chemin(destination)
		precedent = @robot.position.clone
                while !points.empty?
                        prochainPoint = points.first
                        retour = @robot.goTo prochainPoint.x, prochainPoint.y, prochainPoint.angle
                        if !retour
                                @log.debug "Obstacle détecté"
                                
                                # @carte.bloquerZone(position, 10)
                                
                                nouvelleListe = chemin(destination)
                                if nouvelleListe.first == prochainPoint
                                         # Aller retour
                                         @log.debug "Aucune issue"
                                         # sleep(10)
					 @robot.goTo precedent.x, precedent.y, precedent.angle
					 sleep 5
                                else
                                         # Nouveau chemin
                                         @log.debug "Issue trouvée"
                                         points = nouvelleListe
                                end
                                # points = chemin(destination)
                        else
                                precedent = prochainPoint
				points -= [prochainPoint] 
                        end
                end
        end
        
        def chemin(destination)
                c = calculAngle([@robot.position] + @carte.goTo(@robot.position, destination)) - [@robot.position] + [destination]
		c -= [c.first]
		c.each { |point|  point.prettyprint }
		c
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
        
end
