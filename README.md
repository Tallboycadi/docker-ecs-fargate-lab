<h1 align="center" style="color:#1E90FF;">🚀 AWS ECS Fargate Lab (Terraform + Node.js)</h1>

<p align="center">
This project demonstrates how to deploy a <b>containerized Node.js application</b> to 
<b>AWS ECS Fargate</b> using <b>Terraform</b> for Infrastructure as Code (IaC).  
It showcases a full 2-tier AWS setup with <b>ALB</b>, <b>ECR</b>, <b>ECS Task Definition</b>, 
<b>Service</b>, and <b>IAM roles</b> — all automated.
</p>

---

<h2><span style="color:#1E90FF;">🏗️ Architecture Overview</span></h2>

```mermaid
graph TD
    A[Local Dev / VS Code] -->|Terraform Apply| B[AWS VPC]
    B --> C[Subnets & Security Groups]
    C --> D[Application Load Balancer (ALB)]
    D --> E[ECS Service (Fargate)]
    E --> F[ECS Task Definition]
    F --> G[Container Image from Amazon ECR]
    G --> H[Node.js App - server.js]
<h2><span style="color:#C0C0C0;">🧩 Tech Stack</span></h2>
| Component                  | Technology                          |
| -------------------------- | ----------------------------------- |
| **Infrastructure as Code** | Terraform                           |
| **Container Runtime**      | Docker                              |
| **Compute Platform**       | AWS ECS Fargate                     |
| **Networking**             | AWS VPC, Subnets, Security Groups   |
| **Load Balancing**         | AWS Application Load Balancer (ALB) |
| **Registry**               | Amazon ECR                          |
| **Programming Language**   | Node.js                             |
| **IDE / Environment**      | Visual Studio Code                  |
<h2><span style="color:#1E90FF;">📁 Project Structure</span></h2>
docker-ecs-fargate-lab/
│
├── app/
│   └── server.js           # Simple Node.js web server
│
├── Dockerfile              # Defines container image build
├── main.tf                 # ECS cluster, service, task definition
├── provider.tf             # AWS provider + region setup
├── variables.tf            # Input variables
├── outputs.tf              # Outputs (ALB DNS, service ARN, etc.)
├── terraform.lock.hcl      # Provider version lock (auto-generated)
├── .gitignore              # Ignores .terraform/, tfstate files, etc.
└── README.md               # Project documentation

<h2><span style="color:#C0C0C0;">⚙️ Deployment Steps</span></h2>
# Build the Docker image
docker build -t clif-fargate-app .

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Tag and push
docker tag clif-fargate-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/clif-fargate-app:latest
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/clif-fargate-app:latest
terraform init
terraform plan
terraform apply
clif-fargate-alb-830625991.us-east-1.elb.amazonaws.com
terraform destroy
<h2><span style="color:#C0C0C0;">🧠 Lessons Learned</span></h2>

Understanding ECS Task Definition JSON encoding for container configuration

Correct IAM trust relationship setup for the ecs-task-execution-role

Troubleshooting ECR permissions and Terraform references

Importance of .gitignore to avoid large provider binaries

<h2><span style="color:#1E90FF;">✅ Demo Result</span></h2> <p align="center">
<b>Deployed Successfully!</b><br> <i>Hello from Clif on ECS Fargate</i> </p>
<h2><span style="color:#C0C0C0;">👨‍💻 Author</span></h2>

Cliffton C. Benford
🌐 GitHub: @Tallboycadi
💼 Cloud & DevOps Engineer | AWS | Terraform | Docker | CI/CD
🔗 LinkedIn www.linkedin.com/in/clifftonbenford-47439036a

<h2><span style="color:#1E90FF;">🏁 Next Steps</span></h2>

Integrate CI/CD with GitHub Actions (automate Terraform deploys)

Add CloudWatch Logs for ECS monitoring

Extend with RDS (PostgreSQL) or S3 static front-end

This project is part of Clif’s Cloud & DevOps Engineer journey — demonstrating real-world AWS infrastructure deployment with Terraform and ECS Fargate.

---

### 🌟 How to Apply It
1. In VS Code, open your project folder.  
2. Create or open your `README.md`.  
3. Paste the code above (replacing any existing text).  
4. Save → Commit → Push to GitHub:
   ```bash
   git add README.md
   git commit -m "Add styled README with blue and silver theme"
   git push
