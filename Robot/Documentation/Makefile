# Ce fichier permet de générer la doc du projet
# Author::    Clément Bethuys  (mailto:clement.bethuys@laposte.net)
# Copyright:: Copyright (c) 2010 INTech - TechTheFruit
# License::   GPL

doc: clean doc-pc doc-arduino

doc-arduino:
	rdoc --inline-source -a -c utf8 -o doc_pc ../PC/bin/*.rb ../PC/lib/*.rb

doc-pc:
	doxygen DoxyConfig

clean:
	rm -rf doc
