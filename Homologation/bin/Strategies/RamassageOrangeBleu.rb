require "Strategie"
require "Vecteur"

require "Log"

class RamassageOrangeBleu < Strategie

        def initialize
                # temps requis, points gagnés, position de départ
                super(25, 1200, Position.new(300, -300, 0))
                
                @log = Logger.instance
        end
        
        def condition
                false
        end
        
        def sequence
                # @robot.goTo 295, 295, 3.14
                # @robot.baisseFourche
                # @robot.selecteurMilieu
                # @robot.goTo 1130, 295, 3.14, :bypass
                # @robot.leveFourche
                # sleep 1
                @robot.goTo 300, -300, 0
                @robot.rouleauDirect
                @robot.changerVitesse(1500, 1500)
                deplacement 2680, 1889, 1.57
                @robot.rouleauIndirect
                sleep 2
                @robot.stopRouleau
                
                if @robot.goTo 2680, -1889, 1.57
                        @robot.baisseFourche
                        sleep 1
                        @robot.goTo 2680, -1839, 1.57
                        @robot.goTo 2680, -1889, 1.57
                        @robot.goTo 2680, -1839, 1.57
                        @robot.goTo 2680, -1889, 1.57
                        sleep 2
                end
        end
        
        def deplacement(x, y, angle)
                destination = Position.new(x, y, angle)
                position = @robot.position.symetrie
                points = chemin(destination, position)
		precedent = [position.clone]
                while !points.empty?
                        
                        puts "Pile"
                        puts points.each { |e| e.prettyprint }
                        prochainPoint = points.first
                        
                        retour = @robot.goTo prochainPoint.x, prochainPoint.y, prochainPoint.angle 
                        return
                        puts retour
                        
                        if (!retour || @carte.estBloque?(position))
                                exit
                                # @log.debug "Obstacle détecté"
                                #                                 
                                #                                 # @carte.bloquerZone(position, 10)
                                #                                 while precedent != [] && @carte.estBloque?(position)
                                #                                        precedent2 = precedent.last
                                #                                        @robot.goTo precedent2.x, precedent2.y, precedent2.angle
                                #                                        precedent -= [precedent.last]
                                #                                end
                                #                                
                                #                                 nouvelleListe = chemin(destination, position)
                                #                                 puts "Pile"
                                #                                 puts points.each { |e| e.prettyprint }
                                #                                 puts "Nouveau"
                                #                                 nouvelleListe.each { |e| e.prettyprint }
                                #                                 if (nouvelleListe.first.y == prochainPoint.y) && (nouvelleListe.first.x == prochainPoint.x)
                                #                                          # Aller retour
                                #                                          @log.debug "Aucune issue"
                                #                                          # sleep(10)
                                #                                        while precedent != [] && @carte.estBloque?(position)
                                #                                                precedent2 = precedent.last
                                #                                                @robot.goTo precedent2.x, precedent2.y, precedent2.angle
                                #                                                precedent -= [precedent.last]
                                #                                        end
                                #                                          
                                #                                          # sleep 5
                                #                                        points = chemin(destination, position)
                                #                                 else
                                #                                          # Nouveau chemin
                                #                                          @log.debug "Issue trouvée"
                                #                                          points = nouvelleListe
                                #                                 end
                                #                                 # points = chemin(destination)
                        else
                                precedent += [prochainPoint]
                                points -= [prochainPoint]
                        end
                end
        end
        
        def chemin(destination, position = Position.new)
                if position == Position.new
                        position = @robot.position
                end
                liste = calculAngle([position] + @carte.goTo(position, destination))
                liste.map! { |e| e.symetrie }
                c = liste - [position.symetrie] + [destination.symetrie]
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
