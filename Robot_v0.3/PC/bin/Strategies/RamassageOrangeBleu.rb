require "Strategie"
require "Vecteur"

require "Log"

class RamassageOrangeBleu < Strategie

        def initialize
                # temps requis, points gagnés, position de départ
                super(25, 1200, Position.new(0, 0, 0))
                
                @log = Logger.instance
        end
        
        def condition
                true
        end
        
        def sequence
                deplacement 1500, 1500, 0
                # Carte calculée à chaque checkpoint, mauvais
                # La carte doit gérer l'évitement (aller retour sur place 
                # si plus aucun chemin possible, abandon au bout d'un nombre
                # d'essai)
                # carte.parcours Position.new(100, 0, 0)
                
        	# robot.goTo 46.5, 0, 0
                # Thread.new { robot.prendreOranges }
                # sleep 1.3
                # Thread.new {
                #       sleep 0.4
                #       robot.viderOranges 
                # }
                # robot.goTo 22, -4.5, 0 
                # robot.goTo 42, -8.5, 0
                # robot.goTo 48.5, -8.5, 0
                # Thread.new { robot.prendreOranges }
                # sleep 1.5
                # robot.goTo 43, -8.5, 0
                # robot.goTo -15, 0, (Math::PI/3)
                # robot.goTo 0, 30, (Math::PI/3)
                # robot.goTo 150, 100, (Math::PI/2)
                # robot.viderOranges
                # robot.viderOranges
        end
        
        def deplacement(x, y, angle)
                destination = Position.new(x, y, angle)
                points = calculAngle([@robot.position] + @carte.goTo(@robot.position, destination)) - [@robot.position]
                while !points.empty?
                        prochainPoint = points.first
                        retour = @robot.goTo prochainPoint.x, prochainPoint.y, prochainPoint.angle
                        if !retour
                                @log.debug "Obstacle détecté"
                                nouvelleListe = calculAngle(@carte.goTo(@robot.position, destination))
                                if nouvelleListe.first == prochainPoint
                                        # Aller retour
                                        @log.debug "Aucune issue"
                                        sleep(1)
                                else
                                        # Nouveau chemin
                                        @log.debug "Issue trouvée"
                                        points = calculAngle([@robot.position] + @carte.goTo(@robot.position, destination)) - [@robot.position]
                                end
                        else
                                points -= [prochainPoint] 
                        end
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
        
        
end