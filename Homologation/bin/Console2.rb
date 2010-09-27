#!/usr/bin/ruby -I../lib

require "readline"

require "Robot"

robot = Robot.new
robot.demarrer

robot.desactiveAsservissement

loop {
	puts robot.ultrasons.inspect
}

robot.arreter
