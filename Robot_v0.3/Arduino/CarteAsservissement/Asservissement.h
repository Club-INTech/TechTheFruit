#ifndef Asservissement_h
#define Asservissement_h

// Puissance max. de l'asservissement comprise entre 0 et 1024
#define	PUISSANCE	300

// Constante de l'asservissement, valeur changer dans manager.init()
#define KP		30
#define VMAX		30000
#define ACC		22

#define PRESCALER	256

class Asservissement{
	public:
		Asservissement();
		
		void	changeConsigne(long int);
		
		int 	calculePwm(long int);
		void 	calculePositionIntermediaire(long int);
		
		void 	stop();
		void 	stopUrgence(long int); 
		
		void 	calculeErreurMax();
		
		void 	changeKp(int);
		void 	changeAcc(long int);
		void	changeVmax(long int);
		void 	changePWM(int);
		
		void	reset();

		// Consigne et position du robot (point de vue Arduino)
		long int 	consigne;	
		long int 	positionIntermediaire;
		
		// Consigne et position du robot zoomé
		long int 	consigneZoom;	
		long int 	positionIntermediaireZoom;

		// Constantes de l'asservissement et du moteur	
		int 		Kp; 
		long int 	Acc, Vmax;
		long int 	maxPWM; 
		
		// Distance de freinage		
		long int 	dFreinage; 

		// Palier de vitesse
		long int 	n;	

		// Erreur maximum (sert à détecter les obstacles)
		long int 	erreurMax;	

		// Vaut 1 ou -1 si le moteur est bloqué
		int 		blocageDetecte;
};

#endif
