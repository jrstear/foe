import time
import flux
import flux.job
from prometheus_client import start_http_server, Gauge

# Metrics
FLUX_JOB_COUNT = Gauge('flux_job_count', 'Number of jobs in Flux', ['state'])
FLUX_NODES_UP = Gauge('flux_nodes_up', 'Number of online nodes')

def collect_metrics(h):
    # Count Jobs by State
    stats = {'running': 0, 'inactive': 0, 'pending': 0}
    try:
        jobs = flux.job.job_list(h).get()
        for job in jobs:
            state = job.get('state_name', 'unknown')
            if state == 'run':
                stats['running'] += 1
            elif state == 'inactive':
                stats['inactive'] += 1
            elif state == 'depend' or state == 'priority' or state == 'sched':
                stats['pending'] += 1
        
        for state, count in stats.items():
            FLUX_JOB_COUNT.labels(state=state).set(count)
            
    except Exception as e:
        print(f"Error collecting job metrics: {e}")

    # Count Nodes
    try:
        # Simple approximation: online rank count
        # Proper way requires resource module query
        FLUX_NODES_UP.set(h.get_rank() + 1 if h.get_rank() is not None else 0) 
        # Better: use flux.resource.list() if available, but keep simple for now
    except Exception as e:
         print(f"Error collecting node metrics: {e}")

if __name__ == '__main__':
    print("Starting Flux Prometheus Exporter on :8080")
    start_http_server(8080)
    
    h = flux.Flux()
    
    while True:
        collect_metrics(h)
        time.sleep(5)
