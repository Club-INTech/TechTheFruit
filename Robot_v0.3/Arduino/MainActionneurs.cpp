/**
 * \file MainActionneurs.cpp
 * \brief Permet de controler les actionneurs
 *
 * exécute les ordres qui lui sont passées, voici la liste des ordres :\n\n
 * "?" quelle carte est-tu (ie 1) \n
 * "a" lit la valeur du jumper \n
 * "b" allume la led \n ok
 * "c" arrete les actions \n
 * "d" range le bras, dangereux si rails pleins \n //11 bras rangés
 * "e" monte le bras, verrouillage oranges \n //01 bras montésc
 * "f" baisse le bras \n //10 bras en bas
 * "g" démarre le rouleau sens montant \n
 * "h" démarre le rouleau sens descendant \n
 * "i" stoppe le rouleau \n
 * "j" oriente les tomates vers la gauche \n
 * "k" oriente les tomates vers la droite \ni
 * "l" mesure du courant oranges\n
 * "m" mesure du courant rouleau\n
 * "n" lire position bras\n
 */

#include <Servo.h> 

//Commandes moteurs : 
//oranges : 
const int pwmO = 3;//pin acceptant du pwm : 3-5-6-9-10-11
const int dirO = 2;
//rouleau : 
const int pwmR = 5;
const int dirR = 4;
//sélecteur :
const int sel = 6;
Servo selServo;
//jumper : 
const int jmp = 7;
//led : 
const int led = 8;

//Contrôle courant : 
//oranges : 
const int ccO = 5;
//rouleau : 
const int ccR = 0;
//capteurs bras oranges : 
const int brO1 = 13; 
const int brO2 = 12;
int posDemO = 0;//0=rangé, 1=intermédiaire, 2=bas
int sensO = 1;//sens descente
int sensOC = 0;//sens montant

//oscillateur sel : 
char actifSel = 0;
int refSel = 92;//valeur autour de laquelle osciller.
int amplitude = 5;//amplitude du mouvement
int dernEtat = 92;//dernière position du sélecteur.
int periode = 250;//(millisecondes)
int previousMillis = 0;//dernier changement.
int refG = 85;
int refD = 60;

//Valeurs max des pwm
const int maxO = 255;
const int maxR = 255;

//derniers sens rouleau : 
int tmpR = 0;
//Valeur max des courants : 
const int maxC = 512;
const int maxMax = 400;//seuil spécial oranges, le moteur semble avoir un courant d'appel au démarrage assez impressionnant (et long?).
//Compteur de dépassement : 
int depO = 0, depR = 0; 

/**
 * \fn void setup()
 * \brief initialise la connection série à 57600 bauds
 */
void setup() {
	Serial.begin(57600);
	pinMode(pwmO,OUTPUT);
	pinMode(dirO,OUTPUT);
	pinMode(pwmR,OUTPUT);
	pinMode(dirR,OUTPUT);
	pinMode(led,OUTPUT);
	pinMode(sel,OUTPUT);
	digitalWrite(led,0);
	pinMode(jmp,INPUT);
	pinMode(ccO,INPUT);
	pinMode(ccR,INPUT);
	pinMode(brO1,INPUT);
	pinMode(brO2,INPUT);
	selServo.attach(sel);

	// hack pwm interdit, overclock by Bobo pour accélérer le pwm.
	TCCR2B &= ~(1 << CS20);
	TCCR2B &= ~(1 << CS22);
	TCCR2B |= (1 << CS21);
}

/**
 * \fn void loop()
 * \brief traitera en permanence les commandes qui lui sont passées
 */
void loop() {
	char c=0;
	unsigned long currentMillis = millis();
	if (Serial.available()!=0) {
		c=Serial.read();
		switch(c) {
			case '?' :
				Serial.println("1");
				break;
			case 'a' :
				lireJumper();
				break;
			case 'b' :
				allumerLed();
				Serial.println("1");
				break;
			case 'c' :
				arreteTout();
				Serial.println("1");
				actifSel = 0;
				break;
			case 'd' :
				rangeBras();
				Serial.println("1");
				break;
			case 'e' :
				monteBras();
				Serial.println("1");
				break;
			case 'f' :
				baisseBras();
				Serial.println("1");
				break;
			case 'g' :
				demarreRouleauHaut();
				Serial.println("1");
				actifSel = 1;
				break;
			case 'h' :
				demarreRouleauBas();
				Serial.println("1");
				actifSel = 1;
				break;
			case 'i' :
				stoppeRouleau();
				Serial.println("1");
				break;
			case 'j' :
				tomateGauche();
				Serial.println("1");
				actifSel = 1;
				break;
			case 'k' :
				tomateDroite();
				Serial.println("1");
				actifSel = 1;
				break;
			case 'l' :
				Serial.println(analogRead(ccO));
				break;
			case 'm' : 
				Serial.println(analogRead(ccR));
				break;
			case 'n' : 
				lirePositionBras();
				break;
		}
	}
	//les raffraichissement pour le contrôle des courants.(Rouleau)
	controleCourantRouleau();
	/*if (analogRead(ccR)>maxC) {
		depR++;
	}
	else {
		if (depR!=0){
			depR--;
		}
		else {
			depR=0;
		}
	}
	if (depR>=1000) {
		analogWrite(pwmR,0);
		depR=1000;
	}*/
	//Oscillations selecteur tomates
	if (actifSel !=0 ){
		if (currentMillis - previousMillis > periode){
			previousMillis = currentMillis;
			oscilleSel();
			//Serial.println("go");
		}
	}
	//mouvement bras
	bougeBras(posDemO);	
}

/**
 * \fn void lireJumper()
 * \brief revoie l'état du jumper à l'eeepc
 * 
 * lie l'état (branché ou non) du jumper pour déclencher le démarrage du robot.
 * 
 */
void lireJumper() {
	Serial.println(digitalRead(jmp));
}

/**
 * \fn void allumerLed()
 * \brief allume la led
 * 
 * allume la led pour montrer que le robot est prêt à partir.
 * 
 */
void allumerLed() {
	digitalWrite(led,1);
}

/**
 * \fn void arreteTout()
 * \brief arrête tous les actionneurs
 * 
 * met tous les pwm à 0, ce qui stoppe les actionneurs
 * 
 */
void arreteTout() {
	analogWrite(pwmO,0);
	analogWrite(pwmR,0);
}

/**
 * \fn void rangeBras()
 * \brief Fait rentrer le bras dans sa position rentrée dans le robot.
 * 
 * Quelle que soit la position actuelle du bras, il retourne dans sa position haute à partir de la valeur mesurée par le potar.
 * 
 */
void rangeBras() {
	posDemO = 0;
}

/**
 * \fn void monteBras()
 * \brief Fait monter le bras dans sa position prise d'oranges
 * 
 * Quelle que soit la position actuelle du bras, il va dans sa position prise d'oranges à partir de la position mesurée par le potar.
 * 
 */
void monteBras() {
	posDemO = 1;
}

/**
 * \fn void baisseBras()
 * \brief Fait descendre le bras dans sa position basse
 * 
 * Quelle que soit la position actuelle du bras, il va dans sa position basse à partir de la position mesurée par le potar.
 * 
 */
void baisseBras() {
	posDemO = 2;
}

/**
 * \fn int controleCourantOrange()
 * \brief Controle le non dépassement du seuil anti-grillage du pont en H des oranges.
 * 
 * Mesure et vérifie que le courant traversant le pont en H du bras des oranges ne dépasse pas le seuil choisi.
 * 
 * \return code d'erreur : 1 en cas de dépassement, 0 sinon.
 */
int controleCourantOrange(){
	if (analogRead(ccO)>maxMax) {
		//Serial.print(analogRead(ccO));
		//Serial.print(" ");
		depO++;
	}
	else {
		if (depO!=0){
			depO--;
		}
		else {
			depO=0;
		}
	}
	if (depO>=10) {
		stoppeBras();
		return 1;
		//Serial.println("pb");
	}
	return 0;
}

/**
 * \fn void bougeBras(int posDemO)
 * \brief Fait bouger les bras
 *
 * Fait bouger les bras pour les faire aller dans la position demandée
 *
 * \param posDemO Position demandée 
 *
 */
void bougeBras(int posDemO){
	if (posDemO == 0){//on monte
		while (digitalRead(brO1)!=1 || digitalRead(brO2)!=1) {
			digitalWrite(dirO,sensOC);
			analogWrite(pwmO,maxO);
			controleCourantOrange();
		}
		stoppeBras();

	}
	else if (posDemO == 1) {//y faut voir...
		while (digitalRead(brO1)!= 0 || digitalRead(brO2)!= 1){
			if((digitalRead(brO1) == 0 && digitalRead(brO2) == 0) || (digitalRead(brO1) == 1 && digitalRead(brO2) == 0)){//je suis en dessous, je monte
				digitalWrite(dirO,sensOC);
				analogWrite(pwmO,maxO);
				controleCourantOrange();
			}
			else {//je descends
				digitalWrite(dirO,sensO);
				analogWrite(pwmO,maxO);
				controleCourantOrange();
			}
		}
		stoppeBras();
	}
	else {//on descend
		while (digitalRead(brO1)!=1 || digitalRead(brO2)!=0) {
			digitalWrite(dirO,sensO);
			analogWrite(pwmO,maxO);
			controleCourantOrange();
		}
		stoppeBras();
	}
}

/**
 * \fn void stoppeBras()
 * \brief Arrête le bras
 * 
 * Quoiqu'il fasse, le bras s'arrête.
 * 
 */
void stoppeBras(){
	analogWrite(pwmO,0);
}

/**
 * \fn void demarreRouleauBas()
 * \brief Fait tourner le rouleau, sens descendant
 * 
 * Active le pwm du rouleau avec comme sens celui descendant (si le cablage est bien fait). 
 * 
 */
void demarreRouleauBas() {
	digitalWrite(dirR,0);
	analogWrite(pwmR,maxR);
	tmpR = 0;
}

/**
 * \fn void demarreRouleauHaut()
 * \brief Fait tourner le rouleau, sens montant
 * 
 * Active le pwm du rouleau avec comme sens celui montant (si le cablage est bien fait). 
 * 
 */
void demarreRouleauHaut() {
	digitalWrite(dirR,1);
	analogWrite(pwmR,maxR);
	tmpR = 1;
}

/**
 * \fn int controleCourantRouleau()
 * \brief Controle le non dépassement du seuil anti-grillage du pont en H des oranges.
 * 
 * Mesure et vérifie que le courant traversant le pont en H du bras des oranges ne dépasse pas le seuil choisi.
 * 
 * \return code d'erreur : 1 en cas de dépassement, 0 sinon.
 */
int controleCourantRouleau(){
	if (analogRead(ccR)>maxMax) {
		//Serial.print(analogRead(ccO));
		//Serial.print(" ");
		depR++;
	}
	else {
		if (depR!=0){
			depR--;
		}
		else {
			depR=0;
		}
	}
	if (depR>=10) {
		stoppeRouleau();//on coupe avant de tout griller
		delay(50);//on lui laisse le temps de s'arrêter
		if (tmpR==0) {
			demarreRouleauHaut();
		}
		if (tmpR==1) {
			demarreRouleauBas();
		}
		delay(500);//on tente de le débloquer
		stoppeRouleau();
		delay(50);//on lui laisse le temps de s'arrêter
		if (tmpR==0){
			demarreRouleauBas();
		}
		if (tmpR==1){
			demarreRouleauHaut();
		}
		return 1;
		//Serial.println("pb");
	}
	return 0;
}

/**
 * \fn void stoppeRouleau()
 * \brief Arrête le rouleau
 * 
 * Quoi qu'il fasse (y compris blocage) le rouleau s'arrête de tourner.
 * 
 */
void stoppeRouleau() {
	analogWrite(pwmR,0);
}

/**
 * \fn void tomateGauche()
 * \brief envoie les tomates vers la gauche
 * 
 * Active le pwm du moteur sélecteur pour envoyer les tomate vers la gauche.
 * 
 */
void tomateGauche() {
	refSel = refG;
	//selServo.write(92);
}

/**
 * \fn void tomateDroite()
 * \brief envoie les tomates vers la droite
 * 
 * Active le pwm du moteur sélecteur pour envoyer les tomates vers la droite. 
 * 
 */
void tomateDroite() {
	refSel = refD;
	//selServo.write(122);
}

/**
 * \fn void oscilleSel()
 * \brief fait osciller le bras en continu
 *
 * Fait osciller le bras en continue
 *
 */
void oscilleSel(){
	if (dernEtat == refSel - amplitude){
		dernEtat = refSel + amplitude;
		//Serial.println("G");
	}
	else {
		dernEtat = refSel - amplitude;
		//Serial.println("D");
	}
	selServo.write(dernEtat);
}

/** 
 * \fn void lirePositionBras()
 * \brief lie et envoie la position actuelle des bras
 * 
 * Lie et envoie le code de la position actuelle des bras.
 * 
 */
void lirePositionBras() {
	Serial.print(digitalRead(brO1));
	Serial.print("\t");
	Serial.println(digitalRead(brO2));
}
