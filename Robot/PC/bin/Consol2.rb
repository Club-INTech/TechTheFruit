#!/usr/bin/ruby -I../lib

require "readline"

require "Robot"
robot = Robot.new(:jaune, Position.new(300, 300, 0))
robot.demarrer
sleep(3)
puts "gogo"

robot.recalageJaune
robot.goTo 600, 722
robot.goTo 1500,1500
@interface.changerPWM([0, 1023])
loop {
	robot.position.prettyprint
}
