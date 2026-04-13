# 🚀 TechLeap — Cloud Platform (ECS Fargate + IaC + Observabilidade)

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)

## 📌 Visão Geral

O **TechLeap** é um ecossistema completo de infraestrutura e aplicação. Este projeto demonstra um fluxo de trabalho DevOps real, partindo de um ambiente de desenvolvimento conteinerizado até o deploy automatizado em um cluster escalável na AWS.

* **Infraestrutura como Código (IaC):** Provisionamento total via Terraform.
* **Pipeline CI/CD:** Automação completa com GitHub Actions (`ci.yml`).
* **Orquestração:** AWS ECS Fargate (Serverless Containers).
* **Banco de Dados:** PostgreSQL gerenciado via Amazon RDS.
* **Observabilidade:** Monitoramento de métricas com Prometheus e visualização em Grafana.

---

## 🏗️ Arquitetura

```bash
GitHub → CI/CD (GitHub Actions) → AWS ECR → AWS ECS Fargate → RDS (Postgres)
                                      ↓            ↓
                               CloudWatch ← Prometheus (Metrics) ← Grafana

```

### 🔍 Fluxo de Dados:
1.  **Push:** O desenvolvedor envia o código para a branch `main`.
2.  **CI/CD:** O GitHub Actions realiza o build e envia as imagens para o **Amazon ECR**.
3.  **IaC:** O Terraform aplica as mudanças na infraestrutura (RDS, ECS, VPC).
4.  **Deploy:** O serviço ECS realiza o *rolling update* das tarefas.
5.  **Metrics:** O CloudWatch e Prometheus coletam dados para os dashboards do Grafana.

---

## ⚙️ Pipeline de CI/CD

Arquivo: `.github/workflows/ci.yml`

* **🧱 Build:** Instalação e validação do ambiente Node.js.
* **🧪 Test:** Inicialização da API e validação do endpoint de métricas (`/metrics`).
* **🚀 Deploy:** Login no ECR, Push das imagens e execução do Terraform Apply.

---

## 👩🏻‍💻 Endpoints da Aplicação

### ☁️ Ambiente de Produção (AWS)
O tráfego é gerenciado por um **Application Load Balancer (ALB)** que distribui as requisições para os containers Fargate.

| Serviço | Porta | Endpoint (DNS do ALB) |
| :--- | :--- | :--- |
| **Portal (Frontend)** | `80` | `http://techleap-alb-1609484822.us-east-1.elb.amazonaws.com` |
| **API (Backend)** | `3000` | `http://techleap-alb-1609484822.us-east-1.elb.amazonaws.com:3000` |

> **⚠️ Nota de Configuração:** Para rodar na nuvem, o `fetch` no arquivo `frontend/script.js` deve ser apontado para o DNS do ALB na porta **3000**, substituindo o `localhost`.

### 💻 Ambiente Local (Docker Compose)
| Serviço | Porta | Descrição |
| :--- | :--- | :--- |
| **Frontend** | `8080` | Acesso via `http://localhost:8080` |
| **Backend** | `3000` | Acesso via `http://localhost:3000` |
| **Observabilidade**| `3000/metrics`| Métricas para Prometheus |

---

## 🛠️ Transição Local para Nuvem 

Para que a aplicação funcione corretamente após o deploy na AWS, foram aplicadas as seguintes mudanças de rede:

1. **Conectividade de API:**
   - **Local:** O frontend comunica-se com `http://localhost:3000`.
   - **AWS:** O frontend comunica-se com o DNS do Load Balancer na porta `3000`. Isso é necessário porque o backend está isolado em subnets privadas e o ALB atua como a única porta de entrada pública.
2. **Mapeamento de Portas no ALB:**
   - O Load Balancer possui dois **Listeners**:
     - **Porta 80:** Encaminha o tráfego para o serviço Frontend (Nginx).
     - **Porta 3000:** Encaminha o tráfego para o serviço Backend (Node.js).
---

## 📈 Painéis do Grafana 

* **Uso de CPU/Memória:** Monitoramento do cluster ECS.
* **Health Check:** Disponibilidade da API e do Banco RDS.
* **Métricas de App:** Latência de requisições e taxa de erros via Prometheus.

---

## 🧪 Execução Local

### 1. Iniciar Ambiente
```bash
git clone [https://github.com/HebertonGeovane/techleap-cloud-platform.git](https://github.com/HebertonGeovane/techleap-cloud-platform.git)
cd techleap-cloud-platform
docker compose up --build

```
### 2. Validar
Portal: http://localhost:8080

Métricas: http://localhost:3000/metrics

🔐 Segredos do GitHub (Secrets)
* `AWS_ACCESS_KEY_ID`

* `AWS_ACCOUNT_ID`

* `AWS_SECRET_ACCESS_KEY`

* `AWS_REGION: us-east-1`

* `DB_PASSWORD`

## 🎯 Conclusão
Este repositório serve como evidência técnica de implementação de pipelines de alta complexidade, unindo desenvolvimento de software com engenharia de infraestrutura robusta.

## 📣 Autor
**Heberton Geovane** — DevOps & Cloud Engineer [![LinkedIn](https://img.shields.io/badge/linkedin-%230077B5.svg?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/heberton-geovane)