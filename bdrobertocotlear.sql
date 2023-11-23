-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 23-11-2023 a las 01:51:56
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bdrobertocotlear`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateProductInventory` (IN `idProduct` VARCHAR(8), IN `idInventory` INT, IN `priceInit` FLOAT, IN `amountInit` INT)   BEGIN
    DECLARE subtotal FLOAT;
    
    -- Calcular el subtotal
    SET subtotal = priceInit * amountInit;
    
    -- Insertar el producto en la tabla productinventory
    INSERT INTO productinventory (idProduct, idInventory, amountInit, priceInit, subtotal)
    VALUES (idProduct, idInventory, amountInit, priceInit, subtotal);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteInventoryChecking` (IN `idInventoryParam` INT)   BEGIN
	DELETE FROM inventory
    WHERE idInventory = idInventoryParam
    AND NOT EXISTS (SELECT 1 FROM productinventory WHERE idInventory = inventory.idInventory);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteProduct` (IN `idProduct` VARCHAR(8))   BEGIN
	DELETE p FROM product p
    INNER JOIN productinventory pi ON pi.idProduct=p.idProduct
    WHERE pi.amountInit=0 AND p.idProduct = idProduct;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetBuyDetails` (IN `userId` VARCHAR(50))   BEGIN
    SELECT 
      bu.idBuyUser,
      bu.stateBuy,
      bu.dateBuy,
     orb.dateOrder,
     ord.idProduct,
     p.nameProduct,
     p.description,
     p.imgProduct,
    ord.priceProduct,
    ord.amountProduct,
    orb.total 
   FROM orderdetail ord 
  INNER JOIN orderbuy orb
  ON ord.idOrderBuy = orb.idOrderBuy 
  INNER JOIN product p
  ON ord.idProduct = p.idProduct
  INNER JOIN buyuser bu
  ON bu.idOrder = orb.idOrderBuy 
  WHERE bu.idBuyUser = userId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetProductByIdProduct` (IN `idProduct` VARCHAR(8))   BEGIN
	SELECT 
    	p.idProduct,
        p.nameProduct,
        p.brand,
        p.description,
        p.statusProduct,
        p.imgProduct,
        p.price,
        p.unit,
        p.create_at,
        p.update_at,
        pi.amountInit,
        p.idCategory,
        c.nameCategory,
	i.idInventory
    FROM product p
    INNER JOIN category c ON p.idCategory = c.idCategory
    INNER JOIN productinventory pi ON pi.idProduct = p.idProduct
    INNER JOIN inventory i ON i.idInventory = pi.idInventory
    WHERE p.idProduct = idProduct;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetProductsByInventory` (IN `InventoryId` INT)   BEGIN
  SELECT 
        p.idProduct,
        p.nameProduct,
        p.brand,
        p.description,
        p.statusProduct,
        p.imgProduct,
        p.price,
        p.unit,
        p.create_at,
        p.update_at,
        c.nameCategory,
        pi.amountInit
    FROM product p
    INNER JOIN category c ON p.idCategory = c.idCategory
    INNER JOIN productinventory pi ON pi.idProduct = p.idProduct
    INNER JOIN inventory ip ON ip.idInventory = pi.idInventory
    WHERE ip.idInventory =  InventoryId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetProductsByInventoryAndCategory` (IN `idInventory` INT, IN `idCategory` INT)   BEGIN
	SELECT 
        p.idProduct,
        p.nameProduct,
        p.brand,
        p.description,
        p.statusProduct,
        p.imgProduct,
        p.price,
        p.unit,
        p.create_at,
        p.update_at,
        c.nameCategory,
        pi.amountInit
    FROM product p
    INNER JOIN category c ON p.idCategory = c.idCategory
    INNER JOIN productinventory pi ON pi.idProduct = p.idProduct
    INNER JOIN inventory ip ON ip.idInventory = pi.idInventory
    WHERE ip.idInventory =  idInventory AND p.idCategory = idCategory;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetProductsByInventoryPagination` (IN `idInventory` INT, IN `pageInit` INT, IN `pageEnd` INT)   BEGIN
	SELECT 
        p.idProduct,
        p.nameProduct,
        p.brand,
        p.description,
        p.statusProduct,
        p.imgProduct,
        p.price,
        p.unit,
        p.create_at,
        p.update_at,
        c.nameCategory,
        pi.amountInit
    FROM product p
    INNER JOIN category c ON p.idCategory = c.idCategory
    INNER JOIN productinventory pi ON pi.idProduct = p.idProduct
    INNER JOIN inventory ip ON ip.idInventory = pi.idInventory
    WHERE ip.idInventory =  idInventory ORDER BY p.idProduct ASC LIMIT pageInit, pageEnd;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertOrderProducts` (IN `id_user` INT, IN `p_monto_total` FLOAT, IN `p_productos` JSON)   BEGIN
    -- TODO:Los campos que seran nulos se insertan con el valor por defecto
    DECLARE v_id_orderproducts VARCHAR(10);

    -- Insertar en la tabla orderproducts
    INSERT INTO orderbuy (idOrderBuy, dateOrder, stateOrder, total)
    VALUES ( UUID() , NOW(), "Pendiente", p_monto_total);
    -- Obtener el ID del pedido recién insertado de la tabla orderproducts
    
   SET @v_idOrderBuy = (SELECT idOrderBuy FROM orderbuy WHERE idLastOrderBuy = (SELECT o.idLastOrderBuy FROM orderbuy o ORDER BY o.idLastOrderBuy DESC LIMIT 1));
    
    FOR i IN 0..JSON_LENGTH(p_productos) - 1 DO
        SET @idProduct = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', i, '].idProduct')));
        SET @amountProduct = JSON_EXTRACT(p_productos, CONCAT('$[', i, '].amount'));
        SET @priceProduct = JSON_EXTRACT(p_productos, CONCAT('$[', i, '].price'));
        --  Insertar en la tabla orderdetail donde se almacenan los productos del pedido
-- Actualizar la forma de agregar productos
        INSERT INTO orderdetail (idOrderBuy,idProduct,priceProduct,amountProduct)
        VALUES (@v_idOrderBuy, @idProduct,@priceProduct, @amountProduct);
    END FOR;

    -- Insertar en la tabla userbuys
    INSERT INTO buyuser (idBuyUser, idOrder,idUser, stateBuy)
    VALUES (UUID(), @v_idOrderBuy, id_user, 'No Pagado');

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SearchProduct` (IN `idInventory` INT, IN `search` TEXT)   BEGIN
	SELECT 
        p.idProduct,
        p.nameProduct,
        p.brand,
        p.description,
        p.statusProduct,
        p.imgProduct,
        p.price,
        p.unit,
        p.create_at,
        p.update_at,
        c.nameCategory,
        pi.amountInit
    FROM product p
    INNER JOIN category c ON p.idCategory = c.idCategory
    INNER JOIN productinventory pi ON pi.idProduct = p.idProduct
    INNER JOIN inventory ip ON ip.idInventory = pi.idInventory
    WHERE ip.idInventory =  idInventory AND p.nameProduct LIKE CONCAT('%', search, '%');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateProductInventory` (IN `idProduct` VARCHAR(8), IN `priceInit` FLOAT, IN `amountInit` INT)   BEGIN
	UPDATE productinventory p SET 
    p.priceInit = priceInit, p.amountInit = amountInit WHERE p.idProduct = idProduct;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `buyuser`
--

CREATE TABLE `buyuser` (
  `lastId` int(11) NOT NULL,
  `idBuyUser` varchar(10) NOT NULL,
  `idOrder` varchar(10) NOT NULL,
  `idUser` int(11) NOT NULL,
  `stateBuy` varchar(20) NOT NULL,
  `dateBuy` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `buyuser`
--

INSERT INTO `buyuser` (`lastId`, `idBuyUser`, `idOrder`, `idUser`, `stateBuy`, `dateBuy`) VALUES
(1, '643b8593-8', 'f6391150-8', 2, 'Pagado', '2023-11-18 22:58:31'),
(2, '9d7f4254-8', 'f6391150-8', 2, 'Pagado', '2023-11-20 08:39:39'),
(6, 'd04d3fcf-8', 'd04cc1e2-8', 2, 'Pagado', '2023-11-20 08:53:12'),
(7, '1956b04f-8', '195474a4-8', 2, 'Pagado', '2023-11-20 22:27:30'),
(9, 'd3668bed-8', 'd36635a3-8', 2, 'Pagado', '2023-11-20 08:57:03'),
(11, 'aee5ef45-8', 'aee5ac55-8', 2, 'Pagado', '2023-11-20 22:26:22'),
(12, '07c04141-8', '07bfd0d2-8', 2, 'Pagado', '2023-11-20 22:25:08'),
(13, '8f4be7ad-8', '8f4bb061-8', 2, 'Pagado', '2023-11-20 08:40:54'),
(14, 'a59181ca-8', 'a590ea4f-8', 2, 'Pagado', '2023-11-20 22:23:20'),
(15, '7c17b92d-8', '7c176434-8', 2, 'Pagado', '2023-11-20 22:22:13'),
(16, 'b2c364d8-8', 'b2c3122e-8', 2, 'Pagado', '2023-11-20 22:20:03'),
(17, 'e2dbf2e2-8', 'e2db82f1-8', 2, 'Pagado', '2023-11-20 09:13:20'),
(18, 'e2b30962-8', 'e2b22c2f-8', 2, 'Pagado', '2023-11-20 22:18:15'),
(20, '21c11a52-8', '21c0c56d-8', 2, 'Pagado', '2023-11-20 22:39:24'),
(24, '579827b3-8', '57973aea-8', 2, 'Pagado', '2023-11-21 12:19:21'),
(25, '04a93688-8', '04a76aa1-8', 2, 'No Pagado', '0000-00-00 00:00:00'),
(26, 'e74dbb91-8', 'e746c85f-8', 5, 'Pagado', '2023-11-22 18:23:22'),
(27, '3cb1df53-8', '3cb0f041-8', 5, 'No Pagado', '0000-00-00 00:00:00');

--
-- Disparadores `buyuser`
--
DELIMITER $$
CREATE TRIGGER `after_update_CompraPedido` BEFORE UPDATE ON `buyuser` FOR EACH ROW BEGIN
    -- Verificar si el estado de la compra cambió a 'Pagado'
    IF NEW.stateBuy = 'Pagado' AND OLD.stateBuy != 'Pagado' THEN
        -- Actualizar la fecha_ejecucion con la fecha actual
        SET NEW.dateBuy = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `category`
--

CREATE TABLE `category` (
  `idCategory` int(11) NOT NULL,
  `nameCategory` varchar(255) NOT NULL,
  `statusCategory` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `category`
--

INSERT INTO `category` (`idCategory`, `nameCategory`, `statusCategory`) VALUES
(1, 'Herramientas manuales', 'activo'),
(2, 'Herramientas eléctricas', 'activo'),
(3, 'Suministros de construcción', 'activo'),
(4, 'Pintura y suministros relacionados', 'activo'),
(5, 'Ferretería para jardín', 'activo'),
(6, 'Fontanería y fontanería', 'activo'),
(7, 'Electricidad y sistemas de iluminación', 'activo'),
(8, 'Seguridad y protección', 'activo'),
(9, 'Herrajes y accesorios para muebles', 'activo'),
(10, 'Artículos de ferretería diversos', 'activo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventory`
--

CREATE TABLE `inventory` (
  `idInventory` int(11) NOT NULL,
  `note` text NOT NULL,
  `dateInventory` date NOT NULL,
  `idProvider` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `inventory`
--

INSERT INTO `inventory` (`idInventory`, `note`, `dateInventory`, `idProvider`) VALUES
(1, 'Nota 1', '2023-10-23', 45),
(8, 'Nota 2', '2023-10-30', 46),
(12, 'Nota 3', '2023-12-10', 48),
(13, 'Nota 4', '2023-12-10', 48),
(14, 'Nota 5', '2023-12-10', 48);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `orderbuy`
--

CREATE TABLE `orderbuy` (
  `idLastOrderBuy` int(11) NOT NULL,
  `idOrderBuy` varchar(10) NOT NULL,
  `dateOrder` datetime NOT NULL,
  `dateDelivery` datetime DEFAULT NULL,
  `stateOrder` varchar(20) NOT NULL,
  `total` float NOT NULL,
  `idPaymentMethod` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `orderbuy`
--

INSERT INTO `orderbuy` (`idLastOrderBuy`, `idOrderBuy`, `dateOrder`, `dateDelivery`, `stateOrder`, `total`, `idPaymentMethod`) VALUES
(1, '1ffb5349-8', '2023-11-18 22:45:47', NULL, 'Pendiente', 310, 3),
(2, '2fd0be27-8', '2023-11-18 22:39:04', NULL, 'Pendiente', 310, 3),
(3, '46078202-8', '2023-11-18 22:46:51', NULL, 'Pendiente', 310, 3),
(4, '643ad338-8', '2023-11-18 22:54:51', NULL, 'Pendiente', 310, 3),
(5, '6f63dc7c-8', '2023-11-18 22:12:13', NULL, 'Pendiente', 310, 3),
(6, '765b70cb-8', '2023-11-18 22:12:24', NULL, 'Pendiente', 310, 3),
(7, '7bc39042-8', '2023-11-18 22:34:02', NULL, 'Pendiente', 310, 3),
(8, '98866dfa-8', '2023-11-18 22:20:31', NULL, 'Pendiente', 310, 3),
(9, '9d7e9d66-8', '2023-11-18 22:56:27', NULL, 'Pendiente', 310, NULL),
(10, 'a0902545-8', '2023-11-18 22:13:35', NULL, 'Pendiente', 310, 3),
(11, 'da9b004f-8', '2023-11-18 22:36:41', NULL, 'Pendiente', 310, 3),
(12, 'de46a662-8', '2023-11-18 23:19:44', NULL, 'Pendiente', 100, 3),
(13, 'f6391150-8', '2023-11-18 22:37:27', '2023-11-21 11:25:40', 'Aceptado', 310.5, 3),
(14, '212c72f8-8', '2023-11-18 23:28:46', NULL, 'Pendiente', 100, 3),
(15, '35f776e5-8', '2023-11-18 23:29:21', NULL, 'Pendiente', 100, 3),
(16, '96ea8509-8', '2023-11-18 23:46:23', NULL, 'Pendiente', 100, 3),
(17, '9ba313d6-8', '2023-11-18 23:46:30', NULL, 'Pendiente', 100, 3),
(18, '05d91683-8', '2023-11-18 23:49:29', NULL, 'Pendiente', 310, NULL),
(19, '400cf9e3-8', '2023-11-18 23:51:06', NULL, 'Pendiente', 310, NULL),
(20, '1388eba0-8', '2023-11-19 00:04:11', NULL, 'Pendiente', 310, NULL),
(21, '526bb1e9-8', '2023-11-19 00:05:56', NULL, 'Pendiente', 310, NULL),
(22, 'a01607f8-8', '2023-11-19 00:08:06', NULL, 'Pendiente', 310, NULL),
(23, 'd04cc1e2-8', '2023-11-19 00:09:27', '2023-11-21 00:00:00', 'Aceptado', 300, NULL),
(24, '195474a4-8', '2023-11-19 22:58:44', NULL, 'Aceptado', 74, NULL),
(26, 'd36635a3-8', '2023-11-19 23:03:56', NULL, 'Aceptado', 148, NULL),
(28, 'aee5ac55-8', '2023-11-19 23:31:33', '2023-11-21 12:12:21', 'Aceptado', 46, NULL),
(29, '07bfd0d2-8', '2023-11-19 23:34:02', NULL, 'Aceptado', 310, NULL),
(30, '8f4bb061-8', '2023-11-19 23:37:49', '2023-11-21 12:17:55', 'Aceptado', 49.4, NULL),
(31, 'a590ea4f-8', '2023-11-20 08:56:47', '2023-11-21 12:13:23', 'Aceptado', 173, NULL),
(32, '7c176434-8', '2023-11-20 09:02:47', '2023-11-21 12:16:45', 'Aceptado', 88, NULL),
(33, 'b2c3122e-8', '2023-11-20 09:11:28', '2023-11-21 12:17:50', 'Aceptado', 44, NULL),
(34, 'e2db82f1-8', '2023-11-20 09:12:49', '2023-11-21 12:18:08', 'Aceptado', 67, NULL),
(35, 'e2b22c2f-8', '2023-11-20 21:44:26', NULL, 'Aceptado', 111, NULL),
(37, '21c0c56d-8', '2023-11-20 22:29:09', '2023-11-21 12:13:19', 'Aceptado', 44, NULL),
(41, '57973aea-8', '2023-11-21 10:47:57', NULL, 'Pendiente', 517, NULL),
(42, '04a76aa1-8', '2023-11-21 12:18:41', NULL, 'Pendiente', 233, NULL),
(43, 'e746c85f-8', '2023-11-22 18:21:45', NULL, 'Pendiente', 247.5, NULL),
(44, '3cb0f041-8', '2023-11-22 18:24:09', NULL, 'Pendiente', 170.5, NULL);

--
-- Disparadores `orderbuy`
--
DELIMITER $$
CREATE TRIGGER `update_dateDelivery` BEFORE UPDATE ON `orderbuy` FOR EACH ROW BEGIN
    IF NEW.stateOrder <> 'Pendiente' THEN
        SET NEW.dateDelivery = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `orderdetail`
--

CREATE TABLE `orderdetail` (
  `idOrderDetail` int(11) NOT NULL,
  `idOrderBuy` varchar(10) NOT NULL,
  `idProduct` varchar(8) NOT NULL,
  `priceProduct` float NOT NULL,
  `amountProduct` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `orderdetail`
--

INSERT INTO `orderdetail` (`idOrderDetail`, `idOrderBuy`, `idProduct`, `priceProduct`, `amountProduct`) VALUES
(9, 'f6391150-8', 'C605BB1F', 2, 80),
(11, 'f6391150-8', 'C605BB1F', 2, 80),
(15, '1388eba0-8', 'C605BB1F', 2, 80),
(17, '526bb1e9-8', 'C605BB1F', 2, 80),
(19, 'a01607f8-8', 'C605BB1F', 2, 80),
(21, 'd04cc1e2-8', 'C605BB1F', 2, 80),
(22, '195474a4-8', '52B6FD6A', 0, 44),
(23, '195474a4-8', '4938E7FB', 0, 30),
(26, 'd36635a3-8', '52B6FD6A', 0, 44),
(27, 'd36635a3-8', '4938E7FB', 0, 30),
(29, 'aee5ac55-8', 'C762B287', 23, 0),
(31, '07bfd0d2-8', 'C605BB1F', 80, 2),
(32, '8f4bb061-8', '9EDEF19E', 24.7, 2),
(34, 'a590ea4f-8', 'C762B287', 23, 1),
(35, '7c176434-8', '52B6FD6A', 44, 2),
(36, 'b2c3122e-8', '52B6FD6A', 44, 1),
(37, 'e2db82f1-8', '52B6FD6A', 44, 1),
(38, 'e2db82f1-8', 'C762B287', 23, 1),
(39, 'e2b22c2f-8', '4938E7FB', 30, 1),
(40, 'e2b22c2f-8', '017EDD5C', 27, 3),
(43, '21c0c56d-8', '52B6FD6A', 44, 1),
(50, '57973aea-8', 'E614F5A6', 60, 3),
(51, '57973aea-8', '52B6FD6A', 44, 3),
(52, '57973aea-8', '39153B41', 70, 2),
(53, '57973aea-8', 'AF470DA5', 32.5, 2),
(54, '04a76aa1-8', '05A0B0DC', 206, 1),
(55, '04a76aa1-8', '017EDD5C', 27, 1),
(56, 'e746c85f-8', '52B6FD6A', 44, 3),
(57, 'e746c85f-8', '80379AD0', 38.5, 3),
(58, '3cb0f041-8', '52B6FD6A', 44, 3),
(59, '3cb0f041-8', '80379AD0', 38.5, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `paymentmethod`
--

CREATE TABLE `paymentmethod` (
  `idPaymentMethod` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `state` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `paymentmethod`
--

INSERT INTO `paymentmethod` (`idPaymentMethod`, `name`, `description`, `state`) VALUES
(1, 'Paypal', 'Método de pago en línea', 'Activo'),
(2, 'Tarjeta', 'Pago con tarjeta de crédito o débito', 'Activo'),
(3, 'Nulo', 'Nulo', 'Inactivo');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `product`
--

CREATE TABLE `product` (
  `idProduct` varchar(8) NOT NULL,
  `nameProduct` text NOT NULL,
  `brand` text NOT NULL,
  `description` text NOT NULL,
  `statusProduct` varchar(50) NOT NULL,
  `imgProduct` text NOT NULL,
  `price` float NOT NULL,
  `unit` varchar(255) DEFAULT NULL,
  `create_at` datetime NOT NULL,
  `update_at` datetime NOT NULL,
  `idCategory` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `product`
--

INSERT INTO `product` (`idProduct`, `nameProduct`, `brand`, `description`, `statusProduct`, `imgProduct`, `price`, `unit`, `create_at`, `update_at`, `idCategory`) VALUES
('017EDD5C', 'Cinta metrica Global plus 5m / 16\'', 'STANLEY', 'La cinta métrica Global Plus de 5 metros (16 pies) es una herramienta esencial para cualquier proyecto de medición. Con una combinación perfecta de calidad y versatilidad, esta cinta te ayudará a tomar medidas precisas en una variedad de aplicaciones, desde proyectos de construcción hasta trabajos de bricolaje en el hogar.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699923177/products/r4prj6dsm0a0utxqkjq0.avif', 27, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 10),
('05A0B0DC', 'Esmeriladora Neumática Stanley Negra', 'STANLEY', 'La esmeriladora neumática Stanley en elegante color negro es una herramienta versátil y potente que te brindará un rendimiento excepcional en una amplia variedad de aplicaciones de lijado y pulido. Fabricada con la calidad y la durabilidad que caracterizan a la marca Stanley, esta esmeriladora es una elección confiable para profesionales y entusiastas del bricolaje por igual.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699923608/products/s4hdbeaiymld4qkszi3x.png', 206, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('0AA93A9E', 'Llave filtro lona Stanley', 'STANLEY', 'La llave filtro lona Stanley es una herramienta resistente y confiable diseñada para facilitar la extracción y el ajuste de filtros de aceite de automóviles y camiones. Su construcción de alta calidad y su diseño de lona proporcionan una excelente durabilidad y agarre, lo que la convierte en la elección perfecta para profesionales y entusiastas del mantenimiento de vehículos. Esta llave facilita el mantenimiento de los filtros de aceite de manera eficiente y segura.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699924067/products/oasldtdhwd5nbzu72ihk.png', 36.9, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('39153B41', 'Cepillo Global Corrugado Stanley Platiado', 'STANLEY', 'El cepillo Global Corrugado Stanley Platiado es una herramienta esencial para trabajos de carpintería y acabado. Su diseño de alta calidad y plateado proporciona durabilidad y resistencia, mientras que sus cerdas corrugadas permiten un lijado eficaz y uniforme en una variedad de superficies. Este cepillo es ideal para lograr acabados suaves y profesionales en proyectos de carpintería.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699923747/products/gzzfras7big5kxxpz209.png', 70, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 9),
('3DFAB170', 'Alicate de Corte de Precisión 6° Stanley', 'STANLEY', 'El alicate de corte Stanley de 6° es una herramienta versátil y resistente diseñada para cortar alambres, cables y otros materiales con precisión y facilidad. Su diseño de calidad y durabilidad lo convierte en una elección confiable para una amplia variedad de aplicaciones de corte. Este alicate de corte de 6° es esencial en cualquier caja de herramientas y te ayudará a abordar tareas de corte con eficacia.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699924630/products/hf8qwaz2qqy1mca4z9ok.png', 39, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 3),
('3FAB0141', 'Compresor de anillos Stanley', 'STANLEY', 'El compresor de anillos Stanley es la herramienta esencial para cualquier trabajo que involucre la instalación de anillos de pistón en motores y otras aplicaciones de compresión de anillos. Diseñado con la calidad y la durabilidad en mente, este compresor simplificará el proceso y garantizará un ajuste seguro y preciso de los anillos.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699923280/products/ifskonftxaxvqrni4hlc.png', 65, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('4938E7FB', 'Llave francesa 6° Stanley', 'STANLEY', 'La llave francesa Stanley de 6° es una herramienta versátil que permite ajustar y aflojar tuercas y pernos de diferentes tamaños con facilidad. Su diseño de calidad y durabilidad garantiza un rendimiento confiable en una variedad de aplicaciones. La llave ajustable de 6° de Stanley es una elección ideal para profesionales y aficionados que buscan una herramienta esencial para tareas de reparación y mantenimiento.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699924142/products/ozvuskq4umtne656lsr4.png', 30, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('52B6FD6A', 'Alicate articulado de extensión 12°', 'STANLEY', 'El alicate articulado de extensión 12° es una herramienta innovadora que te brinda la versatilidad que necesitas para abordar una amplia gama de tareas de agarre y sujeción. Su diseño único con articulación de 12 grados permite un acceso fácil a espacios estrechos y ángulos complicados.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699922943/products/rghdifzljv9mlmnrqrpz.jpg', 44, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('688A8FEE', 'Lapeadores x2 pz', 'STANLEY', 'Juego de Lapeadores de válvulas x 2 pz. Mangos torneados de madera dura para rotación suave y fácil de válvulas sin ranura de cabeza plana.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699907169/products/opurzf0aeqx6llsgoo24.jpg', 44, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('80379AD0', 'Dados C_ Ratche 1_2 El Roble', 'EL ROBLE', 'El juego de dados con trinquete de 1/2 pulgada de \"El Roble\" es una herramienta esencial para cualquier mecánico o entusiasta del bricolaje que busca calidad y versatilidad en su juego de herramientas. Diseñado para una amplia gama de aplicaciones de apriete y aflojamiento, este juego te ayudará a enfrentar con confianza tareas de reparación y mantenimiento.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699923397/products/gzhve2jbbgoumvrzmlmw.png', 38.5, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('9EDEF19E', 'Alicate P anillo piston Stanley', 'STANLEY', 'El alicate para anillos de pistón Stanley es una herramienta esencial y resistente diseñada para la instalación y extracción de anillos de pistón en motores. Su diseño de calidad y durabilidad garantiza un rendimiento confiable, lo que lo convierte en una elección confiable para profesionales y mecánicos. Este alicate para anillos de pistón Stanley facilita la tarea de trabajar con anillos de pistón de manera eficiente y precisa en una amplia gama de aplicaciones automotrices.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699924717/products/y23pqdh5qkoakca5vwxj.jpg', 24.7, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 3),
('AF470DA5', 'Llave Torx x9 pz Surtek', 'SURTEK', 'El conjunto de llaves Torx x9 piezas de Surtek es una colección esencial para cualquier mecánico o entusiasta del bricolaje. Estas llaves Torx son herramientas de alta calidad diseñadas para resistir el desgaste y proporcionar un agarre seguro en una variedad de tamaños de tornillos Torx. Este conjunto incluye nueve llaves Torx diferentes para abordar una amplia gama de aplicaciones de montaje y desmontaje, lo que lo convierte en una adición valiosa a tu juego de herramientas.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699924321/products/lyzil5opficwvriwaf1u.jpg', 32.5, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('B3D127AC', 'Set de Botadores y Cinceles Stanley', 'STANLEY', 'Este set de botadores y cinceles Stanley es la elección perfecta para profesionales y entusiastas del bricolaje que buscan herramientas de alta calidad para trabajos de carpintería y metalistería. La marca Stanley es conocida por su durabilidad y rendimiento, y este set no es una excepción.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699923071/products/dshk6kvizcbt6oqbhf6b.jpg', 205, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('C605BB1F', ' Alicate de Electricista Stanley 100V E', 'STANLEY', 'Este alicate de electricista Stanley 100V E es la herramienta esencial para los profesionales de la electricidad y los aficionados al bricolaje. Diseñado con la calidad y la durabilidad en mente, este alicate es ideal para cortar cables, pelar conductores y doblar alambres con facilidad.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699922811/products/nrzxwtx9rgjhbelb2edh.png', 80, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 2),
('C762B287', 'Desarmador x 6 pz Stanley', 'STANLEY', 'El conjunto de desarmadores x 6 piezas Stanley es la elección perfecta para todo tipo de tareas de montaje, desmontaje y reparación. Stanley es una marca reconocida por su calidad y durabilidad, y este conjunto no es una excepción. Estas herramientas esenciales están diseñadas para brindar versatilidad y rendimiento en una amplia variedad de aplicaciones.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699923504/products/iozbrrfdoglghvptr41k.png', 23, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 1),
('DBD85DF6', 'Producto 1ABCDDDDDDD', 'MarcaProducto1', 'DADFFASd', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699299450/products/rohzqujamosvnubuv5oy.png', 12, 'Ninguna', '2023-11-06 00:00:00', '2023-11-06 00:00:00', 5),
('E614F5A6', 'Probador de compresión manguera flexible Stanley', 'STANLEY', 'El probador de compresión con manguera flexible Stanley es una herramienta esencial para diagnosticar problemas en el sistema de compresión de motores. Con una manguera flexible que facilita el acceso a espacios reducidos, este probador permite verificar la compresión de los cilindros de manera eficiente y precisa. Diseñado con la calidad y la durabilidad que caracterizan a Stanley, esta herramienta es una elección confiable para profesionales y entusiastas de la automoción.', 'activo', 'https://res.cloudinary.com/dqpzipc8i/image/upload/v1699924418/products/txdtpzxwwx0cpxtooh4v.png', 60, 'Ninguna', '2023-11-13 00:00:00', '2023-11-13 00:00:00', 10);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productinventory`
--

CREATE TABLE `productinventory` (
  `idProductInventory` int(11) NOT NULL,
  `idProduct` varchar(8) NOT NULL,
  `idInventory` int(11) NOT NULL,
  `amountInit` int(11) NOT NULL,
  `priceInit` float NOT NULL,
  `subtotal` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productinventory`
--

INSERT INTO `productinventory` (`idProductInventory`, `idProduct`, `idInventory`, `amountInit`, `priceInit`, `subtotal`) VALUES
(23, '688A8FEE', 1, 120, 44, 5280),
(24, 'C605BB1F', 1, 200, 80, 16000),
(25, '52B6FD6A', 1, 100, 44, 4400),
(26, 'B3D127AC', 1, 50, 205, 10250),
(27, '017EDD5C', 1, 100, 27, 2700),
(28, '3FAB0141', 1, 150, 65, 9750),
(29, '80379AD0', 1, 50, 38.5, 1900),
(30, 'C762B287', 1, 50, 23, 1150),
(31, '05A0B0DC', 1, 25, 206, 5150),
(32, '39153B41', 1, 25, 70, 1750),
(33, '0AA93A9E', 1, 40, 36.9, 1476),
(34, '4938E7FB', 1, 50, 30, 1500),
(35, 'AF470DA5', 1, 50, 32.5, 1625),
(36, 'E614F5A6', 1, 35, 60, 2100),
(37, '3DFAB170', 1, 50, 39, 1950),
(38, '9EDEF19E', 1, 22, 24.7, 543.4000244140625);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `providers`
--

CREATE TABLE `providers` (
  `idProvider` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `state` varchar(50) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `address` text NOT NULL,
  `email` varchar(255) NOT NULL,
  `dateRegister` datetime NOT NULL,
  `description` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `providers`
--

INSERT INTO `providers` (`idProvider`, `name`, `state`, `phone`, `address`, `email`, `dateRegister`, `description`) VALUES
(37, 'DeWalt', 'inactivo', '555-555-5555', '456 Oak Ave', 'dewalt@example.com', '2023-10-30 00:00:00', 'Conocido por sus herramientas eléctricas de alta calidad.'),
(38, 'Bosch', 'activo', '777-777-7777', '789 Elm Rd', 'bosch@example.com', '2023-10-30 00:00:00', 'Fabricante de herramientas eléctricas y productos de seguridad.'),
(39, '3M', 'activo', '333-333-3333', '101 Pine Ln', '3m@example.com', '2023-10-30 00:00:00', 'Ofrece una amplia gama de productos de adhesivos, cintas y suministros de seguridad.'),
(40, 'Sherwin-Williams', 'activo', '999-999-9999', '567 Maple Blvd', 'sherwin@example.com', '2023-10-30 00:00:00', 'Conocido por sus productos de pintura y recubrimientos.'),
(42, 'Schlage', 'activo', '888-888-8888', '333 Birch Rd', 'schlage@example.com', '2023-10-30 00:00:00', 'Especializado en cerraduras y sistemas de seguridad para puertas.'),
(43, 'Phillips', 'activo', '666-666-6666', '444 Willow Ave', 'phillips@example.com', '2023-10-30 00:00:00', 'Fabricante de productos de iluminación y bombillas.'),
(44, 'Makita', 'activo', '111-111-1111', '555 Redwood Ln', 'makita@example.com', '2023-10-30 00:00:00', 'Conocido por sus herramientas eléctricas, especialmente en la industria de la construcción.'),
(45, 'Black & Decker', 'activo', '222-222-2222', '777 Chestnut St', 'bnd@example.com', '2023-10-30 00:00:00', 'Ofrece una amplia gama de herramientas eléctricas y electrodomésticos.'),
(46, 'Ryobi', 'activo', '777-777-7777', '888 Pine Ave', 'ryobi@example.com', '2023-10-30 00:00:00', 'Fabricante de herramientas eléctricas y productos de jardinería.'),
(47, 'Genie', 'activo', '999-999-9999', '111 Oak St', 'genie@example.com', '2023-10-30 00:00:00', 'Especializado en sistemas de apertura de puertas de garaje.'),
(48, 'Toro', 'inactivo', '555-555-5555', '222 Elm Rd', 'toro@example.com', '2023-10-30 00:00:00', 'Fabricante de equipos de jardinería, incluyendo cortacéspedes y sopladores.'),
(49, 'Weber', 'activo', '333-333-3333', '333 Cedar Blvd', 'weber@example.com', '2023-10-30 00:00:00', 'Conocido por sus parrillas y accesorios para barbacoa.'),
(50, 'Honeywell', 'activo', '777-777-7777', '666 Birch St', 'honeywell@example.com', '2023-10-30 00:00:00', 'Fabricante de productos de seguridad y termostatos.'),
(51, 'Master Lock', 'inactivo', '111-111-1111', '555 Willow Rd', 'masterlock@example.com', '2023-10-30 00:00:00', 'Especializado en candados y sistemas de seguridad.'),
(52, 'Proveedor de Ejemplo4', 'inactivo', '1234-133-4444', 'Example ALgo4444', 'Example@gmail.com', '2023-11-02 00:00:00', 'EWDSFASF'),
(53, 'Proveedor de Ejemplo1', 'inactivo', '1234-133-4230', 'Example ALgo', 'Exarewmple@gmail.com', '2023-11-06 00:00:00', 'fasdfasdf'),
(54, 'fasfd', 'activo', '1234-222-4230', 'Example ALgo4444', 'fasd@fsadf.c', '2023-11-06 00:00:00', 'sdfdsafasfdsaf');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `typeuser`
--

CREATE TABLE `typeuser` (
  `idTypeUser` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `typeuser`
--

INSERT INTO `typeuser` (`idTypeUser`, `name`, `description`) VALUES
(1, 'Usuario Normal', 'Usuario con permisos estándar'),
(2, 'Administrador', 'Usuario con permisos de administración');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user`
--

CREATE TABLE `user` (
  `idUser` int(11) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `lastname` varchar(255) NOT NULL,
  `address` text NOT NULL,
  `reference` text NOT NULL,
  `mail` varchar(255) NOT NULL,
  `phone` varchar(30) NOT NULL,
  `city` text NOT NULL,
  `idTypeUser` int(11) NOT NULL,
  `create_user` date NOT NULL,
  `update_user` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `user`
--

INSERT INTO `user` (`idUser`, `password`, `name`, `lastname`, `address`, `reference`, `mail`, `phone`, `city`, `idTypeUser`, `create_user`, `update_user`) VALUES
(1, '$2y$10$63JoXRJZVZR/IUf2O/wR7OpZlIji2EhwC.91/qWz474Ed413T.78i', 'Nombres A', 'Apellidos A', 'Dirección A', 'Dirección de referencia A', 'mail@gmail.com', 'Ciudad A', '12234324', 1, '2023-11-13', NULL),
(2, '$2y$10$m.B9pjtIl31fLT5MHARvPuy4FphE7a0u1zrTxLi0LEZMU9GO4p9PS', 'Manuel Navarro', 'Apellidos A', 'Dirección A', 'Dirección de referencia A', 'mail2@gmail.com', 'Ciudad A', '12234324', 2, '2023-11-13', NULL),
(4, '$2y$10$j971t9RG2GG9mVFV.3ppNO/94VDcu0XJtCSHf4cfAgtwtIEQqkRnu', 'Manuel Navarro', 'Apellidos b', 'Dirección ABB', 'Dirección de referencia ABBBB', 'mail3@gmail.com', '12234324', 'Ciudad ABBB', 1, '2023-11-17', NULL),
(5, '$2y$10$qTS1gEtvZEuoD646eglMG.rgB7XoJ7JwhDGegQ6joetwf46rtHYs2', 'Paolo', 'Guerrero', 'Av. Morropon', 'Colegio San Andres', 'paolo@gmail.com', '123456789', 'Piura', 1, '2023-11-22', NULL);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `buyuser`
--
ALTER TABLE `buyuser`
  ADD PRIMARY KEY (`lastId`),
  ADD UNIQUE KEY `idBuyUser` (`idBuyUser`),
  ADD KEY `FK_OrderProducts_BuyUser` (`idOrder`),
  ADD KEY `FK_BuyUser_User` (`idUser`);

--
-- Indices de la tabla `category`
--
ALTER TABLE `category`
  ADD PRIMARY KEY (`idCategory`);

--
-- Indices de la tabla `inventory`
--
ALTER TABLE `inventory`
  ADD PRIMARY KEY (`idInventory`),
  ADD KEY `FK_Inventory_Provider` (`idProvider`);

--
-- Indices de la tabla `orderbuy`
--
ALTER TABLE `orderbuy`
  ADD PRIMARY KEY (`idLastOrderBuy`),
  ADD UNIQUE KEY `idOrderBuy` (`idOrderBuy`),
  ADD KEY `FK_OrderBuy_PaymentMethod` (`idPaymentMethod`);

--
-- Indices de la tabla `orderdetail`
--
ALTER TABLE `orderdetail`
  ADD PRIMARY KEY (`idOrderDetail`),
  ADD KEY `FK_OrderDetail_OrderBuy` (`idOrderBuy`),
  ADD KEY `FK_OrderDetail_Product` (`idProduct`);

--
-- Indices de la tabla `paymentmethod`
--
ALTER TABLE `paymentmethod`
  ADD PRIMARY KEY (`idPaymentMethod`);

--
-- Indices de la tabla `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`idProduct`),
  ADD KEY `FK_Product_Category` (`idCategory`);

--
-- Indices de la tabla `productinventory`
--
ALTER TABLE `productinventory`
  ADD PRIMARY KEY (`idProductInventory`),
  ADD KEY `FK_ProductInventory_Product` (`idProduct`),
  ADD KEY `FK_ProductInventory_Provider` (`idInventory`);

--
-- Indices de la tabla `providers`
--
ALTER TABLE `providers`
  ADD PRIMARY KEY (`idProvider`);

--
-- Indices de la tabla `typeuser`
--
ALTER TABLE `typeuser`
  ADD PRIMARY KEY (`idTypeUser`);

--
-- Indices de la tabla `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`idUser`),
  ADD UNIQUE KEY `UNIKE_MAIL` (`mail`),
  ADD KEY `FK_Type_User` (`idTypeUser`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `buyuser`
--
ALTER TABLE `buyuser`
  MODIFY `lastId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT de la tabla `category`
--
ALTER TABLE `category`
  MODIFY `idCategory` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `inventory`
--
ALTER TABLE `inventory`
  MODIFY `idInventory` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `orderbuy`
--
ALTER TABLE `orderbuy`
  MODIFY `idLastOrderBuy` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT de la tabla `orderdetail`
--
ALTER TABLE `orderdetail`
  MODIFY `idOrderDetail` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

--
-- AUTO_INCREMENT de la tabla `paymentmethod`
--
ALTER TABLE `paymentmethod`
  MODIFY `idPaymentMethod` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `productinventory`
--
ALTER TABLE `productinventory`
  MODIFY `idProductInventory` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT de la tabla `providers`
--
ALTER TABLE `providers`
  MODIFY `idProvider` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT de la tabla `typeuser`
--
ALTER TABLE `typeuser`
  MODIFY `idTypeUser` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `user`
--
ALTER TABLE `user`
  MODIFY `idUser` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `buyuser`
--
ALTER TABLE `buyuser`
  ADD CONSTRAINT `FK_BuyUser_User` FOREIGN KEY (`idUser`) REFERENCES `user` (`idUser`),
  ADD CONSTRAINT `FK_OrderProducts_BuyUser` FOREIGN KEY (`idOrder`) REFERENCES `orderbuy` (`idOrderBuy`);

--
-- Filtros para la tabla `inventory`
--
ALTER TABLE `inventory`
  ADD CONSTRAINT `FK_Inventory_Provider` FOREIGN KEY (`idProvider`) REFERENCES `providers` (`idProvider`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `orderbuy`
--
ALTER TABLE `orderbuy`
  ADD CONSTRAINT `FK_OrderBuy_PaymentMethod` FOREIGN KEY (`idPaymentMethod`) REFERENCES `paymentmethod` (`idPaymentMethod`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `orderdetail`
--
ALTER TABLE `orderdetail`
  ADD CONSTRAINT `FK_OrderDetail_OrderBuy` FOREIGN KEY (`idOrderBuy`) REFERENCES `orderbuy` (`idOrderBuy`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_OrderDetail_Product` FOREIGN KEY (`idProduct`) REFERENCES `product` (`idProduct`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Filtros para la tabla `product`
--
ALTER TABLE `product`
  ADD CONSTRAINT `FK_Product_Category` FOREIGN KEY (`idCategory`) REFERENCES `category` (`idCategory`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `productinventory`
--
ALTER TABLE `productinventory`
  ADD CONSTRAINT `FK_ProductInventory_Product` FOREIGN KEY (`idProduct`) REFERENCES `product` (`idProduct`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_ProductInventory_Provider` FOREIGN KEY (`idInventory`) REFERENCES `inventory` (`idInventory`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `user`
--
ALTER TABLE `user`
  ADD CONSTRAINT `FK_Type_User` FOREIGN KEY (`idTypeUser`) REFERENCES `typeuser` (`idTypeUser`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
