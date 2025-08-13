#!/usr/bin/env python3
import yaml
import sys
import os

def generate_namespace_yaml(namespace_name):
    return {
        'apiVersion': 'v1',
        'kind': 'Namespace',
        'metadata': {
            'name': namespace_name,
            'labels': {
                'test': 'large-scale',
                'backend': 'postgresql'
            }
        }
    }

def generate_pod_yaml(namespace_name, pod_index):
    return {
        'apiVersion': 'v1',
        'kind': 'Pod',
        'metadata': {
            'name': f'baseline-violations-{pod_index}',
            'namespace': namespace_name,
            'labels': {
                'test': 'large-scale',
                'pod-index': str(pod_index)
            }
        },
        'spec': {
            'hostPID': True,
            'hostIPC': True,
            'hostNetwork': True,
            'containers': [{
                'name': 'c',
                'image': 'nginx',
                'securityContext': {
                    'privileged': True,
                    'capabilities': {
                        'add': ['NET_ADMIN']
                    },
                    'seccompProfile': {
                        'type': 'Unconfined'
                    }
                },
                'ports': [{
                    'containerPort': 8080,
                    'hostPort': 8080
                }],
                'volumeMounts': [{
                    'name': 'host',
                    'mountPath': '/host'
                }]
            }],
            'volumes': [{
                'name': 'host',
                'hostPath': {
                    'path': '/',
                    'type': 'Directory'
                }
            }]
        }
    }

def main():
    total_namespaces = 1425
    pods_per_namespace = 9
    
    # Create output directory
    os.makedirs('large-scale-resources', exist_ok=True)
    
    # Generate namespaces
    print(f"Generating {total_namespaces} namespaces...")
    with open('large-scale-resources/namespaces.yaml', 'w') as f:
        for i in range(1, total_namespaces + 1):
            namespace = generate_namespace_yaml(f'large-scale-test-{i}')
            f.write(yaml.dump(namespace, default_flow_style=False))
            f.write('---\n')
    
    # Generate pods in batches
    print(f"Generating {total_namespaces * pods_per_namespace} pods...")
    batch_size = 100  # Generate 100 namespaces worth of pods per file
    
    for batch in range(0, total_namespaces, batch_size):
        end = min(batch + batch_size, total_namespaces)
        filename = f'large-scale-resources/pods-batch-{batch//batch_size + 1}.yaml'
        
        with open(filename, 'w') as f:
            for ns_idx in range(batch + 1, end + 1):
                namespace_name = f'large-scale-test-{ns_idx}'
                for pod_idx in range(1, pods_per_namespace + 1):
                    pod = generate_pod_yaml(namespace_name, pod_idx)
                    f.write(yaml.dump(pod, default_flow_style=False))
                    f.write('---\n')
        
        print(f"Generated batch {batch//batch_size + 1}: namespaces {batch + 1}-{end}")

if __name__ == '__main__':
    main()
