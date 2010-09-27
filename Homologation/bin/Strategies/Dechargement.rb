require "Strategie"
require "Vecteur"

require "Log"

class Dechargement < Strategie

        def initialize
                @log = Logger.instance
		@log.info "Stratégie Dechargement chargée"
                # temps requis, points gagnés, position de départ
                super(1, 1200, Point.new(2000,2000)) # dernier paramètre faux
        end
        
        def condition
                true
        end
        
        def sequence
                deplacement 2700,1889,0
		# scrip de dechargement à ecrire
        end
end
