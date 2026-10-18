\set ON_ERROR_STOP on

SELECT 'CREATE ROLE labapp LOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'labapp')
\gexec

SELECT 'CREATE DATABASE labdb'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'labdb')
\gexec

REVOKE CONNECT ON DATABASE labdb FROM PUBLIC;
GRANT  CONNECT ON DATABASE labdb TO labapp;
REVOKE CONNECT ON DATABASE postgres, template1 FROM PUBLIC;

\connect labdb

CREATE TABLE IF NOT EXISTS productos (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre     varchar(100)   NOT NULL UNIQUE,
    precio     numeric(10, 2) NOT NULL CHECK (precio >= 0),
    creado_en  timestamptz    NOT NULL DEFAULT now()
);

INSERT INTO productos (nombre, precio) VALUES
    ('Teclado mecánico',     45.99),
    ('Ratón inalámbrico',    19.50),
    ('Monitor 24 pulgadas', 149.00),
    ('Webcam HD',            32.75)
ON CONFLICT (nombre) DO NOTHING;

GRANT USAGE  ON SCHEMA public TO labapp;
GRANT SELECT ON productos     TO labapp;

SELECT id, nombre, precio FROM productos ORDER BY id;
\dp productos

-- Opciones configuradas:
-- ----------------------
-- \set ON_ERROR_STOP on -> psql para en el primer error
-- SELECT ... WHERE NOT EXISTS + \gexec -> crea el rol o la base solo si no existen
-- LOGIN -> el rol puede iniciar sesión; sin contraseña, se pone a mano con \password
-- REVOKE CONNECT ... FROM PUBLIC -> por defecto todos entran en todas las bases; se lo quito
-- GRANT CONNECT ... TO labapp -> solo labapp (y el administrador) entran en labdb
-- \connect labdb -> lo que sigue va dentro de labdb
-- GENERATED ALWAYS AS IDENTITY -> número automático (la forma estándar de SERIAL)
-- NOT NULL UNIQUE -> obligatorio y sin repetidos
-- numeric(10, 2) CHECK (precio >= 0) -> dos decimales exactos, nunca negativo
-- timestamptz DEFAULT now() -> fecha y hora con zona, se rellena sola
-- ON CONFLICT (nombre) DO NOTHING -> repetir el archivo no duplica filas
-- GRANT USAGE ON SCHEMA public -> puede entrar en el esquema public, no crear objetos
-- GRANT SELECT ON productos -> solo lectura; va después del CREATE TABLE porque la tabla tiene que existir
-- \dp productos -> tiene que salir labapp=r/postgres