#!/usr/bin/env python3
"""
Test script to validate Kubernetes manifests for MCP Proxy deployment
"""

import yaml
import sys
from pathlib import Path

def validate_yaml_file(filepath):
    """Validate a YAML file can be parsed correctly"""
    try:
        with open(filepath) as f:
            docs = list(yaml.safe_load_all(f))
        return True, docs
    except Exception as e:
        return False, str(e)

def test_deployment():
    """Test mcpo-proxy-deployment.yaml"""
    print("Testing mcpo-proxy-deployment.yaml...")
    
    success, result = validate_yaml_file('mcpo-proxy-deployment.yaml')
    if not success:
        print(f"  ❌ YAML parsing failed: {result}")
        return False
    
    deployment = result[0]
    
    # Check basic structure
    assert deployment['kind'] == 'Deployment', "Should be a Deployment"
    assert deployment['metadata']['name'] == 'mcpo-proxy-deployment', "Should have correct name"
    
    # Check container configuration
    containers = deployment['spec']['template']['spec']['containers']
    assert len(containers) == 1, "Should have one container"
    
    container = containers[0]
    assert container['name'] == 'mcpo-proxy', "Container should be named mcpo-proxy"
    assert container['image'] == 'python:3.11-slim', "Should use python:3.11-slim image"
    
    # Check ports
    assert container['ports'][0]['containerPort'] == 8000, "Should expose port 8000"
    
    # Check environment variables
    env_vars = {env['name']: env['value'] for env in container['env']}
    assert 'MCP_SERVER_URL' in env_vars, "Should have MCP_SERVER_URL env var"
    assert 'n8n.cluster.dphx.eu' in env_vars['MCP_SERVER_URL'], "Should point to correct MCP server"
    
    # Check command includes mcpo installation and execution
    command_str = container['args'][0]
    assert 'pip install' in command_str, "Should install mcpo"
    assert 'mcpo' in command_str, "Should run mcpo"
    assert '--server-type sse' in command_str, "Should use SSE server type"
    
    print("  ✅ Deployment manifest is valid")
    return True

def test_service():
    """Test mcpo-proxy-service.yaml"""
    print("Testing mcpo-proxy-service.yaml...")
    
    success, result = validate_yaml_file('mcpo-proxy-service.yaml')
    if not success:
        print(f"  ❌ YAML parsing failed: {result}")
        return False
    
    service = result[0]
    
    # Check basic structure
    assert service['kind'] == 'Service', "Should be a Service"
    assert service['metadata']['name'] == 'mcpo-proxy-service', "Should have correct name"
    
    # Check selector
    assert service['spec']['selector']['app'] == 'mcpo-proxy', "Should select mcpo-proxy pods"
    
    # Check ports
    ports = service['spec']['ports']
    assert len(ports) == 1, "Should have one port"
    assert ports[0]['port'] == 8000, "Should expose port 8000"
    assert ports[0]['targetPort'] == 8000, "Should target port 8000"
    
    print("  ✅ Service manifest is valid")
    return True

def test_ingress():
    """Test mcpo-proxy-ingress.yaml"""
    print("Testing mcpo-proxy-ingress.yaml...")
    
    success, result = validate_yaml_file('mcpo-proxy-ingress.yaml')
    if not success:
        print(f"  ❌ YAML parsing failed: {result}")
        return False
    
    ingress = result[0]
    
    # Check basic structure
    assert ingress['kind'] == 'Ingress', "Should be an Ingress"
    assert ingress['metadata']['name'] == 'mcpo-proxy-ingress', "Should have correct name"
    
    # Check TLS
    tls = ingress['spec']['tls'][0]
    assert 'mcpo-proxy.cluster.dphx.eu' in tls['hosts'], "Should have correct host"
    assert tls['secretName'] == 'mcpo-proxy-tls', "Should have TLS secret"
    
    # Check rules
    rules = ingress['spec']['rules']
    assert len(rules) == 1, "Should have one rule"
    assert rules[0]['host'] == 'mcpo-proxy.cluster.dphx.eu', "Should have correct host"
    
    # Check backend service
    backend = rules[0]['http']['paths'][0]['backend']['service']
    assert backend['name'] == 'mcpo-proxy-service', "Should point to correct service"
    assert backend['port']['number'] == 8000, "Should use port 8000"
    
    print("  ✅ Ingress manifest is valid")
    return True

def test_dockerfile():
    """Test Dockerfile.mcpo exists and has basic structure"""
    print("Testing Dockerfile.mcpo...")
    
    dockerfile_path = Path('Dockerfile.mcpo')
    if not dockerfile_path.exists():
        print("  ❌ Dockerfile.mcpo not found")
        return False
    
    content = dockerfile_path.read_text()
    
    # Check basic Dockerfile elements
    assert 'FROM python:3.11-slim' in content, "Should use python:3.11-slim base image"
    assert 'pip install' in content, "Should install mcpo"
    assert 'mcpo' in content, "Should reference mcpo"
    assert 'EXPOSE 8000' in content, "Should expose port 8000"
    
    print("  ✅ Dockerfile is valid")
    return True

def main():
    """Run all tests"""
    print("=" * 60)
    print("MCP Proxy Kubernetes Manifest Tests")
    print("=" * 60)
    print()
    
    # Change to script directory
    script_dir = Path(__file__).parent
    import os
    os.chdir(script_dir)
    
    tests = [
        test_deployment,
        test_service,
        test_ingress,
        test_dockerfile,
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except AssertionError as e:
            print(f"  ❌ Assertion failed: {e}")
            results.append(False)
        except Exception as e:
            print(f"  ❌ Unexpected error: {e}")
            results.append(False)
        print()
    
    print("=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"Results: {passed}/{total} tests passed")
    print("=" * 60)
    
    if passed == total:
        print("✅ All tests passed!")
        sys.exit(0)
    else:
        print("❌ Some tests failed")
        sys.exit(1)

if __name__ == '__main__':
    main()
