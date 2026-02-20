# Guía de Reutilización del Backend

## 1. Archivos Necesarios

Copia estas carpetas y archivos a tu nuevo proyecto:

```
tu-nuevo-proyecto/
├── main.py                    # Punto de entrada (adaptar)
├── requirements.txt           # Dependencias
├── app/
│   ├── __init__.py
│   └── main.py               # Configuración FastAPI (adaptar)
├── config/
│   ├── __init__.py
│   └── database.py           # Conexión DB (adaptar)
├── models/
│   ├── __init__.py           # (adaptar - importar tus modelos)
│   └── [tus_modelos].py      # Tus modelos SQLAlchemy
├── schemas/
│   ├── __init__.py           # (adaptar - importar tus schemas)
│   └── [tus_schemas].py      # Tus schemas Pydantic
└── routers/
    ├── __init__.py
    └── [tus_routers].py      # Tus endpoints
```

## 2. Instalación en Nuevo Proyecto

```bash
# 1. Crear entorno virtual
python -m venv venv

# 2. Activar entorno virtual
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 3. Instalar dependencias
pip install -r requirements.txt
```

## 3. Qué Debes Adaptar

### A. Configuración de Base de Datos (`config/database.py`)

```python
# Cambia la cadena de conexión según tu DB:

# SQL Server (actual)
connection_string = (
    r"mssql+pyodbc://@localhost\SQLEXPRESS/FastAPI_DB"
    r"?driver=ODBC+Driver+17+for+SQL+Server"
    r"&trusted_connection=yes"
)

# PostgreSQL
connection_string = "postgresql://usuario:password@localhost:5432/nombre_db"

# MySQL
connection_string = "mysql+pymysql://usuario:password@localhost:3306/nombre_db"

# SQLite
connection_string = "sqlite:///./nombre_db.db"
```

### B. Modelos (`models/`)

Crea tus propios modelos siguiendo este patrón:

```python
from sqlalchemy import Column, Integer, String
from config.database import Base

class TuModelo(Base):
    __tablename__ = "nombre_tabla"
    
    id = Column(Integer, primary_key=True)
    campo1 = Column(String(100))
    campo2 = Column(Integer)
```

### C. Schemas (`schemas/`)

Crea tus schemas Pydantic:

```python
from pydantic import BaseModel
from typing import Optional

class TuModeloBase(BaseModel):
    campo1: str
    campo2: int

class TuModeloCreate(TuModeloBase):
    pass

class TuModeloUpdate(BaseModel):
    campo1: Optional[str] = None
    campo2: Optional[int] = None

class TuModelo(TuModeloBase):
    id: int
    
    class Config:
        from_attributes = True
```

### D. Routers (`routers/`)

Crea tus endpoints:

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from config.database import SessionLocal
from models.tu_modelo import TuModelo
from schemas.tu_modelo import TuModelo as TuModeloSchema, TuModeloCreate

router = APIRouter(prefix="/tu-endpoint", tags=["tu-etiqueta"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/")
def listar(db: Session = Depends(get_db)):
    return db.query(TuModelo).all()
```

### E. Registrar Routers (`app/main.py`)

```python
from fastapi import FastAPI
from routers import tu_router

app = FastAPI()

# Incluir tus routers
app.include_router(tu_router.router)

@app.get("/")
def home():
    return {"mensaje": "Tu API funcionando"}
```

## 4. Ejecutar el Servidor

```bash
# Opción 1
python main.py

# Opción 2
uvicorn app.main:app --reload
```

## 5. Ejemplo Completo de Adaptación

### Paso 1: Copiar estructura
```bash
cp -r config/ models/ schemas/ routers/ app/ tu-nuevo-proyecto/
cp requirements.txt main.py tu-nuevo-proyecto/
```

### Paso 2: Crear tu modelo
```python
# models/producto.py
from sqlalchemy import Column, Integer, String, Float
from config.database import Base

class Producto(Base):
    __tablename__ = "productos"
    
    id = Column(Integer, primary_key=True)
    nombre = Column(String(100))
    precio = Column(Float)
    stock = Column(Integer)
```

### Paso 3: Crear tu schema
```python
# schemas/producto.py
from pydantic import BaseModel
from typing import Optional

class ProductoBase(BaseModel):
    nombre: str
    precio: float
    stock: int

class ProductoCreate(ProductoBase):
    pass

class ProductoUpdate(BaseModel):
    nombre: Optional[str] = None
    precio: Optional[float] = None
    stock: Optional[int] = None

class Producto(ProductoBase):
    id: int
    
    class Config:
        from_attributes = True
```

### Paso 4: Crear tu router
```python
# routers/productos.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from config.database import SessionLocal
from models.producto import Producto
from schemas.producto import Producto as ProductoSchema, ProductoCreate, ProductoUpdate

router = APIRouter(prefix="/productos", tags=["productos"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/", response_model=List[ProductoSchema])
def obtener_productos(db: Session = Depends(get_db)):
    return db.query(Producto).all()

@router.post("/", response_model=ProductoSchema)
def crear_producto(producto: ProductoCreate, db: Session = Depends(get_db)):
    db_producto = Producto(**producto.dict())
    db.add(db_producto)
    db.commit()
    db.refresh(db_producto)
    return db_producto
```

### Paso 5: Actualizar imports
```python
# models/__init__.py
from .producto import Producto

# schemas/__init__.py
from .producto import ProductoBase, ProductoCreate, ProductoUpdate, Producto

# app/main.py
from fastapi import FastAPI
from routers.productos import router as productos_router

app = FastAPI()
app.include_router(productos_router)
```

## 6. Notas Importantes

- **Siempre activa el entorno virtual** antes de trabajar
- **No subas `venv/`** a git (agrega a `.gitignore`)
- **Cambia la configuración de DB** en `config/database.py`
- **Crea tus propios modelos** según tus necesidades
- **La estructura es modular** - puedes agregar más routers fácilmente

## 7. Estructura de Base de Datos de Ejemplo

Este proyecto usa estas tablas SQL Server:

```sql
CREATE TABLE candidatos (
    candidatoId INT IDENTITY(1,1) PRIMARY KEY,
    cargo VARCHAR(100),
    experiencia VARCHAR(300),
    imagen VARCHAR(500),
    nombre VARCHAR(100),
    numero INT,
    propuesta VARCHAR(300),
    semestre VARCHAR(50),
    vision VARCHAR(300),
    votos INT DEFAULT 0
);

CREATE TABLE votos (
    votoId INT IDENTITY(1,1) PRIMARY KEY,
    candidatoId INT,
    correo VARCHAR(150),
    fecha DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_candidato FOREIGN KEY (candidatoId) REFERENCES candidatos(candidatoId)
);
```

Para tu nuevo proyecto, crea las tablas que necesites.
