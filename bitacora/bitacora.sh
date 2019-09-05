 #!/bin/bash

if [ -f db1 ]; then

   # SI LA BASE DE DATOS EXISTE ENTONCES CREARA UNA SEGUNDA PARA COMPARAR CON LA PRIMERA.
   # PARA ELLO RECUPERARA LA RUTA A EXAMINAR DEL ARCHIVO .CFG, LA DE LA BITACORA
   # LAS BANDERAS DE LOS CAMPOS A CONSIDERAR PARA LA COMPARACION DE LAS BASES DE DATOS

   echo -e "\n\nLa base de datos db1 existe.\nSe creará otra base de datos para comparar archivos y el resultado se guarará en la bitácora."


   ######################################## ACTUALIZA ARCHIVO CONFIGURACION.CFG
   # VERIFICA QUE HAYA BANDERAS. EN EL CASO DE HABERLAS LAS ESCRIBIRÁ EN UN ARCHIVO FLAGS
   # FILTRARA SOLO LAS OPCIONES VÁLIDAS Y ESCRIBIRÁ UN ARCHIVO TEMPORAL DE
   # CONFIGURACIONES, RECUPERA EL TEXTO DE LA RUTA DEL SISTEMA DE ARCHIVOS
   # A EXAMINAR Y LA DE LA BITÁCORA, BORRARÁ EL ANTERIOR Y RENOMBRARÁ EL TEMPORAL.
   # ASÍ, SE TIENEN LOS CAMPOS DE LAS BANDERAS ANTES DE COMPARAR SI SE HAN MODIFICADO

   actualizarconfig=0
   if [ $# -ne 0 ]; then
     rm flags 2>> errores.log
     while [ $# -gt 0 ]
     do
       echo $1 >> flags 2>> errores.log
       actualizarconfig=1
       shift
     done
   else
     echo ""
   fi

   # SI HAY BANDERAS VUELVE A HACER EL ARCHIVO DE CONFIGURACION CON LAS BANDERAS
   if [ $actualizarconfig -eq 1 ]; then
     # ANIADE TODOS LOS PARAMETROS DESACTIVADOS
     echo -e "#USTED PUEDE ACTIVAR O DESACTIVAR LOS PARAMETROS PARA LA COMPARACION DE MODIFICACIONES.\n#PARA ACTIVARLOS BORRE EL SIMBOLO DE #. PARA ACTIVARLOS AGREGUELO ANTES DEL GUIÓN MEDIO '-'.\n#MANTENGA SIEMPRE ACTIVADO -I\n# NUMERO DE INODO\n-I\n# PERMISOS\n#-P\n# NUMERO DE LIGAS\n#-L\n# DUENO\n#-D\n# GRUPO\n#-G\n# TAMANO DEL ARCHIVO\n#-T\n# FECHA DE ULTIMO ACCESO\n#-A\n# FECHA DE ULTIMA MODIFICACION\n#-M\n# FECHA DE ULTIMA MODIFIACION AL CONTENIDO DEL INODO\n#-C\n" > configuracion.tmp 2>> errores.log
     # ANIADE LAS RUTAS DE EXPLORACION Y GUARDADO DE BITACORA
     sed -n '/SIS/,/log/p'  configuracion.cfg 2>> errores.log >> configuracion.tmp 2>> errores.log
     # ANIADE LOS PARAMETROS DE LAS BANDERAS
     sed -e 's/[^IPLDGTAMC-]//g' -e 's/-\{2,\}//g' -e 's/[A-Z][A-Z]//g' -e 's/-$//g' flags >> configuracion.tmp 2>> errores.log
     # ACTUALIZA EL ARCHIVO DE CONFIGURACIONES
     rm configuracion.cfg flags 2>> errores.log
     mv configuracion.tmp configuracion.cfg
   else
     echo ""
   fi

   ##########################################################################


   # RECUPERAR LA RUTA DE DONDE EMPEZAR LA REVISION DEL ARCHIVO CONFIGURACION.CFG
   ruta=$(sed -n '/^SISARCH/p' configuracion.cfg | sed 's/SISARCH=//g')


   # RECUPERAR LA BITACORA
   bitacora=$(sed -n '/^BITACORA/p' configuracion.cfg | sed 's/BITACORA=//g')

   # CREACION BASE DE DATOS 2

	ls -liRu  --time-style=+%s $ruta 2>> errores.log | tr -s " " " " | tr -t " " ":" | cut -f1-7 -d: > datosacceso 2>> errores.log
	ls -liR   --time-style=+%s $ruta 2>> errores.log | tr -s " " " " | tr -t " " ":" | cut -f1,7 -d: > datosmodi 2>> errores.log
	ls -liRc  --time-style=+%s $ruta 2>> errores.log | tr -s " " " " | tr -t " " ":" | cut -f1,7 -d: > datosinodo 2>> errores.log
	paste -d : datosacceso datosmodi datosinodo > datos 2>> errores.log
	cut datos -f1-7,9,11 -d: | sed -e 's/rwx/7/g' -e 's/rw-/6/g' -e 's/r-x/5/g' -e 's/r--/4/g' -e  's/-wx/3/g' -e 's/-w-/2/g' | sed -e 's/--x/1/g' -e 's/---/0/g' -e '/^\./d' -e '/^:/d' -e '/^total/d' -e '/\./d' -e '/\//d'| sort -k1g -t":" | grep  '^.*:.*:.*:.*:.*:.*:.*:.*:.*$' | uniq > db2 2>> errores.log
	rm datosacceso datosmodi datosinodo datos 2>> errores.log



	# RECUPERA LOS CAMPOS QUE SE QUIEREN TOMAR EN CUENTA EN LA COMPARACION.
	# ANTE DE ELLO LIMPIA POR SI HAY ESPACIOS EN BLANCO SALTOS DE LINEA
	# Y OMITE LAS LINEAS QUE NO EMPIECEN CON -
	# DE ESTA MANERA SE TENDRA TODAS LAS LINEAS DE PARAMETROS Y SE LES ORDENARA
	# Y QUITARA DUPLICADOS- FINALMENTE TODAS ESAS LINEAS LA HARA UNA SOLA
	# Y FILTRARA LOS CAMPOS QUE CORRESPONDAN PARA VER SI HAY DIFERENCIAS

	# PARA LA BASE BASE DE DATOS 1

	columnas_flag="$(sed -e '/^[^-]/d' -e '/#/d' -e 's/[[:space:]]//g'  -e '/^$/d'  configuracion.cfg | sed -e '/-I/c\1' -e '/-P/c\2' -e '/-L/c\3' -e '/-D/c\4' -e '/-G/c\5' -e '/-T/c\6' -e '/-A/c\7' -e '/-M/c\8' -e '/-C/c\9' | sort -g | uniq | paste -s -d",")"
	echo $clumnas_flag > columnas1.txt  2>> errores.log
	cut -f$columnas_flag -d: db1 > temporaldb1 2>> errores.log

	# PARA LA BASE DE DATOS 2

	columnas_flag="$(sed -e '/^[^-]/d' -e '/#/d' -e 's/[[:space:]]//g'  -e '/^$/d'  configuracion.cfg | sed -e '/-I/c\1' -e '/-P/c\2' -e '/-L/c\3' -e '/-D/c\4' -e '/-G/c\5' -e '/-T/c\6' -e '/-A/c\7' -e '/-M/c\8' -e '/-C/c\9' | sort -g | uniq | paste -s -d",")"
	echo $clumnas_flag > columnas2.txt 2>> errores.log
	cut -f$columnas_flag -d: db2 > temporaldb2 2>> errores.log

	# COMPARA SI HAY DIFERENCIAS

	diff temporaldb1 temporaldb2 | sed -e '/^[^><]/d' -e 's/[<>] //g' | sort -k1g -t":" | grep  '^.*:.*:.*:.*:.*:.*:.*:.*:.*$' | uniq  > diferencias 2>> errores.log
	rm columnas1.txt columnas2.txt temporaldb1 temporaldb2 2>> errores.log   #BORRA ARCHIVOS UTILIZADOS


###############################################################################
###############################################################################
# DE NO EXISTIR LA BASE DE DATOS ENTONCES EMPIEZAN LAS CONSIDERACIONES PARA CREARLA

else

	touch errores.log
  rm configuracion.cfg 2> errores.log
	echo -e "#USTED PUEDE ACTIVAR O DESACTIVAR LOS PARAMETROS PARA LA COMPARACION DE MODIFICACIONES.\n#PARA ACTIVARLOS BORRE EL SIMBOLO DE #. PARA ACTIVARLOS AGREGUELO ANTES DEL GUIÓN MEDIO '-'.\n#MANTENGA SIEMPRE ACTIVADO -I\n# NUMERO DE INODO\n-I\n# PERMISOS\n#-P\n# NUMERO DE LIGAS\n#-L\n# DUENO\n#-D\n# GRUPO\n#-G\n# TAMANO DEL ARCHIVO\n#-T\n# FECHA DE ULTIMO ACCESO\n#-A\n# FECHA DE ULTIMA MODIFICACION\n#-M\n# FECHA DE ULTIMA MODIFIACION AL CONTENIDO DEL INODO\n#-C"  > configuracion.cfg 2>> errores.log                      # SE CREA EL ARCHIVO DE CONFIGURACIONES

	# PREGUNTA SI SE DESEA ESPECIFICAR EL DIRECTORIO PARA LA BASE DE DATOS. POR DEFECTO ES /HOME

	echo -e "Bienvenido al analizador de cambios en el sistema de archivos\n\n"
	echo -e "Se realizará por primera vez la base de datos del sistema de archivos.\nIndique si desea revisar el sistema de archivos del directorio sobre un directorio específico.\n\n1) Sí\n2) No\n"
	elegir_banderas=0
	read opcion
	case $opcion in
		2)
			echo -e "#SISTEMA DE ARCHIVOS\nSISARCH=/" >> configuracion.cfg 2>> errores.log
			elegir_banderas=1
      ruta=/
		;;
		1)
			echo -e "\nEspecifique con la ruta absoluta del directorio el cual desea revisar.\nPor ejemplo: /home/usuario/\n"
			read ruta
			if [ -d $ruta -a -r $ruta ]; then
				echo -e "\nEl directorio existe. \nSobre $ruta se hará la revisión del sistema de archivos.\n"
				echo -e "#SISTEMA DE ARCHIVOS\nSISARCH=$ruta" >> configuracion.cfg 2>> errores.log   #AGREGA LA RUTA A EXAMINAR AL ARCHIVO DE CONFIGURACION
				elegir_banderas=1
			else
				echo -e "\nEl directorio no existe o no se puede leer. Vuelva a ejecutar el programa con una ruta válida\n"; exit 0;   # SI NO EXISTE ESE DIRECTORIO SE CIERRA EL PROGRAMA
			fi
		;;
		*)
			echo -e "\nOpcion no válida.\nInicie de nuevo el programa e introduzca una ruta de directorio existente.\n"; exit 0; # DE IGUAL MANERA SE CIERRA ANTE UNA OPCION NO VALIDA
		;;
	esac

	# PREGUNTA SI SE DESEA DETERMINAR LA UBICACION DE LA BITACORA

	echo -e "\n¿Desea especificar la ruta de creación del archivo bitacora.log?\nEste archivo mantendrá los registros de los archivos que sufrieron alguna modificación en sus atributos.\n\n1) Sí\n2) No\n"
	read opcion
	case $opcion in
		2)
			echo -e "#BITA_CORA\nBITACORA=bitacora.log" >> configuracion.cfg 2>> errores.log                    # AGREGA LA UBICACION DEFAULT DE LA BITACORA AL ARCHIVO DE CONFIGURACION QUE ES EL MISMO DIRECTORIO
			elegir_banderas=1
		;;
		1)
			echo -e "\nIndique la ruta donde se generará el archivo bitacora.log, el cual contendrá los datos de los archivos modificados.\nPor ejemplo: /home/usuario\n"
			read camino
			if [ -d $camino -a  -w $camino ]; then
				echo -e "\nEl directorio existe. Sobre $ruta se hará la revisión del sistema de archivos."
				bitacora=$(echo $camino | sed 's/\/$//g')
				bitacora="$bitacora/bitacora.log"
				echo -e "#BITA_CORA\nBITACORA=$bitacora" >> configuracion.cfg 2>> errores.log                     # AGREGA LA UBICACION AL ARCHIVO DE CONFIGURACION SI EL DIRECTORIO EXISTE. SI NO EXISTE EL DIRECTORIO O PONE UNA OPCION NO VALIDA SE TERMINA EL PROGRAMA

			else
				echo -e "\nEl directorio no existe o no es posible escribir en él. Vuelva a ejecutar el programa con una ruta válida\n"; exit 0;
			fi
		;;
		*)
			echo -e "\nOpcion no válida.\nInicie de nuevo el programa e introduzca una ruta de directorio existente o con permisos de escritura.\n"; exit 0;
		;;
	esac


	# DETERMINAR LAS BANDERAS
	# LE PREGUNTA AL USUARIO SI QUIERE ESPECIFICAR CUALES SE EMPLEARAN PARA COMPRAR. POR DEFAULT SON TODAS.
	# LA MANERA DE PONERLAS SON LAS OPCIONES SEGUIDAS Y CON GUIONES: -A-B-C-D-E...

	if [ $elegir_banderas -eq 1 ]; then
		echo -e "Estos son los campos a considerar al comparar las bases de datos del sistema de archivos:\n\n"
		echo -e "-I Número de i-nodo\n-P Permisos\n-L Número de ligas por archivo\n-D Dueño del archivo\n-G Grupo del archivo\n-T Tamaño del archivo\n-A Fecha de último acceso\n-M Fecha de última modificación del archivo\n-C Fecha de última modificación del contenido del i-nodo\n\n"
		echo -e "¿Desea seleccionar algunos campos en específico?\n\n1) Sí\n2) No\n"
		read opcion
		case $opcion in
			1)
				echo -e "\nIntroduzca los que desea comparar de la siguiente manera, por ejemplo, los primeros cinco parámetros: -I-P-L-D-G\n"
				read banderas
			;;
			2)
				echo -e "\nTodos los campos anteriores serán considerados."
				banderas="-I-P-L-D-G-T-A-M-C"                                                        # POR DEFAULT
			;;
			*)
				echo -e "\nOpción no válida. Vuelva a ejecutar el programa"; exit 0
			;;
		esac
	else
		exit 0
	fi

	# INTEGRAR LAS BANDERAS AL ARCHIVO DE CONFIGURACION
	# REVISA QUE NO HAYA OTROS CARACTERES QUE NO CORRESPONDAN A LAS OPCIONES, QUITA GUIONES CONSECUTIVOS Y AÑADE AL ARCHIVO DE CONFIGURACION LAS QUE SE VAN A UTILIZAR

	banderalimpio=$(echo $banderas | sed -e 's/[^IPLDGTAMC-]//g' -e 's/-\{2,\}//g' -e 's/[A-Z][A-Z]//g' -e 's/-$//g')

	echo $banderalimpio | sed  -e 's/-I/# NUMERO DE INODO\n-I\n/1'  -e 's/-P/# PERMISOS\n-P\n/1' -e 's/-L/# NUMERO DE LIGAS\n-L\n/1' -e 's/-D/# DUENO\n-D\n/1' -e 's/-G/# GRUPO\n-G\n/1' -e 's/-T/# TAMANO DEL ARCHIVO\n-T\n/1' -e 's/-A/# FECHA DE ULTIMO ACCESO\n-A\n/1' -e 's/-M/# FECHA DE ULTIMA MODIFICACION\n-M\n/1' -e 's/-C/# FECHA DE ULTIMA MODIFIACION AL CONTENIDO DEL INODO\n-C\n/1' >> configuracion.cfg 2>> errores.log

	# CREACION BASE DE DATOS 1
	# SE USA LS Y SE EXTRAE LA LINEA HASTA LOS TIEMPOS EN FORMATO EPOCH. LUEGO SE PEGAN Y SE CORTA LAS COLUMNAS REPETIDAS.
	# SE TRADUCEN LOS PERMISOS A SU FORMA OCTAL

	ls -liRu  --time-style=+%s $ruta 2>> errores.log | tr -s " " " " | tr -t " " ":" | cut -f1-7 -d: > datosacceso 2>> errores.log
	ls -liR   --time-style=+%s $ruta 2>> errores.log | tr -s " " " " | tr -t " " ":" | cut -f1,7 -d: > datosmodi 2>> errores.log
	ls -liRc  --time-style=+%s $ruta 2>> errores.log | tr -s " " " " | tr -t " " ":" | cut -f1,7 -d: > datosinodo 2>> errores.log
	paste -d : datosacceso datosmodi datosinodo > datos
	cut datos -f1-7,9,11 -d: | sed -e 's/rwx/7/g' -e 's/rw-/6/g' -e 's/r-x/5/g' -e 's/r--/4/g' -e  's/-wx/3/g' -e 's/-w-/2/g' | sed -e 's/--x/1/g' -e 's/---/0/g' -e '/^\./d' -e '/^:/d' -e '/^total/d' -e '/\./d' -e '/\//d'| grep  '^.*:.*:.*:.*:.*:.*:.*:.*:.*$' | sort -k1g -t":" | uniq > db1 2>> errores.log #
	rm datosacceso datosmodi datosinodo datos 2>> errores.log  # SE BORRAN LOS ARCHIVOS UTILIZADOS TEMPORALMENTE
	touch bitacora.log camino 2>> errores.log
	rm camino 2>> errores.log

	echo -e "\nLa base de datos ha sido creada satisfactoriamente. Se llama db1.\nSe encuentra en el mismo directorio en el que ha ejecutado este programa.\n\nPara que se añadan datos a la bitácora vuelva a ejecutar el programa y consulte el archivo $(pwd)/bitacora.log.\n\n\n\n"
	exit 0

fi
