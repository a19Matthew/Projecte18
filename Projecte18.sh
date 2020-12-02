#!/bin/bash

#Definim la funció que dona informació a l'usuari de la comanda.
usage(){
cat <<EOF	
	Utilització: $0 [-d] [-r] [-a] nomUsuari 

	-d Deshabilita l'usuari [Opcional]
	-r Esborra l'usuari [Opcional]
	-a Fa un backup del home de l'usuari a /archives/user.tar.gz [Opcional]

EOF
}
#Aquesta funció guarda la id de l'usuari.
getId(){	
	id=`id -u $1 2>/dev/null`
	check=$?
	if [ "$check" == 1 ];then
		echo "ERROR: L'usuari "$1" no existeix"
		ERROR=1
	fi
	if [ $id -gt 1000 ];then
		echo "Usuari "$1" té un id major de 1000"
		vulnerable=1
	fi
	if [ $id -lt 1000 ];then
		echo "Usuari "$1" té un id menor de 1000."
		echo "Aquest usuari no pot ser bloquejat o esborrat."
	fi
}

#Funció que bloqueja l'usuari
lockUser(){
	usermod -L $1
	chage -E0 $1
	usermod -s /sbin/nologin $1
	echo "Usuari "$1" bloquejat satisfactoriament"
}

#Esborra l'usuari, la carpeta home i l'email.
deleteUser(){
	userdel -r $1
}

#Fem backup de l'usuari
backupUser(){
	userdir=`eval echo ~$1`
	date=`date +"%y-%m-%d-%s"`
	filename=`echo $1"."$date".tar.gz"`
	path=`echo $userdir"/"$filename`
	`cd $userdir`
	`tar -czf $filename .`
	`mv $filename /archives/$filename`
	echo "Backup d'usuari "$1" fet a /archives/"$filename
}

#Iniciem el geotops amb les corresponents opcions
while getopts ":d:r:a:" o; do
	case "${o}" in
	d)
		#Agafem el parametre de -d
		USUARI=$OPTARG
		getId $USUARI
		if [ "$vulnerable" == 1 ];then
			lockUser $USUARI
		fi
		;;
	r)
		#Agafem el parametre de -r
		USUARI=$OPTARG
		getId $USUARI
		if [ "$vulnerable" == 1 ];then
			deleteUser $USUARI
		fi
		;;
	a)
		#Agafem el parametre de -a
		USUARI=$OPTARG
		backupUser $USUARI
		;;
	:)
		#Aquest case s'activarà quan NO passem un parametre
		#a les opcions que les necessiten.
		#També guardarem el nom de l'opció sense parametre
		#en la variable RE per donar informació mes endevant.
		echo "ERROR: Opció -$OPTARG requereix un argument" 1>&2
		RE=$OPTARG
		ERROR=1
		;;
	\?)
		#Aquest case s'activarà quan es introdueix una opció
		#que no esta contemplada per geotops.
		echo "ERROR: Opció invalida -$OPTARG" 1>&2
		ERROR=1
		;;
	esac
done

#Aquesta condició es dona si l'usuari no ha escrit
#cap opció en la comanda.La variable RE s'utilitza
#aqui per evitar mostrar aquest error si ja se sap
#que s'ha passat aquesta opció sense parametre.
if [ -z $USUARI ] && [ "$RE" != "d" ] && [ "$RE" != "r"  ] && [ "$RE" != "a" ]; then
	echo "ERROR: Cal inserir almenys una opció -d, -r o -a" 1>&2
	ERROR=1
fi
#En cas que hagi hagut algun error, es cridarà a
#la funció usage i sortirem de l'escript amb un codi error.
if [ "$ERROR" == 1 ];then
	usage
	exit 1
fi
