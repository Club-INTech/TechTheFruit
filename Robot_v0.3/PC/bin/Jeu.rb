#!/usr/bin/ruby -I../lib

require "readline"

require "ListeEvenements"
require "RobotMagique"

positionInitiale = Position.new(300, 300, 0)

magicien = RobotMagique.new(positionInitiale, ListeEvenements, "Strategies/")

while line = Readline.readline("Presser une touche pour lancer le robot", true)
       break
end

magicien.demarrer
