# Three-Tier AWS Web Application (Terraform)

A three-tier AWS setup built with Terraform. VPC with public and private subnets across two Availability Zones, an Application Load Balancer as the only internet-facing component, an Auto Scaling Group of EC2 instances, and an RDS MySQL database.

First Terraform project built from scratch instead of through the AWS console. Plan is to keep tearing it down and rebuilding it to lock in the syntax.

**Stack:** Terraform · AWS VPC · EC2 · Auto Scaling · ALB · RDS (MySQL) · CloudWatch · SNS

## Architecture Diagram

Made with Lucidchart.

![Architecture Diagram](architecture.png)

## Security Model

```
Internet → ALB (open on port 80)
ALB → EC2 (only accepts from the ALB's security group)
EC2 → RDS (only accepts from EC2's security group, port 3306)
```

Each layer only accepts traffic from the layer directly in front of it. Nothing skips a step. In code, that chain looks like this on the EC2 side:

```hcl
ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.alb.id]
}
```

Same pattern on RDS, just pointed at the EC2 security group instead, on port 3306.

## Stack

- VPC (`10.0.0.0/16`) across `us-east-1a` / `us-east-1b`
- Public subnets: ALB, NAT Gateway
- Private subnets: EC2 (Auto Scaling Group), RDS
- Internet Gateway for public outbound/inbound, NAT Gateway for private outbound-only
- Files split by resource: `provider.tf`, `variables.tf`, `vpc.tf`, `ec2.tf`, `alb.tf`, `rds.tf`, `outputs.tf`
- DB password in a gitignored `terraform.tfvars`, no default set on the variable

## Notes from the build

- Nested a `route` block inside `aws_internet_gateway` instead of giving it its own `aws_route_table`, Terraform threw a missing-brace error until it got split apart
- NAT Gateway needed an explicit `depends_on` on the Internet Gateway since nothing in its config referenced the IGW directly
- AMI is pulled dynamically with `data "aws_ami"` and a wildcard filter instead of a hardcoded ID
- Moved from two hardcoded EC2 instances to a launch template + Auto Scaling Group, ASG registers directly with the target group instead of manual attachments
- `user_data` failed on first try using `yum`, Amazon Linux 2023 uses `dnf`. Also learned `user_data` only fires on first boot, changing the script does nothing until the instance is replaced
- `t2.micro` wasn't Free Tier eligible on this account, switched to `t3.micro`

## Testing

`terraform plan` before every apply. Verified target health with `aws elbv2 describe-target-health` instead of trusting the console. Confirmed end-to-end by hitting the ALB's DNS name in a browser.

## Monitoring

CloudWatch alarm on average CPU across the ASG, tied to an SNS topic that emails an alert if usage stays above 70% for two checks in a row.

## Outputs

`outputs.tf` prints the ALB DNS name, RDS endpoint, and VPC ID after every apply.

## Teardown

```
terraform destroy
```

NAT Gateway and RDS are the main cost drivers if left running, so this gets destroyed between sessions.

## Running it yourself

```
git clone https://github.com/jdrakegit/aws-three-tier-terraform.git
cd aws-three-tier-terraform
terraform init
```

Create a `terraform.tfvars` file with your own database password:

```
rds_password = "your-password-here"
```

Then:

```
terraform plan
terraform apply
```

Grab the ALB URL from the output once it's done, and you should get a real response back from one of the EC2 instances behind it.

## What's next

HTTPS through ACM, a CI/CD pipeline with GitHub Actions so a push builds and deploys automatically, and eventually Multi-AZ RDS for real failover instead of a single instance.

---

Built by [Jordan Drake](https://github.com/jdrakegit) · [LinkedIn](https://www.linkedin.com/in/jordan-drake-a95471397)
