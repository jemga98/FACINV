-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 22-09-2021 a las 01:02:13
-- Versión del servidor: 10.4.17-MariaDB
-- Versión de PHP: 7.4.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `facinvconny`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_precio_producto` (`n_cantidad` INT, `n_precio` DECIMAL(10,2), `codigo` INT)  BEGIN
DECLARE nueva_existencia int;
DECLARE nuevo_total decimal(10,2);
declare nuevo_precio decimal(10,2);

 DECLARE cant_actual int;
 DECLARE pre_actual decimal(10,2);
 
 DECLARE actual_existencia int;
 DECLARE actual_precio decimal(10,2);
 
 SELECT precio, existencia INTO actual_precio,actual_existencia FROM producto WHERE codproducto = codigo;
 SET nueva_existencia = actual_existencia + n_cantidad;
 SET nuevo_total = (actual_existencia * actual_precio) + (n_cantidad * n_precio);
 SET nuevo_precio = nuevo_total / nueva_existencia;
 
 
 UPDATE producto SET existencia = nueva_existencia, precio = nuevo_precio  WHERE codproducto = codigo;
  SELECT nueva_existencia, nuevo_precio;
  
  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_detalle_temp` (IN `codigo` INT, IN `cantidad` INT, IN `token_user` VARCHAR(50))  BEGIN

DECLARE precio_actual decimal(10,2);
SELECT precio INTO precio_actual FROM producto WHERE codproducto = codigo;

 INSERT INTO detalle_temp(token_user,codproducto,cantidad,precio_venta) VALUES(token_user,codigo,cantidad,precio_actual);
 
 SELECT tmp.correlativo, tmp.codproducto, p.descripcion, tmp.cantidad, tmp.precio_venta FROM detalle_temp tmp
 INNER JOIN producto p
 ON tmp.codproducto = p.codproducto
 WHERE tmp.token_user= token_user;
 

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `anular_factura` (IN `no_factura` INT)  BEGIN
DECLARE existe_factura int;
DECLARE registros int;
DECLARE a int;
DECLARE cod_producto int;
DECLARE cant_producto int;
DECLARE existencia_actual int;
DECLARE nueva_existencia int;

SET existe_factura = (SELECT COUNT(*)  FROM factura WHERE nofactura = no_factura and estatus = 1);

IF existe_factura > 0 THEN
CREATE TEMPORARY TABLE tbl_tmp (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cod_prod BIGINT,
    cant_prod int);
    SET a = 1;
    SET registros = (SELECT COUNT(*) FROM detallefactura WHERE nofactura= no_factura);
                  IF(registros > 0) THEN
                     INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detallefactura WHERE nofactura = no_factura;
                     WHILE a <= registros DO
                     SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id = a;
                     SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = cod_producto;
                     SET nueva_existencia = existencia_actual + cant_producto;
                     UPDATE producto SET existencia = nueva_existencia WHERE codproducto = cod_producto;
                     
                     SET a=a+1;
                     
                     END WHILE;
                     UPDATE factura SET estatus = 2 WHERE nofactura = no_factura;
                     DROP TABLE tbl_tmp;
                     SELECT * FROM factura WHERE nofactura = no_factura;
                     
                     END IF;                  
    ELSE
    SELECT 0 factura;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `del_detalle_temp` (IN `id_detalle` INT, IN `token` VARCHAR(50))  BEGIN
DELETE FROM detalle_temp WHERE correlativo = id_detalle;
SELECT tmp.correlativo,tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp tmp INNER JOIN producto p ON tmp.codproducto= p.codproducto WHERE tmp.token_user= token;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procesar_venta` (IN `cod_usuario` INT, IN `cod_cliente` INT, IN `token` VARCHAR(50))  BEGIN
DECLARE factura INT;

DECLARE registros int;
DECLARE total DECIMAL(10,2);

DECLARE nueva_existencia int;
DECLARE existencia_actual int;

DECLARE tmp_cod_producto int;
DECLARE tmp_cant_producto int;
DECLARE a INT;
SET a = 1;

CREATE TEMPORARY TABLE tbl_tmp_tokenuser (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cod_prod BIGINT,
    cant_prod int);
    
    SET registros = (SELECT COUNT(*) FROM detalle_temp WHERE token_user = token);
    IF registros > 0 THEN
    INSERT INTO tbl_tmp_tokenuser(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp WHERE token_user = token;
    INSERT INTO factura(usuario,codcliente) VALUES (cod_usuario,cod_cliente);
    SET factura = LAST_INSERT_ID();
    INSERT INTO detallefactura(nofactura,codproducto,cantidad,precio_venta) SELECT (factura) as nofactura, codproducto,cantidad, precio_venta FROM detalle_temp WHERE token_user = token;
    
    WHILE a<= registros DO
    SELECT cod_prod,cant_prod INTO tmp_cod_producto,tmp_cant_producto FROM tbl_tmp_tokenuser WHERE id= a;
    SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = tmp_cod_producto;
    
    SET nueva_existencia = existencia_actual - tmp_cant_producto;
    UPDATE producto SET existencia = nueva_existencia WHERE codproducto = tmp_cod_producto;
    
    SET a=a+1;
    
    
    END WHILE;
    SET total = (SELECT SUM(cantidad * precio_venta) FROM detalle_temp WHERE token_user = token);
                 UPDATE factura SET totalfactura = total WHERE nofactura = factura;
                 
                 DELETE FROM detalle_temp WHERE token_user = token;
                 TRUNCATE TABLE tbl_tmp_tokenuser;
                 SELECT * FROM factura WHERE nofactura = factura;
    ELSE
                 SELECT 0;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

CREATE TABLE `categoria` (
  `cod_categoria` int(11) NOT NULL,
  `nombre` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`cod_categoria`, `nombre`) VALUES
(1, 'Sofas'),
(11, 'Comedores'),
(12, 'Libreros'),
(13, 'Categoría Prueba'),
(14, 'Sillas'),
(16, 'Juegos de Sala');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `idcliente` int(11) NOT NULL,
  `nit` varchar(16) NOT NULL,
  `nombre` varchar(80) DEFAULT NULL,
  `telefono` int(11) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `dateadd` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`idcliente`, `nit`, `nombre`, `telefono`, `direccion`, `dateadd`, `usuario_id`, `estatus`) VALUES
(1, '1', 'Consumidor Final', 87992532, '', '2021-06-07 20:38:43', 24, 0),
(49, '203-031191-1000T', 'Mario Alberto Arias Anton', 87992532, 'Granada,Gomper 1/2 C al oeste', '2021-06-07 20:38:43', 24, 0),
(50, '203-031197-100T', '', 0, '', '2021-06-08 18:14:15', 24, 0),
(51, '203-031197-100T', '', 0, '', '2021-06-08 18:14:16', 24, 0),
(52, '204-031120-2000N', 'Amparo López Ruiz', 2147483647, 'Managua, Mercado Oriental tres esquinas 10 vrs', '2021-06-10 00:46:05', 24, 1),
(53, '203-091599-1000G', 'Marta Elena Franco', 2147483647, 'Hotel cordoba. 2 C abajo', '2021-06-10 16:48:55', 24, 1),
(54, '203-031191-1000p', 'test01', 1545454, 'Grandad,Gomper 1/2 C al oeste', '2021-06-24 14:40:34', 24, 0),
(55, '203-031191-1000B', 'Maria Josefa Duarte', 2147483647, 'Granada, Nicaragua', '2021-06-24 23:27:54', 24, 1),
(56, '203-031191-1000B', 'Maria Josefa Duarte', 123456789, 'Granada, Nicaragua', '2021-06-24 23:28:13', 24, 0),
(57, '203-119875-1000N', 'Juegos de Sala', 2147483647, 'dsds', '2021-06-24 23:43:47', 24, 0),
(58, '203-031191-1000', 'asa', 87952, 'assa', '2021-07-01 22:54:04', 24, 0),
(59, '203-031-1000T', 'cd', 78852, 'Grandad,Gomper 1/2 C al oeste', '2021-07-16 00:35:10', 25, 0),
(60, '203-031192-1000T', 'Marcos José López López', 5495955, 'Granada,Gomper 1/2 C al oeste', '2021-07-16 00:36:24', 25, 1),
(61, '203-031191-1000', 'Juegos de Sala', 265262, 'ssa', '2021-07-16 00:39:07', 25, 0),
(62, '203-031191', 'gd', 456654545, 'dasa', '2021-07-16 00:44:48', 25, 0),
(63, 'eeeeded', '5555', 1111111, 'e', '2021-07-16 00:53:34', 25, 0),
(64, '203-031191-1000T', 'Jose Adan Lopéz Rivas', 87992532, 'Managua, Mercado Oriental', '2021-07-22 11:13:04', 24, 1),
(65, '203-031191-1000T', 's', 2147483647, 'Plaza Sésamo', '2021-07-22 11:13:29', 24, 0),
(66, '203-031191-1000T', 'e', 2147483647, 'ew', '2021-07-22 11:21:56', 24, 0),
(67, '203-110497-1000N', 'Pedro José Aguirre ', 123456789, 'Calzada ', '2021-07-22 11:28:13', 24, 1),
(68, '203-031191-1000Ñ', 'FACINV', 25524838, 'Granada, Nicaragua', '2021-09-17 23:31:32', 24, 1),
(69, '203-031191-1000F', 'TestMaria', 87992532, 'Granada, Nicaragua', '2021-09-21 14:11:22', 26, 1),
(70, '203-031191-1000G', 'Junito', 87992535, 'Granada, Nicaragua', '2021-09-21 14:20:05', 26, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detallefactura`
--

CREATE TABLE `detallefactura` (
  `correlativo` bigint(11) NOT NULL,
  `nofactura` bigint(11) DEFAULT NULL,
  `codproducto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_venta` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `detallefactura`
--

INSERT INTO `detallefactura` (`correlativo`, `nofactura`, `codproducto`, `cantidad`, `precio_venta`) VALUES
(39, 48, 18, 1, '8500.00'),
(40, 49, 19, 2, '45.00'),
(41, 50, 19, 2, '45.00'),
(42, 51, 19, 1, '45.00'),
(43, 52, 19, 2, '45.00'),
(44, 56, 19, 1, '45.00'),
(45, 58, 19, 1, '55.00'),
(46, 58, 19, 1, '55.00'),
(48, 59, 19, 1, '55.00'),
(49, 60, 19, 1, '55.00'),
(50, 61, 19, 3, '55.00'),
(51, 62, 18, 1, '8500.00'),
(52, 62, 18, 1, '8500.00'),
(53, 63, 23, 4, '22.00'),
(54, 64, 19, 1, '55.00'),
(55, 64, 18, 1, '8500.00'),
(57, 65, 18, 1, '8512.50'),
(58, 66, 20, 1, '173.53'),
(59, 67, 18, 1, '8512.50'),
(60, 68, 28, 6, '150.00'),
(61, 70, 18, 2, '8512.50'),
(62, 71, 18, 1, '8512.50'),
(63, 72, 18, 1, '8112.19'),
(64, 73, 30, 1, '7500.00'),
(65, 74, 30, 1, '7500.00'),
(66, 75, 27, 1, '17.39'),
(67, 76, 19, 1, '55.04'),
(68, 77, 19, 1, '55.04'),
(69, 78, 19, 1, '55.04'),
(70, 79, 19, 1, '55.04'),
(71, 80, 19, 1, '55.04'),
(72, 81, 19, 1, '55.04'),
(73, 82, 19, 1, '55.04'),
(74, 83, 19, 1, '55.04'),
(75, 84, 19, 1, '55.04'),
(76, 85, 19, 1, '55.04'),
(77, 86, 19, 1, '55.04'),
(78, 87, 19, 1, '55.04'),
(79, 88, 19, 1, '55.04'),
(80, 89, 19, 1, '55.04'),
(81, 90, 29, 3, '55.00'),
(82, 91, 29, 1, '55.00'),
(83, 92, 29, 1, '55.00'),
(84, 93, 29, 1, '55.00'),
(85, 93, 19, 1, '55.04'),
(86, 93, 25, 4, '9.13'),
(87, 94, 25, 1, '9.13'),
(88, 95, 25, 1, '9.13'),
(89, 96, 19, 1, '55.04');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_temp`
--

CREATE TABLE `detalle_temp` (
  `correlativo` int(11) NOT NULL,
  `token_user` varchar(50) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `detalle_temp`
--

INSERT INTO `detalle_temp` (`correlativo`, `token_user`, `codproducto`, `cantidad`, `precio_venta`) VALUES
(322, '8e296a067a37563370ded05f5a3bf3ec', 20, 1, '173.53'),
(323, '8e296a067a37563370ded05f5a3bf3ec', 25, 1, '9.13');

--
-- Disparadores `detalle_temp`
--
DELIMITER $$
CREATE TRIGGER `before_ventas_delete` BEFORE DELETE ON `detalle_temp` FOR EACH ROW begin
  update producto set existencia=producto.existencia+old.cantidad
     where old.codproducto=producto.codproducto;   
 end
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_ventas_insert` BEFORE INSERT ON `detalle_temp` FOR EACH ROW begin
   update producto set existencia=producto.existencia-new.cantidad
     where new.codproducto=producto.codproducto; 
 END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entradas`
--

CREATE TABLE `entradas` (
  `identrada` int(11) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `cantidad` int(11) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `usuario_id` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `entradas`
--

INSERT INTO `entradas` (`identrada`, `codproducto`, `fecha`, `cantidad`, `precio`, `usuario_id`) VALUES
(46, 18, '2021-06-07 20:56:30', 1, '8500.00', 25),
(47, 18, '2021-06-08 18:06:49', 2, '8500.00', 24),
(48, 19, '2021-06-09 01:07:20', 50, '45.00', 24),
(49, 19, '2021-06-10 12:20:37', 10, '55.00', 24),
(50, 20, '2021-06-15 16:32:36', 3, '22.00', 24),
(51, 20, '2021-06-15 16:33:58', 13, '22.00', 24),
(52, 20, '2021-06-15 16:36:31', 1, '22.00', 24),
(53, 20, '2021-06-15 16:37:15', 1, '23.00', 24),
(56, 23, '2021-06-17 00:24:00', 5, '22.00', 24),
(57, 24, '2021-06-17 00:58:51', 2, '555.00', 24),
(58, 25, '2021-06-24 15:03:31', 9, '15.00', 24),
(59, 25, '2021-06-24 15:06:08', 400, '9.00', 24),
(60, 18, '2021-06-24 15:14:42', 1, '8600.00', 24),
(61, 20, '2021-06-24 15:47:26', 18, '325.00', 24),
(62, 26, '2021-07-01 13:21:04', 10, '35.00', 24),
(63, 26, '2021-07-01 13:24:33', 5, '35.00', 24),
(64, 26, '2021-07-01 13:24:34', 5, '35.00', 24),
(65, 26, '2021-07-01 13:24:51', 5, '35.00', 24),
(66, 27, '2021-07-01 13:50:54', 50, '22.00', 24),
(67, 27, '2021-07-01 13:55:45', 100, '15.00', 24),
(68, 27, '2021-07-01 14:00:46', 15, '18.00', 24),
(69, 28, '2021-07-09 13:05:30', 5, '150.00', 24),
(70, 28, '2021-07-09 13:06:15', 4, '150.00', 24),
(71, 28, '2021-07-09 13:14:06', 10, '155.00', 24),
(72, 18, '2021-07-23 10:14:08', 2, '8512.12', 24),
(73, 18, '2021-07-23 10:15:16', 2, '8512.12', 24),
(74, 18, '2021-07-23 10:15:59', 1, '8512.12', 24),
(75, 18, '2021-07-23 10:16:47', 1, '8512.12', 24),
(76, 18, '2021-07-23 10:19:43', 1, '8512.12', 24),
(77, 18, '2021-07-23 10:29:36', 2, '8512.00', 24),
(78, 18, '2021-07-23 14:14:32', 2, '5512.00', 24),
(79, 18, '2021-07-24 23:32:38', 1, '8112.19', 24),
(80, 19, '2021-07-24 23:39:16', 5, '55.13', 24),
(81, 19, '2021-07-24 23:39:50', 1, '55.00', 24),
(82, 29, '2021-08-30 20:31:55', 9, '55.00', 24),
(83, 30, '2021-08-31 22:18:54', 3, '7500.00', 24),
(84, 31, '2021-09-16 23:09:28', 3, '7000.00', 24),
(85, 32, '2021-09-20 23:11:59', 3, '10500.00', 24),
(86, 32, '2021-09-20 23:12:57', 4, '10500.00', 24),
(87, 18, '2021-09-21 15:17:09', 5, '6000.00', 25),
(88, 18, '2021-09-21 16:34:25', 3, '7609.29', 24),
(89, 33, '2021-09-21 16:35:06', 8, '8112.19', 24);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estado`
--

CREATE TABLE `estado` (
  `codestado` int(11) NOT NULL,
  `Descripcion` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `estado`
--

INSERT INTO `estado` (`codestado`, `Descripcion`) VALUES
(1, 'Activo'),
(2, 'Inactivo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura`
--

CREATE TABLE `factura` (
  `nofactura` bigint(11) NOT NULL,
  `metodopago` int(11) NOT NULL DEFAULT 1,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario` int(11) DEFAULT NULL,
  `codcliente` int(11) DEFAULT NULL,
  `totalfactura` decimal(10,2) DEFAULT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `factura`
--

INSERT INTO `factura` (`nofactura`, `metodopago`, `fecha`, `usuario`, `codcliente`, `totalfactura`, `estatus`) VALUES
(48, 1, '2021-06-08 18:15:34', 24, 49, '8500.00', 1),
(49, 1, '2021-06-09 01:10:39', 26, 49, '90.00', 2),
(50, 1, '2021-06-10 00:43:19', 24, 49, '90.00', 2),
(51, 1, '2021-06-10 00:44:54', 24, 49, '45.00', 2),
(52, 1, '2021-06-10 00:46:50', 24, 52, '90.00', 2),
(56, 1, '2021-06-10 12:17:26', 24, 49, '45.00', 2),
(58, 1, '2021-06-10 12:29:28', 24, 49, '110.00', 2),
(59, 1, '2021-06-10 16:44:21', 26, 49, '55.00', 2),
(60, 1, '2021-06-10 20:08:32', 24, 49, '55.00', 2),
(61, 1, '2021-06-10 20:15:37', 24, 49, '165.00', 2),
(62, 1, '2021-06-17 12:09:28', 24, 49, '17000.00', 1),
(63, 1, '2021-06-19 00:35:45', 24, 49, '88.00', 1),
(64, 1, '2021-06-24 11:10:19', 24, 49, '8555.00', 1),
(65, 1, '2021-06-24 15:15:18', 24, 49, '8512.50', 1),
(66, 1, '2021-06-24 15:51:34', 26, 49, '173.53', 2),
(67, 1, '2021-07-01 15:38:06', 26, 49, '8512.50', 2),
(68, 1, '2021-07-09 13:13:02', 24, 55, '900.00', 1),
(70, 1, '2021-07-22 23:58:17', 24, 64, '17025.00', 1),
(71, 1, '2021-07-22 23:59:35', 24, 64, '8512.50', 2),
(72, 1, '2021-07-23 14:20:47', 24, 52, '8112.19', 1),
(73, 1, '2021-08-31 22:19:47', 24, 60, '7500.00', 2),
(74, 1, '2021-08-31 23:08:40', 26, 52, '7500.00', 2),
(75, 1, '2021-09-15 21:46:04', 24, 53, '17.39', 1),
(76, 1, '2021-09-15 22:15:08', 24, 64, '55.04', 2),
(77, 1, '2021-09-15 22:18:05', 24, 64, '55.04', 2),
(78, 1, '2021-09-15 23:11:20', 24, 64, '55.04', 1),
(79, 1, '2021-09-15 23:26:01', 24, 1, '55.04', 1),
(80, 1, '2021-09-15 23:30:38', 24, 1, '55.04', 1),
(81, 1, '2021-09-15 23:31:10', 24, 1, '55.04', 1),
(82, 1, '2021-09-15 23:33:04', 24, 1, '55.04', 1),
(83, 1, '2021-09-16 00:17:52', 24, 1, '55.04', 1),
(84, 1, '2021-09-16 23:18:08', 26, 64, '55.04', 2),
(85, 1, '2021-09-16 23:21:26', 24, 1, '55.04', 1),
(86, 1, '2021-09-16 23:21:43', 24, 64, '55.04', 1),
(87, 1, '2021-09-18 00:04:58', 24, 68, '55.04', 2),
(88, 1, '2021-09-18 01:22:29', 28, 68, '55.04', 2),
(89, 1, '2021-09-20 23:17:25', 30, 52, '55.04', 2),
(90, 1, '2021-09-21 14:13:15', 26, 52, '165.00', 1),
(91, 1, '2021-09-21 14:35:53', 26, 1, '55.00', 1),
(92, 1, '2021-09-21 14:38:10', 26, 70, '55.00', 1),
(93, 1, '2021-09-21 14:40:46', 26, 1, '146.56', 1),
(94, 1, '2021-09-21 14:46:29', 26, 1, '9.13', 1),
(95, 1, '2021-09-21 14:47:23', 26, 70, '9.13', 2),
(96, 1, '2021-09-21 15:20:23', 25, 1, '55.04', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `codproducto` int(11) NOT NULL,
  `descripcion` varchar(100) DEFAULT NULL,
  `detalle` varchar(100) DEFAULT NULL,
  `proveedor` int(11) DEFAULT NULL,
  `categoria` int(11) NOT NULL,
  `precio` decimal(10,2) DEFAULT NULL,
  `existencia` int(11) DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`codproducto`, `descripcion`, `detalle`, `proveedor`, `categoria`, `precio`, `existencia`, `date_add`, `usuario_id`, `estatus`) VALUES
(18, 'Pieza Trenza Acustico 2 sillones', 'Verificacion', 15, 1, '7609.29', 24, '2021-06-07 20:56:30', 25, 1),
(19, 'Pieza Sevilla', 'color blanco', 15, 1, '55.04', 8, '2021-06-09 01:07:20', 25, 1),
(20, 'Pieza Porta Vaso', 'Madera de cedro', 15, 1, '173.53', 35, '2021-06-15 16:32:36', 24, 1),
(23, 'lite0255', NULL, 15, 11, '22.00', 1, '2021-06-17 00:24:00', 24, 0),
(24, 'maria 12', NULL, 15, 1, '555.00', 2, '2021-06-17 00:58:51', 24, 0),
(25, 'Pieza Esquinero Americano', 'Madera de abedul', 15, 14, '9.13', 403, '2021-06-24 15:03:31', 24, 1),
(26, 'Comedor tres pieza\r\n', NULL, 15, 11, '35.00', 25, '2021-07-01 13:21:04', 24, 0),
(27, 'Comedor Premium', 'color marrón', 15, 1, '17.39', 164, '2021-07-01 13:50:54', 24, 1),
(28, 'sofa cama', NULL, 15, 1, '153.85', 13, '2021-07-09 13:05:30', 24, 0),
(29, 'Test Prueba', 'color wengué', 15, 1, '55.00', 3, '2021-08-30 20:31:55', 24, 1),
(30, 'Pieza Clon Jalado', 'color café', 15, 1, '7500.00', 3, '2021-08-31 22:18:54', 24, 1),
(31, 'Test12', 'Prueba', 15, 1, '7000.00', 3, '2021-09-16 23:09:28', 24, 1),
(32, 'Comedor estandar', 'Madera acabado fino real', 15, 11, '10500.00', 7, '2021-09-20 23:11:59', 24, 1),
(33, 'Pieza Trenza Acustico 2 Mesedoras', 'Color madera', 20, 1, '8112.19', 8, '2021-09-21 16:35:06', 24, 1);

--
-- Disparadores `producto`
--
DELIMITER $$
CREATE TRIGGER `entrada_producto` AFTER INSERT ON `producto` FOR EACH ROW BEGIN 
INSERT INTO entradas(codproducto,cantidad,precio,usuario_id)
VALUES(new.codproducto,new.existencia,new.precio,new.usuario_id);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `codproveedor` int(11) NOT NULL,
  `ruc` varchar(100) DEFAULT NULL,
  `proveedor` varchar(100) DEFAULT NULL,
  `contacto` varchar(100) DEFAULT NULL,
  `telefono` bigint(11) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `proveedor`
--

INSERT INTO `proveedor` (`codproveedor`, `ruc`, `proveedor`, `contacto`, `telefono`, `direccion`, `date_add`, `usuario_id`, `estatus`) VALUES
(15, '304952BM', 'Mubleria Conny', 'Benlly Vilchez', 86577267, 'Managua, Mercado Oriental', '2021-06-07 20:40:50', 24, 1),
(16, '729992F', 'Test024', 'FACINV', 555959595, 'Granada, Nicaragua', '2021-06-16 22:49:57', 24, 0),
(17, '380264T', 'Taller 2', 'Franchezco Vilches', 56546565, 'Managua', '2021-06-24 14:45:01', 24, 1),
(18, '529483P', 'Prueba de proveedor', 'Benlly Vilchez02', 12345677, 'Granada, Nicaragua', '2021-07-25 00:51:00', 24, 1),
(19, '29399248N', 'Taller1', 'Bernardo', 71525139, 'Managua', '2021-09-12 12:01:00', 24, 1),
(20, '304952BM', 'FACINV', 'FACINV', 87992532, 'Granada, Nicaragua', '2021-09-17 23:51:35', 24, 1),
(21, '304923FAC', 'FACINV1', 'FACINV1', 87992532, 'Granada, Nicaragua', '2021-09-18 01:18:13', 24, 0),
(22, '11212232G', 'Mubleria Conny', 'Benlly Vilchez1', 87992532, 'Managua, Mercado Oriental ', '2021-09-21 15:05:32', 25, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `idrol` int(11) NOT NULL,
  `rol` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`idrol`, `rol`) VALUES
(1, 'Administrador'),
(2, 'Supervisor'),
(3, 'Vendedor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `salida_producto`
--

CREATE TABLE `salida_producto` (
  `Cod_salida` int(11) NOT NULL,
  `Id_usuario` int(11) NOT NULL,
  `producto` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `Decripcion` varchar(300) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipopago`
--

CREATE TABLE `tipopago` (
  `Cod_Tipo_pago` int(11) NOT NULL,
  `Nombre` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `tipopago`
--

INSERT INTO `tipopago` (`Cod_Tipo_pago`, `Nombre`) VALUES
(1, 'Efectivo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `idusuario` int(11) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `usuario` varchar(15) DEFAULT NULL,
  `clave` varchar(100) DEFAULT NULL,
  `rol` int(11) DEFAULT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`idusuario`, `nombre`, `correo`, `usuario`, `clave`, `rol`, `estatus`) VALUES
(24, 'Conny Robleto', 'Conny@gmail.com', 'Admin', 'e10adc3949ba59abbe56e057f20f883e', 1, 1),
(25, 'María López Leyton', 'antonwalter@gmail.con', 'Supervisor1', 'e10adc3949ba59abbe56e057f20f883e', 2, 1),
(26, 'José Pavón', 'pavon@gmail.com', 'pavon2', 'e10adc3949ba59abbe56e057f20f883e', 3, 1),
(27, 'Fabio Jose Maltez Flores', 'malezflores@gmail.com', 'Fabio15', '202cb962ac59075b964b07152d234b70', 2, 1),
(28, 'FACINV', 'DEV@FACINV.COM.NI', 'TestUSer', 'e10adc3949ba59abbe56e057f20f883e', 3, 1),
(29, 'Mario José Aguilar', 'jose@gmail.com', 'AguilarMario', 'e10adc3949ba59abbe56e057f20f883e', 3, 1),
(30, 'Jose Walter ', 'jose001@gmail.com', 'Vendedor02', 'e10adc3949ba59abbe56e057f20f883e', 3, 1),
(31, 'Walter José02', 'Supervisor21@conny.com', 'Admin06', '827ccb0eea8a706c4c34a16891f84e7b', 1, 1);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`cod_categoria`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`idcliente`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `nofactura` (`nofactura`);

--
-- Indices de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`);

--
-- Indices de la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD PRIMARY KEY (`identrada`),
  ADD KEY `codproducto` (`codproducto`);

--
-- Indices de la tabla `estado`
--
ALTER TABLE `estado`
  ADD PRIMARY KEY (`codestado`);

--
-- Indices de la tabla `factura`
--
ALTER TABLE `factura`
  ADD PRIMARY KEY (`nofactura`),
  ADD KEY `usuario` (`usuario`),
  ADD KEY `codcliente` (`codcliente`),
  ADD KEY `metodopago` (`metodopago`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`codproducto`),
  ADD KEY `proveedor` (`proveedor`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `categoria` (`categoria`);

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`codproveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `rol`
--
ALTER TABLE `rol`
  ADD PRIMARY KEY (`idrol`);

--
-- Indices de la tabla `salida_producto`
--
ALTER TABLE `salida_producto`
  ADD PRIMARY KEY (`Cod_salida`),
  ADD KEY `Id_usuario` (`Id_usuario`,`producto`),
  ADD KEY `producto` (`producto`);

--
-- Indices de la tabla `tipopago`
--
ALTER TABLE `tipopago`
  ADD PRIMARY KEY (`Cod_Tipo_pago`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`idusuario`),
  ADD KEY `rol` (`rol`),
  ADD KEY `estatus` (`estatus`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categoria`
--
ALTER TABLE `categoria`
  MODIFY `cod_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `idcliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT de la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  MODIFY `correlativo` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=90;

--
-- AUTO_INCREMENT de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=324;

--
-- AUTO_INCREMENT de la tabla `entradas`
--
ALTER TABLE `entradas`
  MODIFY `identrada` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=90;

--
-- AUTO_INCREMENT de la tabla `estado`
--
ALTER TABLE `estado`
  MODIFY `codestado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `factura`
--
ALTER TABLE `factura`
  MODIFY `nofactura` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=97;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `codproducto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `codproveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `idrol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `salida_producto`
--
ALTER TABLE `salida_producto`
  MODIFY `Cod_salida` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `tipopago`
--
ALTER TABLE `tipopago`
  MODIFY `Cod_Tipo_pago` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `idusuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `cliente_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
