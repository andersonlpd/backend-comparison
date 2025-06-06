from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
import time
import re
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
from starlette.requests import Request

from app.api.router import api_router
from app.core.config import settings
from app.db.database import engine, Base

# Prometheus metrics
REQUEST_COUNT = Counter(
    'app_request_count',
    'Application Request Count',
    ['method', 'endpoint', 'http_status']
)
REQUEST_LATENCY = Histogram(
    'app_request_latency_seconds',
    'Application Request Latency',
    ['method', 'endpoint']
)

# Função para normalizar endpoints com IDs
def normalize_endpoint(path: str) -> str:
    # Padrão para endpoints com IDs numéricos
    patterns = [
        r'/api/v1/products/\d+',
        r'/api/v1/orders/\d+',
        r'/api/v1/inventory/\d+'
    ]
    
    # Substituir o padrão específico por uma versão normalizada
    for pattern in patterns:
        if re.match(pattern, path):
            # Extrair a parte base do endpoint e adicionar /{id}
            base_path = path.rsplit('/', 1)[0]
            return f"{base_path}/{{id}}"
    
    return path

class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        method = request.method
        path = request.url.path
        
        # Normalizar o caminho para métricas
        normalized_path = normalize_endpoint(path)
        
        start_time = time.time()
        response = await call_next(request)
        duration = time.time() - start_time
        
        status_code = response.status_code
        REQUEST_COUNT.labels(method=method, endpoint=normalized_path, http_status=status_code).inc()
        REQUEST_LATENCY.labels(method=method, endpoint=normalized_path).observe(duration)
        
        return response

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    description="API para comparação de performance entre Python e Node.js"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus middleware
app.add_middleware(PrometheusMiddleware)

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

# Include API router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    return {"message": "Backend Comparison - Python Version"}

@app.on_event("startup")
async def startup():
    # Create database tables
    Base.metadata.create_all(bind=engine)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
