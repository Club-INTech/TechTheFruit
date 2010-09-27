#!/usr/bin/ruby -I../lib

require "readline"

require "ListeEvenements"
require "RobotMagique"

positionInitiale = Position.new(300, -300, 0)

magicien = RobotMagique.new(positionInitiale, ListeEvenements, "Strategies/")

begin
ligne = Readline.readline("on est de quel cote \n j->jaune\n b->bleu\n", true)
puts ligne
end while (ligne!="j" and ligne!="b")
#ensuite on fait ce que l'on doit faire avec cette info
Readline.readline("Presser une touche pour lancer le robot", true)

magicien.demarrer
