# NIVEL 1 : 
# Descargar los archivos CSV, estudiar y diseñar una base de datos con un esquema de estrella que contenga
# al menos 4 tablas de las que se pueda realizar algunas consultas.

# Hemos analizado el contenido de cada archivo y observado el encabezado en cada uno para poder crear las columnas
# de las tablas de manera apropiada.
# Ahora vamos a enumerar en pasos la secuencia de acciones realizadas.


# PASO 1: Se crea una nueva BD denominada transactionsTS4:

CREATE DATABASE transactionsTS4;
USE transactionsTS4;

/* PASO 2: Ahora se crean 4 tablas, según lo solicitado en el enunciado. Las tablas a crear serían companies, credit_cards,
   users y transactions. */


CREATE TABLE companies (
	company_id VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(60),
    country VARCHAR(60),
    website VARCHAR(60)
		);

CREATE TABLE credit_cards (
	id VARCHAR(15) PRIMARY KEY,
    user_id VARCHAR(10),
    iban VARCHAR(50),
    pan VARCHAR(50), 
    pin VARCHAR(4),
    cvv VARCHAR(3),
    track1 VARCHAR(60),
    track2 VARCHAR(60),
    expiring_date VARCHAR(10)
		);
        
        
CREATE TABLE users (
	id INT PRIMARY KEY,
    NAME VARCHAR(60),
    surname VARCHAR(60),
    phone VARCHAR(15),
    email VARCHAR(60),
    birth_date VARCHAR(30),
    country VARCHAR(60),
    city VARCHAR(60),
    postal_code VARCHAR(15),
    address VARCHAR(250)
		);

CREATE TABLE transactions (
	id VARCHAR(255) PRIMARY KEY,
    card_id VARCHAR(15),
    business_id VARCHAR(15),
    TIMESTAMP VARCHAR(35),
    amount DECIMAL(15,2),
    declined BOOLEAN,
    product_ids VARCHAR(25),
    user_id INT,
    lat VARCHAR(60),
    longitude VARCHAR(60)
		);
        
# Las relaciones con las Foreign key en la tabla transactions se crearán más adelante, luego de cargar la data.

# PASO 3: Ahora insertaremos la data de cada archivo en la correspondiente tabla ya creada en el paso anterior.

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv"
INTO TABLE companies
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv"
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# Los 3 archivos: users_ca, users_uk y users_usa; se cargarán en la misma tabla users, como se observa
# a continuación:

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv"
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv"
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv"
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# PASO 4: Ahora si podemos establecer las relaciones entre las tablas a través de las Foreign key.
# De esta manera se habrán establecido correctamente las relaciones entre la tabla de hechos y las tablas de dimensiones.

ALTER TABLE transactions
	ADD FOREIGN KEY(business_id) REFERENCES companies(company_id),
    ADD FOREIGN KEY(card_id) REFERENCES credit_cards(id),
    ADD FOREIGN KEY(user_id) REFERENCES users(id);

# Dados los pasos anteriores, disponemos de la Base de Datos transactionsTS4 bien montada y lista para ejecutar las queries solicitadas.

/* Ejercicio 1.1 : Realizar una subconsulta que muestre a todos los usuarios con más de 30 transacciones
   utilizando al menos 2 tablas  */

# Necesitaremos datos de las tablas transactions y users; es por ello que serán las 2 tablas que utilizaremos.

# La solución utilizando subconsulta, como solicitado, sería de la siguiente forma:

SELECT *, (SELECT COUNT(user_id) FROM transactions
			WHERE transactions.user_id = users.id ) AS cantidad_trans
FROM users
GROUP BY users.id
HAVING cantidad_trans > 30;


# La solución alternativa utilizando JOIN sería de la siguiente forma:
      
SELECT u.name AS nombre, u.surname AS apellido, u.country AS pais, user_id AS ID, count(user_id) AS cantidad_trans
FROM transactions t
JOIN users u ON t.user_id = u.id
GROUP BY user_id
HAVING cantidad_trans > 30;

# *Para la solución mediante el uso de JOIN hemos decidido cargar solo algunos campos de la tabla users.   
# Mientras que para la solución con subconsulta hemos mostrado todos los campos de la tabla users.

   
/* Ejercicio 1.2 : Mostrar la media de amount por IBAN de las tarjetas de crédito en la compañía Donec Ltd., 
utilizar por lo menos 2 tablas.  */

# Para la siguiente query requerimos incluir una tercera tabla que contenga información del iban, por lo que  
# utilizaremos las tablas: transactions, credit_cards y companies.


SELECT co.company_name AS compañia, cc.iban, ROUND(AVG(tr.amount),2) AS media_transacciones
FROM transactions AS tr
JOIN companies AS co ON co.company_id=tr.business_id
JOIN credit_cards AS cc ON cc.id = tr.card_id
WHERE company_name = 'Donec Ltd'
GROUP BY cc.iban;


# NIVEL 2 : Crea una nueva tabla que refleje el estado de las tarjetas de crédito basado en si las últimas
# 3 transacciones fueron declinadas y genera la siguiente consulta:

/* Ejercicio 2.1: ¿Cuántas tarjetas están activas?  */

/* Solucion: 
  Paso 1: se pasa a crear una nueva tabla denominada card_status. La tabla contendrá 2 campos utiles para 
  nuestro proposito, los cuales denominados card_id y status */


CREATE TABLE card_status (
	card_id VARCHAR(15),
    status VARCHAR(50));
    

/* Paso 2: Ya creada la tabla, ahora pasamos a rellenarla. Cabe destacar la creación de una tabla 
  temporal (CTE: Common Table Expression) denominada transacciones_tarjeta2 que contiene como columnas 
  algunas extraidas y generadas de la tabla transactions.
  Además, con el uso del operador CASE y las condiciones que le siguen se calculará el estado de la tarjeta. En donde si 
  la suma de declined en las 3 últimas transacciones es de 2 o menos se considera como "tarjeta activa". En cualquier
  otro caso se considera como "tarjeta inactiva".
  El filtro para considerar únicamente las 3 últimas transacciones de cada tarjeta sería el siguiente:
   WHERE row_transaction <= 3
  */


INSERT INTO card_status (card_id, status)
WITH transacciones_tarjeta2 AS (
	SELECT card_id, 
		timestamp, 
		declined, 
		ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS row_transaction
FROM transactions)
SELECT card_id,
	CASE 
		WHEN SUM(declined) <= 2 THEN 'tarjeta activa'
		ELSE 'tarjeta inactiva'
	END AS estado_tarjeta
FROM transacciones_tarjeta2
WHERE row_transaction <= 3 
GROUP BY card_id;


# Paso 3: Verificamos la data de la tabla card_status recién creada:

SELECT card_id, status AS estado_tarjeta
FROM card_status; 


# Ejercicio 2.1: ¿Cuántas tarjetas están activas?

# Solución: Sería un simple conteo de todos los registros de la tabla card_status utilizando el 
# filtro WHERE status = 'tarjeta activa';

SELECT COUNT(*) AS 'tarjetas activas'
FROM card_status
WHERE status ='tarjeta activa';


--------------------------------------------------- ***** -----------------------------------------------------------
/*  Modificaciones de la última actualización:
1) En la tabla transactions ya no se han creado las relaciones con las foreign key a la hora de crear la tabla. En su lugar,
   Se ha creado la tabla transactions sin las foreign key; luego de cargar los datos recién se han establecido las relaciones
   con las foreign key para así evitar el uso de la activación / desactivación de las Foreign Key. 

2) Se ha explicado el paso a paso de cada acción relevante, a diferencia de la versión anterior, en la que se había omitido
	en gran medida.

3) Se ha incluido la resolución del ejercicio del nivel 2.

*/
