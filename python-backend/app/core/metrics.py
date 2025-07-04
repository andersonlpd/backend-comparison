import time
import psutil
import os
import gc
from prometheus_client import Counter, Histogram, Gauge

# Métricas de requisições HTTP
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

# Métricas de sistema
CPU_USAGE = Gauge(
    'app_cpu_usage_percent',
    'Current CPU usage percentage of the application process'
)

MEMORY_USAGE = Gauge(
    'app_memory_usage_bytes',
    'Current memory usage in bytes of the application process'
)

MEMORY_USAGE_PERCENT = Gauge(
    'app_memory_usage_percent', 
    'Current memory usage percentage of the application process'
)

CPU_COUNT = Gauge(
    'app_cpu_count',
    'Number of CPU cores available to the application'
)

MEMORY_TOTAL = Gauge(
    'app_memory_total_bytes',
    'Total system memory in bytes'
)

DISK_USAGE = Gauge(
    'app_disk_usage_bytes',
    'Current disk usage in bytes',
    ['path']
)

DISK_USAGE_PERCENT = Gauge(
    'app_disk_usage_percent',
    'Current disk usage percentage',
    ['path']
)

ACTIVE_CONNECTIONS = Gauge(
    'app_active_connections',
    'Number of active database connections'
)

# Métricas adicionais para comparação com Node.js
RESPONSE_SIZE = Histogram(
    'app_response_size_bytes',
    'Size of HTTP responses in bytes',
    ['method', 'endpoint']
)

REQUEST_SIZE = Histogram(
    'app_request_size_bytes', 
    'Size of HTTP requests in bytes',
    ['method', 'endpoint']
)

CONCURRENT_REQUESTS = Gauge(
    'app_concurrent_requests',
    'Number of concurrent requests being processed'
)

DB_QUERY_DURATION = Histogram(
    'app_db_query_duration_seconds',
    'Time spent on database queries',
    ['operation']
)

GC_COLLECTIONS = Counter(
    'app_gc_collections_total',
    'Total number of garbage collections',
    ['generation']
)

GC_TIME = Counter(
    'app_gc_time_seconds_total',
    'Total time spent in garbage collection'
)

THREAD_COUNT = Gauge(
    'app_thread_count',
    'Number of threads in the process'
)

FILE_DESCRIPTORS = Gauge(
    'app_file_descriptors',
    'Number of open file descriptors'
)

NETWORK_IO = Counter(
    'app_network_io_bytes_total',
    'Network I/O in bytes',
    ['direction']
)

STARTUP_TIME = Gauge(
    'app_startup_time_seconds',
    'Application startup time in seconds'
)

HEAP_SIZE = Gauge(
    'app_heap_size_bytes',
    'Current heap size in bytes'
)

ERROR_RATE = Counter(
    'app_errors_total',
    'Total number of application errors',
    ['error_type']
)

UPTIME = Gauge(
    'app_uptime_seconds',
    'Application uptime in seconds'
)

# Variáveis globais para rastreamento
_concurrent_requests = 0
_startup_time = time.time()

def get_concurrent_requests():
    return _concurrent_requests

def increment_concurrent_requests():
    global _concurrent_requests
    _concurrent_requests += 1
    CONCURRENT_REQUESTS.set(_concurrent_requests)
    return _concurrent_requests

def decrement_concurrent_requests():
    global _concurrent_requests
    _concurrent_requests -= 1
    CONCURRENT_REQUESTS.set(_concurrent_requests)
    return _concurrent_requests

def get_startup_time():
    return _startup_time

def update_system_metrics():
    """Atualiza as métricas de sistema"""
    try:
        # Obter processo atual
        process = psutil.Process(os.getpid())
        
        # CPU metrics
        cpu_percent = process.cpu_percent()
        CPU_USAGE.set(cpu_percent)
        CPU_COUNT.set(psutil.cpu_count())
        
        # Memory metrics
        memory_info = process.memory_info()
        memory_percent = process.memory_percent()
        
        MEMORY_USAGE.set(memory_info.rss)  # Resident Set Size
        MEMORY_USAGE_PERCENT.set(memory_percent)
        HEAP_SIZE.set(memory_info.vms)  # Virtual Memory Size como proxy para heap
        
        # System memory
        system_memory = psutil.virtual_memory()
        MEMORY_TOTAL.set(system_memory.total)
        
        # Disk usage
        disk_usage = psutil.disk_usage('/')
        DISK_USAGE.labels(path='/').set(disk_usage.used)
        DISK_USAGE_PERCENT.labels(path='/').set(disk_usage.percent)
        
        # Thread and process metrics
        THREAD_COUNT.set(process.num_threads())
        
        # File descriptors
        try:
            FILE_DESCRIPTORS.set(process.num_fds())
        except:
            # Windows doesn't support num_fds
            pass
        
        # Network I/O
        try:
            net_io = process.io_counters()
            NETWORK_IO.labels(direction='read').inc(net_io.read_bytes)
            NETWORK_IO.labels(direction='write').inc(net_io.write_bytes)
        except:
            pass
        
        # Database connections (approximation)
        connections = len(process.connections())
        ACTIVE_CONNECTIONS.set(connections)
        
        # Uptime
        UPTIME.set(time.time() - _startup_time)
        
        # Garbage collection metrics (Python específico)
        for i in range(3):
            GC_COLLECTIONS.labels(generation=str(i)).inc(gc.get_count()[i])
        
    except Exception as e:
        # Log do erro sem quebrar a aplicação
        print(f"Error updating system metrics: {e}")
        ERROR_RATE.labels(error_type='metrics_update').inc()
