-- Creación de la base de datos
CREATE DATABASE IF NOT EXISTS panaderia_2526;
USE panaderia_2526;

-- Tabla 1: Clientes
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    es_vip BOOLEAN DEFAULT FALSE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabla 2: Productos
CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria ENUM('Pan', 'Bollería', 'Pastelería', 'Bebidas') NOT NULL,
    precio DECIMAL(5,2) NOT NULL,
    stock SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    requiere_frio BOOLEAN DEFAULT FALSE,
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabla 3: Pedidos
CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    estado ENUM('Pendiente', 'Preparando', 'Completado', 'Cancelado') DEFAULT 'Pendiente',
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    CONSTRAINT fk_pedidos_cliente 
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabla 4: Detalles del Pedido
CREATE TABLE detalles_pedido (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad SMALLINT UNSIGNED NOT NULL,
    subtotal DECIMAL(7,2) NOT NULL, -- Se calcula como cantidad * precio del producto
    CONSTRAINT fk_detalles_pedido 
        FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_detalles_producto 
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- --------------------------------------------------------
-- 1. Inserts para la tabla CLIENTES
-- --------------------------------------------------------
INSERT INTO clientes (nombre, email, es_vip) VALUES
('Ana García', 'ana.garcia@email.com', TRUE),
('Carlos López', 'clopez88@email.com', FALSE),
('María Fernández', 'maria.fer_pan@email.com', TRUE),
('Juan Pérez', 'jperez_vecino@email.com', FALSE),
('Lucía Gómez', 'lucia.gomez92@email.com', FALSE);

-- --------------------------------------------------------
-- 2. Inserts para la tabla PRODUCTOS
-- --------------------------------------------------------
INSERT INTO productos (nombre, categoria, precio, stock, requiere_frio) VALUES
('Hogaza de Masa Madre', 'Pan', 3.50, 20, FALSE),
('Croissant de Mantequilla', 'Bollería', 1.80, 45, FALSE),
('Tarta de Queso con Frutos Rojos', 'Pastelería', 18.00, 5, TRUE),
('Zumo de Naranja Natural', 'Bebidas', 2.20, 30, TRUE),
('Napolitana de Chocolate', 'Bollería', 1.90, 40, FALSE);

-- --------------------------------------------------------
-- 3. Inserts para la tabla PEDIDOS
-- --------------------------------------------------------
INSERT INTO pedidos (id_cliente, estado, observaciones) VALUES
(1, 'Completado', 'Entregado en mano. Cliente muy habitual.'),
(2, 'Pendiente', 'Para recoger a las 11:30 AM.'),
(3, 'Preparando', 'La tarta debe llevar una vela con el número 30.'),
(4, 'Cancelado', 'El cliente llamó para anular por imprevisto.'),
(5, 'Completado', NULL);

-- --------------------------------------------------------
-- 4. Inserts para la tabla DETALLES_PEDIDO
-- --------------------------------------------------------
INSERT INTO detalles_pedido (id_pedido, id_producto, cantidad, subtotal) VALUES
-- Pedido 1 de Ana
-- 2 Hogazas a 3.50€ c/u = 7.00€
(1, 1, 2, 7.00),
-- 1 Zumo a 2.20€ c/u = 2.20€
(1, 4, 1, 2.20),

-- Pedido 2 de Carlos
-- 4 Croissants a 1.80€ c/u = 7.20€
(2, 2, 4, 7.20),

-- Pedido 3 de María
-- 1 Tarta de queso a 18.00€ = 18.00€
(3, 3, 1, 18.00),

-- Pedido 5 de Lucía
-- 3 Napolitanas a 1.90€ c/u = 5.70€
(5, 5, 3, 5.70);

/*
Ejercicio 1: Autocalcular el subtotal de una línea de pedido

    Contexto: Cuando un empleado registra un nuevo detalle en un pedido, solo debería tener que introducir el id_pedido, el id_producto y la cantidad.

	Requisito: al dar de alta el detalle de un pedido, se debe informar automáticamente el campo subtotal.

Ejercicio 2: Actualizar el inventario tras una venta

    Contexto: Una vez que se ha confirmado que un producto se ha añadido a un pedido, el stock en la tienda debe disminuir para reflejar la realidad del inventario.

    Requisito: al realizar un pedido, se debe actualizar automáticamente el stock de ese producto en función de la cantidad pedida.
	
Ejercicio 3: Evitar rebajas drásticas por error humano

    Contexto: Los precios de los pasteles y panes fluctúan, pero un empleado podría equivocarse al teclear (por ejemplo, poner 0.50€ en lugar de 5.00€).

    Requisito: impedir la actualización de un producto si el nuevo precio es inferior al 50% del precio antiguo. Si esto ocurre, el mensaje de error debe advirtir que la rebaja es demasiado grande.

Ejercicio 4: Restaurar el stock si se cancela un pedido

    Contexto: A veces los clientes cancelan sus encargos de última hora. Si un pedido pasa a estar 'Cancelado', los panes o pasteles reservados deben volver a estar disponibles en el inventario.

    Requisito: detectar si el estado de un pedido se cancela y devolver la cantidad de cada línea al stock de su respectivo producto.

Ejercicio 5: Protección de clientes VIP frente a borrados accidentales

    Contexto: Los clientes vip son cruciales para el negocio de la panadería y no deberían poder ser eliminados del sistema directamente.

    Requisito: impedir borrado de clientes vip indicando: "No se puede eliminar un cliente VIP. Revoque sus privilegios primero."
*/



-- Segunda parte

-- Tabla para el log de auditoría
CREATE TABLE log_cambios_precio (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_anterior DECIMAL(5,2) NOT NULL,
    precio_nuevo DECIMAL(5,2) NOT NULL,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario_db VARCHAR(50) -- Para registrar qué usuario de la BD hizo el cambio
) ENGINE=InnoDB;

/*
Ejercicio 6: Auditoría de cambios de precios (Tabla Log)

    Contexto: El precio de los productos es un dato muy sensible. El dueño de la panadería quiere llevar un registro estricto (una auditoría) cada vez que alguien modifique el precio de un pan o un pastel, para saber cuál era el precio anterior, cuál es el nuevo y cuándo se cambió.

    Requisito: satisfacer necesidad del cliente

Ejercicio 7: Control estricto del flujo de estados de un pedido

    Contexto: Los pedidos tienen un ciclo de vida lógico (Pendiente -> Preparando -> Completado o Cancelado). Una vez que un pedido ha sido marcado como 'Completado' (entregado al cliente) o 'Cancelado', por política de la empresa, ya no se puede volver a cambiar su estado a 'Pendiente' o 'Preparando'. Esto evita fraudes o confusiones en el mostrador.

    Requisito: satisfacer necesidad del cliente
*/