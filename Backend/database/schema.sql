-- =====================================================
-- BASE DE DATOS POSTGRESQL PARA SISTEMA DE VOTACIÓN
-- =====================================================

-- Crear base de datos (ejecutar en psql o herramienta similar)
-- CREATE DATABASE votacion_delegate;

-- Conectar a la base de datos
-- \c votacion_delegate

-- =====================================================
-- TABLAS
-- =====================================================

-- Tabla de candidatos
CREATE TABLE IF NOT EXISTS candidatos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    numero INTEGER NOT NULL UNIQUE,
    foto_url TEXT,
    votos INTEGER DEFAULT 0,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de votos
CREATE TABLE IF NOT EXISTS votos (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL UNIQUE,
    candidato_id INTEGER NOT NULL REFERENCES candidatos(id),
    correo VARCHAR(255) NOT NULL UNIQUE,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    ubicacion_lat DOUBLE PRECISION,
    ubicacion_lng DOUBLE PRECISION
);

-- Tabla de usuarios verificados (para controlar quién puede votar)
CREATE TABLE IF NOT EXISTS usuarios_verificados (
    id SERIAL PRIMARY KEY,
    correo VARCHAR(255) NOT NULL UNIQUE,
    nombre VARCHAR(100),
    verificado BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES)
-- =====================================================

-- 1. Obtener todos los candidatos
CREATE OR REPLACE FUNCTION sp_obtener_candidatos()
RETURNS TABLE (
    id INTEGER,
    nombre VARCHAR(100),
    numero INTEGER,
    foto_url TEXT,
    votos INTEGER,
    descripcion TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.nombre,
        c.numero,
        c.foto_url,
        c.votos,
        c.descripcion,
        c.created_at,
        c.updated_at
    FROM candidatos c
    ORDER BY c.numero ASC;
END;
$$ LANGUAGE plpgsql;

-- 2. Obtener candidato por ID
CREATE OR REPLACE FUNCTION sp_obtener_candidato_por_id(p_id INTEGER)
RETURNS TABLE (
    id INTEGER,
    nombre VARCHAR(100),
    numero INTEGER,
    foto_url TEXT,
    votos INTEGER,
    descripcion TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.nombre,
        c.numero,
        c.foto_url,
        c.votos,
        c.descripcion,
        c.created_at,
        c.updated_at
    FROM candidatos c
    WHERE c.id = p_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Verificar si usuario ya votó
CREATE OR REPLACE FUNCTION sp_verificar_ya_voto(p_user_id VARCHAR(100))
RETURNS BOOLEAN AS $$
DECLARE
    existe_voto BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM votos WHERE user_id = p_user_id) INTO existe_voto;
    RETURN existe_voto;
END;
$$ LANGUAGE plpgsql;

-- 4. Verificar si correo ya votó
CREATE OR REPLACE FUNCTION sp_verificar_correo_ya_voto(p_correo VARCHAR(255))
RETURNS BOOLEAN AS $$
DECLARE
    existe_voto BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM votos WHERE correo = p_correo) INTO existe_voto;
    RETURN existe_voto;
END;
$$ LANGUAGE plpgsql;

-- 5. Registrar voto (con transacción atómica)
CREATE OR REPLACE FUNCTION sp_registrar_voto(
    p_user_id VARCHAR(100),
    p_candidato_id INTEGER,
    p_correo VARCHAR(255),
    p_ip_address VARCHAR(45) DEFAULT NULL,
    p_ubicacion_lat DOUBLE PRECISION DEFAULT NULL,
    p_ubicacion_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message VARCHAR(255)
) AS $$
DECLARE
    candidato_existe BOOLEAN;
    voto_existe BOOLEAN;
BEGIN
    -- Verificar si el candidato existe
    SELECT EXISTS(SELECT 1 FROM candidatos WHERE id = p_candidato_id) INTO candidato_existe;
    
    IF NOT candidato_existe THEN
        RETURN QUERY SELECT FALSE, 'Candidato no encontrado';
        RETURN;
    END IF;

    -- Verificar si el usuario ya votó
    SELECT EXISTS(SELECT 1 FROM votos WHERE user_id = p_user_id) INTO voto_existe;
    
    IF voto_existe THEN
        RETURN QUERY SELECT FALSE, 'El usuario ya ha votado';
        RETURN;
    END IF;

    -- Verificar si el correo ya votó
    SELECT EXISTS(SELECT 1 FROM votos WHERE correo = p_correo) INTO voto_existe;
    
    IF voto_existe THEN
        RETURN QUERY SELECT FALSE, 'El correo ya ha sido usado para votar';
        RETURN;
    END IF;

    -- Insertar voto
    INSERT INTO votos (user_id, candidato_id, correo, ip_address, ubicacion_lat, ubicacion_lng)
    VALUES (p_user_id, p_candidato_id, p_correo, p_ip_address, p_ubicacion_lat, p_ubicacion_lng);

    -- Incrementar contador de votos del candidato
    UPDATE candidatos 
    SET votos = votos + 1, 
        updated_at = CURRENT_TIMESTAMP 
    WHERE id = p_candidato_id;

    RETURN QUERY SELECT TRUE, 'Voto registrado exitosamente';
END;
$$ LANGUAGE plpgsql;

-- 6. Obtener conteo de votos por candidato
CREATE OR REPLACE FUNCTION sp_obtener_conteo_votos()
RETURNS TABLE (
    candidato_id INTEGER,
    nombre VARCHAR(100),
    numero INTEGER,
    votos INTEGER,
    porcentaje DECIMAL(5,2)
) AS $$
DECLARE
    total_votos INTEGER;
BEGIN
    -- Obtener total de votos
    SELECT COALESCE(SUM(votos), 0) INTO total_votos FROM candidatos;

    RETURN QUERY
    SELECT 
        c.id AS candidato_id,
        c.nombre,
        c.numero,
        c.votos,
        CASE 
            WHEN total_votos > 0 THEN ROUND((c.votos::DECIMAL / total_votos::DECIMAL) * 100, 2)
            ELSE 0
        END AS porcentaje
    FROM candidatos c
    ORDER BY c.votos DESC;
END;
$$ LANGUAGE plpgsql;

-- 7. Obtener estadísticas generales
CREATE OR REPLACE FUNCTION sp_obtener_estadisticas()
RETURNS TABLE (
    total_votos INTEGER,
    total_candidatos INTEGER,
    candidato_ganador VARCHAR(100),
    votos_ganador INTEGER
) AS $$
DECLARE
    v_total_votos INTEGER;
    v_total_candidatos INTEGER;
    v_candidato_ganador VARCHAR(100);
    v_votos_ganador INTEGER;
BEGIN
    -- Total de votos
    SELECT COALESCE(SUM(votos), 0) INTO v_total_votos FROM candidatos;

    -- Total de candidatos
    SELECT COUNT(*) INTO v_total_candidatos FROM candidatos;

    -- Candidato con más votos
    SELECT c.nombre, c.votos 
    INTO v_candidato_ganador, v_votos_ganador
    FROM candidatos c
    ORDER BY c.votos DESC
    LIMIT 1;

    RETURN QUERY
    SELECT 
        v_total_votos,
        v_total_candidatos,
        COALESCE(v_candidato_ganador, 'Sin candidato'),
        COALESCE(v_votos_ganador, 0);
END;
$$ LANGUAGE plpgsql;

-- 8. Crear candidato
CREATE OR REPLACE FUNCTION sp_crear_candidato(
    p_nombre VARCHAR(100),
    p_numero INTEGER,
    p_foto_url TEXT DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message VARCHAR(255),
    candidato_id INTEGER
) AS $$
DECLARE
    numero_existe BOOLEAN;
BEGIN
    -- Verificar si el número ya existe
    SELECT EXISTS(SELECT 1 FROM candidatos WHERE numero = p_numero) INTO numero_existe;
    
    IF numero_existe THEN
        RETURN QUERY SELECT FALSE, 'El número de candidato ya está en uso', NULL;
        RETURN;
    END IF;

    -- Insertar candidato
    INSERT INTO candidatos (nombre, numero, foto_url, descripcion)
    VALUES (p_nombre, p_numero, p_foto_url, p_descripcion);

    RETURN QUERY SELECT TRUE, 'Candidato creado exitosamente', LASTVAL();
END;
$$ LANGUAGE plpgsql;

-- 9. Eliminar candidato
CREATE OR REPLACE FUNCTION sp_eliminar_candidato(p_id INTEGER)
RETURNS TABLE (
    success BOOLEAN,
    message VARCHAR(255)
) AS $$
DECLARE
    candidato_existe BOOLEAN;
    tiene_votos BOOLEAN;
BEGIN
    -- Verificar si el candidato existe
    SELECT EXISTS(SELECT 1 FROM candidatos WHERE id = p_id) INTO candidato_existe;
    
    IF NOT candidato_existe THEN
        RETURN QUERY SELECT FALSE, 'Candidato no encontrado';
        RETURN;
    END IF;

    -- Verificar si tiene votos
    SELECT EXISTS(SELECT 1 FROM votos WHERE candidato_id = p_id) INTO tiene_votos;
    
    IF tiene_votos THEN
        RETURN QUERY SELECT FALSE, 'No se puede eliminar un candidato con votos registrados';
        RETURN;
    END IF;

    -- Eliminar candidato
    DELETE FROM candidatos WHERE id = p_id;

    RETURN QUERY SELECT TRUE, 'Candidato eliminado exitosamente';
END;
$$ LANGUAGE plpgsql;

-- 10. Reiniciar elección (borrar todos los votos)
CREATE OR REPLACE FUNCTION sp_reiniciar_eleccion()
RETURNS TABLE (
    success BOOLEAN,
    message VARCHAR(255),
    votos_eliminados INTEGER
) AS $$
DECLARE
    votos_eliminados INTEGER;
BEGIN
    -- Contar votos antes de eliminar
    SELECT COUNT(*) INTO votos_eliminados FROM votos;

    -- Eliminar todos los votos
    DELETE FROM votos;

    -- Reiniciar contadores de candidatos
    UPDATE candidatos SET votos = 0, updated_at = CURRENT_TIMESTAMP;

    RETURN QUERY SELECT TRUE, 'Elección reiniciada exitosamente', votos_eliminados;
END;
$$ LANGUAGE plpgsql;

-- 11. Verificar si el usuario puede votar (verificado y dentro del campus)
CREATE OR REPLACE FUNCTION sp_verificar_usuario_puede_votar(
    p_correo VARCHAR(255),
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_lat_campus DOUBLE PRECISION DEFAULT -12.0753,  -- Latitud UC (valor por defecto)
    p_lng_campus DOUBLE PRECISION DEFAULT -77.0821,  -- Longitud UC (valor por defecto)
    p_radio_campus DOUBLE PRECISION DEFAULT 0.5     -- Radio en km (500 metros)
)
RETURNS TABLE (
    puede_votar BOOLEAN,
    message VARCHAR(255)
) AS $$
DECLARE
    usuario_verificado BOOLEAN;
    ya_voto BOOLEAN;
    dentro_campus BOOLEAN;
    distancia DOUBLE PRECISION;
BEGIN
    -- Verificar si el usuario está verificado
    SELECT verificado INTO usuario_verificado 
    FROM usuarios_verificados 
    WHERE correo = p_correo;

    IF usuario_verificado IS NULL OR usuario_verificado = FALSE THEN
        RETURN QUERY SELECT FALSE, 'Usuario no verificado';
        RETURN;
    END IF;

    -- Verificar si ya votó
    SELECT EXISTS(SELECT 1 FROM votos WHERE correo = p_correo) INTO ya_voto;
    
    IF ya_voto THEN
        RETURN QUERY SELECT FALSE, 'Ya has votado';
        RETURN;
    END IF;

    -- Calcular distancia (fórmula de Haversine simplificada)
    distancia := (
        SQRT(
            POW(69.1 * (p_lat - p_lat_campus), 2) +
            POW(69.1 * (p_lng_campus - p_lng) * COS(p_lat / 57.3), 2)
        )
    );

    IF distancia <= p_radio_campus THEN
        dentro_campus := TRUE;
    ELSE
        dentro_campus := FALSE;
    END IF;

    IF NOT dentro_campus THEN
        RETURN QUERY SELECT FALSE, 'Debes estar dentro del campus universitario';
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Usuario puede votar';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- DATOS DE PRUEBA (INSERTS DE EJEMPLO)
-- =====================================================

-- Insertar candidatos de prueba
INSERT INTO candidatos (nombre, numero, foto_url, descripcion, votos) VALUES
('Juan Pérez', 1, 'https://example.com/juan.jpg', 'Estudiante de Ingeniería', 0),
('María García', 2, 'https://example.com/maria.jpg', 'Estudiante de Medicina', 0),
('Carlos López', 3, 'https://example.com/carlos.jpg', 'Estudiante de Derecho', 0),
('Ana Martínez', 4, 'https://example.com/ana.jpg', 'Estudiante de Economía', 0);

-- Insertar usuarios verificados de prueba
INSERT INTO usuarios_verificados (correo, nombre, verificado) VALUES
('juan@uc.edu.pe', 'Juan Pérez', TRUE),
('maria@uc.edu.pe', 'María García', TRUE),
('carlos@uc.edu.pe', 'Carlos López', TRUE),
('ana@uc.edu.pe', 'Ana Martínez', TRUE);

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================
