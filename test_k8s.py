
import paramiko
import sys

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    client.connect('192.168.1.51', username='k8s', password='Admin@123', timeout=10)
    print("✅ SSH connection successful!")
    
    # Run basic commands
    commands = [
        'hostname',
        'uname -a',
        'kubectl version --short 2>/dev/null || kubectl version --client',
        'docker --version 2>/dev/null || echo "Docker not found"',
        'kubectl get nodes 2>/dev/null || echo "K8s not accessible"',
        'kubectl get ns benchmark 2>/dev/null || echo "Namespace benchmark not found"',
    ]
    
    for cmd in commands:
        stdin, stdout, stderr = client.exec_command(cmd)
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        if out:
            print(f"  {out}")
        if err and 'WARNING' not in err:
            print(f"  ⚠️ {err}")
    
    client.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
    sys.exit(1)
