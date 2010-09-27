require "GestionEvenements"
require "Log"

class ListeEvenements < GestionEvenements

        def evArretUrgence
		capteurs = @robot.ultrasons
		if capteurs[4]!=0 && capteurs[4]<=400
			#Logger.instance.debug "alerte AvG"
			#condition_AvG=true
		end
		if capteurs[5]!=0 && capteurs[5]<=400
			#Logger.instance.debug "alerte AvD"
			#condition_AvD=true
		end
		if capteurs[6]!=0 && capteurs[6]<=400
			Logger.instance.debug "alerte ArG"
			@robot.stopUrgence
			#condition_ArG=true
		end
		if capteurs[7]!=0 && capteurs[7]<=400
			Logger.instance.debug "alerte ArD"
			@robot.stopUrgence
			#condition_ArD=true
		end
                # 
                # 
                #       
                #       angle = @robot.angle
                #       r=200
                # if condition_AvG && condition_AvD
                #       puts " il y a un robot devant nous, STOP !"
                #       @carte.bloquerZone(@robot.position+Point.new(Math.cos(angle)*r,Math.sin(angle)*r),1) # 1 pour une seconde
                #       @robot.stop
                # elif condition_ArG && condition_ArD
                #       puts "il y a un robot derrière nous STOP !" #pourquoi on s'arrête si le robot adverse est "derrière" nous?
                #       @carte.bloquerZone(@robot.position+Point.new(Math.cos(angle)*r,Math.sin(angle)*r),1) # 1 pour une seconde
                #       @robot.stop
                # end
				
        end

	def evStockageTomates
		placeRG = @robot.placeRailGauche
		placeRD = @robot.placeRailDroit
		if (placeRG<=placeRD) 
			@robot.selecteurGauche
		else
			@robot.selecteurDroit
		end
		if (placeRD==0 && placeRG==0)
			@robot.stopSelecteur
		end
	end
        
end
