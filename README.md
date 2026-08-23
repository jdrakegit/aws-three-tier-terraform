# Three-Tier AWS Web Application (Terraform)

A three-tier AWS setup built entirely in Terraform. Custom VPC, public and private subnets across two AZs, an Application Load Balancer sending traffic to two EC2 web servers, and an RDS MySQL database sitting behind everything else. Nothing but the load balancer touches the internet directly.

This is the first project I built straight in Terraform instead of clicking through the console first. The plan going forward is to keep tearing it down and rebuilding it so the syntax and the reasoning actually stick instead of just working once and getting forgotten.

---

## Why build it this way

If a web app's servers and database all sit in one flat network, anything that reaches the internet can eventually reach the database too. Splitting it into tiers means only the load balancer is actually exposed. The servers and the database stay hidden behind it, and each layer only trusts the one directly in front of it.

---

## What's in it

- VPC (`10.0.0.0/16`) across `us-east-1a` and `us-east-1b`
- Public subnets (`10.0.1.0/24`, `10.0.2.0/24`) hold the ALB and NAT Gateway
- Private subnets (`10.0.3.0/24`, `10.0.4.0/24`) hold the EC2 instances and RDS
- Internet Gateway for the public side, NAT Gateway so the private side can still reach out for updates without anything reaching in
- ALB distributing HTTP traffic across two t3.micro EC2 instances, one per AZ
- RDS MySQL (db.t3.micro), reachable only from the EC2 security group

Security group chain:

```
Internet → ALB (open on port 80)
ALB → EC2 (only the ALB's security group)
EC2 → RDS (only the EC2 security group, port 3306)
```

Nothing can skip a step. The database will only talk to EC2. EC2 will only talk to the ALB.

---

## How it's organized

Split into separate files instead of one giant `main.tf`: `provider.tf`, `variables.tf`, `vpc.tf`, `ec2.tf`, `alb.tf`, `rds.tf`, `outputs.tf`. The database password lives in a gitignored `terraform.tfvars` file, and the variable itself has no default, so Terraform won't let it silently fall back to something hardcoded.

---

## Building the network

Built the VPC and four subnets first. Early on I accidentally nested a `route` block inside the `aws_internet_gateway` resource instead of giving it its own `aws_route_table` — Terraform errored on a missing closing brace, and once I split them apart it worked. Public route table points at the Internet Gateway, private one points at the NAT Gateway, and each subnet gets associated with the right one.

The NAT Gateway also needed an explicit `depends_on` pointing at the Internet Gateway, since nothing in its arguments actually referenced the IGW and Terraform had no other way to know it needed to exist first.

---

## EC2 and the load balancer

Used a `data "aws_ami"` block with a wildcard (`al2023-ami-*-x86_64`) so it always grabs the current Amazon Linux 2023 image instead of a hardcoded AMI ID that goes stale. Two instances, one per private subnet, both behind a security group that only lets port 80 in from the ALB's security group specifically.

Gave both instances a `user_data` script so they'd actually run a web server instead of sitting there with nothing on port 80. First version used `yum`, and both instances came up unhealthy in the target group with the ALB returning a 502. Turned out Amazon Linux 2023 runs on `dnf`, not `yum`, so the install step never actually ran. Swapped it over, but since `user_data` only fires on first boot, just changing the script didn't do anything until I forced a replace with `terraform apply -replace`. After that both targets went healthy and the ALB actually served a real response.

Also hit a Free Tier error on `t2.micro` — turned out it wasn't eligible on this account, `t3.micro` was, so I switched.

---

## Testing it

Ran `terraform plan` before every apply, checked target health directly through `aws elbv2 describe-target-health` instead of trusting the console alone, and confirmed the whole path by loading the ALB's DNS name in a browser and getting a real response back from one of the EC2 instances.

---

## Outputs

`outputs.tf` prints the ALB's DNS name, the RDS endpoint, and the VPC ID after every apply, so there's no need to dig through the console to find them.

---

## Tearing it down

```
terraform destroy
```

The NAT Gateway and RDS instance are the main things that cost money if left running, so this is meant to be destroyed between sessions, not left up indefinitely.

---
