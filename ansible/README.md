# Ansible Automation for Benchmark

## Setup

### 1. Install Ansible

```bash
# Linux/macOS
pip install ansible

# Windows (WSL recommended)
wsl --install
# Then inside WSL:
pip install ansible
```

### 2. Configure Inventory

Edit `ansible/inventory.ini`:

```ini
[k3s_server]
k3s ansible_host=192.168.1.51 ansible_user=k8s

[k3s_server:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
# OR for password auth:
# ansible_ssh_pass=YOUR_PASSWORD
```

### 3. Test Connection

```bash
cd ansible
ansible all -m ping
```

## Playbooks

### 01-preflight.yml — Verifica K3s e dependências

```bash
ansible-playbook playbooks/01-preflight.yml
```

Coleta:
- Versão do K3s
- Nodes do cluster
- Conectividade PostgreSQL
- Conectividade Redis
- Storage classes
- Pods existentes

### 02-create-secrets.yml — Cria secrets Kubernetes

```bash
ansible-playbook playbooks/02-create-secrets.yml \
  -e "pg_password=SUA_SENHA_PG" \
  -e "redis_password=SUA_SENHA_REDIS"
```

### 03-label-nodes.yml — Adiciona labels nos nodes

```bash
ansible-playbook playbooks/03-label-nodes.yml
```

### 04-build-images.yml — Build de imagens Docker

```bash
# Single implementation
ansible-playbook playbooks/04-build-images.yml -e "impl=rust-rest-actix-web"

# All REST
ansible-playbook playbooks/04-build-images.yml -e "impl=all" -e "protocol=rest"

# All gRPC
ansible-playbook playbooks/04-build-images.yml -e "impl=all" -e "protocol=grpc"

# All GraphQL
ansible-playbook playbooks/04-build-images.yml -e "impl=all" -e "protocol=graphql"
```

### 05-deploy-benchmark.yml — Deploy e benchmark de uma implementação

```bash
# Basic
ansible-playbook playbooks/05-deploy-benchmark.yml -e "impl=rust-rest-actix-web"

# With mode and scenario
ansible-playbook playbooks/05-deploy-benchmark.yml \
  -e "impl=go-grpc-grpc-go" \
  -e "mode=clusterip" \
  -e "scenario=health"
```

### 06-run-all-benchmarks.yml — Benchmark de TODAS as implementações

```bash
# All implementations
ansible-playbook playbooks/06-run-all-benchmarks.yml

# REST only
ansible-playbook playbooks/06-run-all-benchmarks.yml -e "protocol=rest"

# gRPC only
ansible-playbook playbooks/06-run-all-benchmarks.yml -e "protocol=grpc"

# GraphQL only
ansible-playbook playbooks/06-run-all-benchmarks.yml -e "protocol=graphql"

# Specific environment
ansible-playbook playbooks/06-run-all-benchmarks.yml -e "environment=rust"
```

## Full Workflow

```bash
cd ansible

# 1. Preflight
ansible-playbook playbooks/01-preflight.yml

# 2. Create secrets
ansible-playbook playbooks/02-create-secrets.yml \
  -e "pg_password=Admin@123" \
  -e "redis_password=Admin@123"

# 3. Label nodes
ansible-playbook playbooks/03-label-nodes.yml

# 4. Build images
ansible-playbook playbooks/04-build-images.yml -e "impl=all" -e "protocol=rest"

# 5. Run benchmarks
ansible-playbook playbooks/05-deploy-benchmark.yml -e "impl=rust-rest-actix-web"

# 6. Or run all
ansible-playbook playbooks/06-run-all-benchmarks.yml -e "protocol=rest"
```

## Troubleshooting

### SSH Connection Failed

```bash
# Test SSH manually
ssh k8s@192.168.1.51

# Check SSH key
ssh-add -l

# Use password
ansible-playbook playbooks/01-preflight.yml --ask-pass
```

### K3s Not Found

```bash
# Install K3s on server
ssh k8s@192.168.1.51
curl -sfL https://get.k3s.io | sh -
```

### Docker Not Available

K3s uses containerd, not Docker. Images need to be imported:

```bash
# On server
docker save benchmark/rust-rest-actix-web:latest | sudo ctr -n k8s.io images import -
```
