<?php 
	
	$host = 'localhost';
	$user = 'root';
	$password = '';
	$db = 'sistema_facinv';

	$conection = @mysqli_connect($host,$user,$password,$db);

	if(!$conection){
		echo "Error en la conexión";
	}

?>