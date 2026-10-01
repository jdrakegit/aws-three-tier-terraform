# Three-Tier AWS Web Application (Terraform)

A three-tier setup on AWS, built with Terraform. VPC with public and private subnets across two Availability Zones, an Application Load Balancer as the only internet-facing component, an Auto Scaling Group of EC2 instances, and an RDS MySQL database.

First Terraform project I built from scratch instead of just clicking through the AWS console. Plan is to keep tearing it down and rebuilding it so the syntax actually sticks.

**Stack:** Terraform · AWS VPC · EC2 · Auto Scaling · ALB · RDS (MySQL) · CloudWatch · SNS · GitHub Actions

## Architecture Diagram

Made with Lucidchart.

![Architecture Diagram](architecture.png)

## Security Model

```
Internet → ALB (open on port 80)
ALB → EC2 (only accepts from the ALB's security group)
EC2 → RDS (only accepts from EC2's security group, port 3306)
```

Each layer only takes traffic from the layer right in front of it. Nothing skips a step. On the EC2 side it looks like this:

```
ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.alb.id]
}
```

Same idea on RDS, just pointed at the EC2 security group instead, on port 3306.

## Stack

- VPC (`10.0.0.0/16`) across `us-east-1a` / `us-east-1b`
- Public subnets: ALB, NAT Gateway
- Private subnets: EC2 (Auto Scaling Group), RDS
- Internet Gateway for public traffic, NAT Gateway so the private side can still reach out
- Split into files by resource: `provider.tf`, `variables.tf`, `vpc.tf`, `ec2.tf`, `alb.tf`, `rds.tf`, `outputs.tf`
- DB password lives in a gitignored `terraform.tfvars`, no default on that variable
- State is in S3 with locking on, not a local state file

## CI/CD

GitHub Actions runs on every push to `main`. `terraform plan` runs automatically, then `terraform apply` waits on manual approval through a protected environment before it touches anything real.

Setting this up is actually where I ran into the hardest problem of the whole project. My laptop and GitHub Actions were each keeping their own state file, so neither one knew what the other had already built. Every run started from scratch and tried to recreate everything, which meant duplicate VPCs, load balancers, even a duplicate database showing up in my account. Fixed it by moving state into S3 with `use_lockfile = true` so both sides read and write the same file and can't step on each other, but I had to manually clean up the duplicates first.

## Notes from building it

- Accidentally nested a `route` block inside `aws_internet_gateway` instead of giving it its own `aws_route_table`. Terraform just errored about a missing brace until I split them apart.
- NAT Gateway needed a `depends_on` pointing at the Internet Gateway since nothing in its config actually referenced it directly.
- AMI gets pulled dynamically with `data "aws_ami"` and a wildcard filter instead of hardcoding an ID that goes stale.
- Started with two hardcoded EC2 instances, switched to a launch template + Auto Scaling Group. The ASG registers with the target group directly instead of a manual attachment.
- `user_data` failed the first time because I used `yum`, but Amazon Linux 2023 uses `dnf`. Also learned `user_data` only runs on first boot, so changing the script does nothing to an instance that already exists, it has to actually get replaced.
- `t2.micro` isn't Free Tier eligible on this account, had to switch to `t3.micro`.
- Two pipeline runs went at the same time with no lock in place, which is what caused the duplicate resources mentioned above.

## Testing

`terraform plan` before every apply. Checked target health with `aws elbv2 describe-target-health` instead of just trusting the console. Confirmed it actually worked by hitting the ALB's DNS name in a browser, both locally and through the pipeline.

## Monitoring

CloudWatch alarm watching average CPU on the ASG, tied to an SNS topic that emails me if it stays above 70% for two checks in a row.

## Outputs

`outputs.tf` prints the ALB DNS name, RDS endpoint, and VPC ID after every apply so I'm not digging through the console for them.

## Tearing it down

```
terraform destroy
```

NAT Gateway and RDS are the main things that cost money if left running, so this gets destroyed between sessions.

## Running it yourself

```
git clone https://github.com/jdrakegit/aws-three-tier-terraform.git
cd aws-three-tier-terraform
terraform init
```

Make a `terraform.tfvars` file with your own password:

```
rds_password = "your-password-here"
```

Then:

```
terraform plan
terraform apply
```

Grab the ALB URL from the output once it's done and you should get a real response back from one of the instances.

If you want to use the GitHub Actions pipeline instead of applying locally, you'll need your own S3 bucket for state and your own `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `RDS_PASSWORD` set as repo secrets.

## What's next

HTTPS through ACM, and eventually Multi-AZ RDS so there's actual failover instead of a single instance.

---

Built by [Jordan Drake](https://github.com/jdrakegit) · [LinkedIn](https://www.linkedin.com/in/jordan-drake-a95471397)

---

Built by [Jordan Drake](https://github.com/jdrakegit) · [LinkedIn](https://www.linkedin.com/in/jordan-drake-a95471397)
