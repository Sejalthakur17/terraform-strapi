Terraform – Private EC2 with Strapi using ALB & NAT Gateway

This project provisions a secure AWS infrastructure using Terraform to deploy a Strapi application running on Docker inside a private EC2 instance.
Public access is provided through an Application Load Balancer (ALB), while outbound internet access is enabled via a NAT Gateway.

📌 Architecture Overview :
Internet
   |
[ Application Load Balancer ]
   |
[ Private EC2 (Docker + Strapi) ]
   |
[ NAT Gateway ]
   |
AWS Services (Docker pull, updates)

Key Design Principles :
Private EC2 → No direct internet exposure
Public ALB → Secure application access
NAT Gateway → Outbound-only internet access
Infrastructure as Code → Fully managed via Terraform
Environment-specific configs → Handled using tfvars

🧱 AWS Resources Created :
Resource	Description
VPC	Custom isolated network
Public Subnet	ALB + NAT Gateway
Private Subnet	EC2 running Strapi
Internet Gateway	Internet access for public subnet
NAT Gateway	Outbound access for private EC2
EC2 Instance	Dockerized Strapi app
Application Load Balancer	Public entry point
Security Groups	Controlled access
Key Pair	SSH login
user_data	Auto install Docker & Strapi

📁 Project Structure :
terraform-strapi/
│
├── provider.tf          # AWS provider configuration
├── main.tf              # Core infrastructure
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── terraform.tfvars     # Environment-specific values
├── user_data.sh         # Docker + Strapi bootstrap script
└── README.md

⚙️ Prerequisites :
AWS Account
Terraform v1.3+
AWS CLI configured (aws configure)
Existing EC2 Key Pair

🔧 Configuration :
terraform.tfvars
aws_region          = "ap-south-1"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
instance_type       = "t3.micro"
key_name            = "my-key"
environment         = "dev"

🐳 Application Setup (user_data):
The EC2 instance automatically:
Installs Docker
Pulls the official Strapi Docker image
Runs Strapi on port 1337
docker run -d -p 1337:1337 strapi/strapi

🚀 Deployment Steps :
terraform init
terraform plan
terraform apply

🌐 Accessing the Application :
After deployment, Terraform outputs the ALB DNS name:
alb_dns = dev-alb-123456.ap-south-1.elb.amazonaws.com

Open in browser:
http://<ALB_DNS_NAME>

🔐 Security Considerations :
EC2 instance is not publicly accessible
Only ALB can reach the application port (1337)
SSH access restricted via Security Group
Outbound internet only via NAT Gateway

🌍 Environment Management :
Different environments (dev, staging, prod) can be managed using:
Separate terraform.tfvars
Different backend configurations (optional)

Example:
terraform apply -var-file=prod.tfvars

🧪 Use Cases :
Production-grade Strapi deployment
DevOps / Terraform learning project
Interview-ready AWS architecture
Secure containerized application hosting

🧹 Cleanup :
To destroy all resources:
terraform destroy
