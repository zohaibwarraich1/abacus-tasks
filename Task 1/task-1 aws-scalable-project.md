## VPC
Created a vpc with cidr block of 10.0.0.0/16
Used 2 AZs of ap-south i.e 1a & 1b

## Subnets
Created two public subnets with cidr blocks of 10.0.0.0/20 and 10.0.16.0/20 in AZs 1a & 1b
Created two private subnets with cidr blocks of 10.0.128.0/20 and 10.0.144.0/20 in AZs 1a & 1b

## NAT gateway
Created a regional NAT gateway just because of its auto contraction capability that will help in cost optimization.
Enabled Enable DNS hostnames && Enable DNS resolution for ALB to provide it public DNS and resolution of it.

## Internet Gateway
Created an internet gateway and attached it to the vpc

## Route tables

Created a route table for the public subnets and attached it to the internet gateway
Created a route table for the private subnets and attached it to the NAT gateway

1. project-abacus-task-rtb-public attached to pub subnet 1a && pub subnet 1b && igw
2. project-abacus-task-rtb-private1-ap-south-1a attached to priv subnet 1a && regional nat gateway
3. project-abacus-task-rtb-private2-ap-south-1b attached to priv subnet 1b && regional nat gateway
4. rtb-0fde0740aece47ba3 (rtb-regional-nat) attached to regional nat gateway && igw 
5. rtb-0562ce6fc2a10f77a not attached to any resource cause its a default vpc route table.

## EIP and ENI 
1 EIP created for nat-10b6066df89b4af90 (project-abacus-task-regional-nat)

## Target Group
Created a target group with port 80 for ALB to forward requests to EC2 instances.
Health check configuration
Health check protocol : HTTP
Health check port: traffic port
Health check path: /
Healthy threshold: 5
Unhealthy threshold: 5
Timeout: 10
Interval: 30

Load balancing algorithm: round robin
Protocol Version: HTTP1
IP Address type: IPv4
Target type: Instances

## Load Balancer
Created an ALB inside a vpc (project-abacus-task-vpc) and have 2 public subnets in each AZs (project-subnet-public1-ap-south-1a && project-subnet-public2-ap-south-1b)
It has security group (abacus-task-1-sg)

## Launch Template
Created a launch template with t3.micro and ubuntu image with security group (abacus-task-1-sg)

## ASG
Created an ASG inside a vpc (project-abacus-task-vpc) and have 2 private subnets in each AZs (project-subnet-private1-ap-south-1a && project-subnet-private2-ap-south-1b)
It has launch template created in above section.
It has Availability Zone distribution set to Balanced best effort.
Capacity Reservation preference is set to default
It has alb (abacus-task-1-alb) attached to it which is connected to public subnets.
ARC zonal shift is Disabled

Health check type: EC2, ELB
Health check grace period: 300 seconds
Desired capacity: 4
Minimum desired capacity: 4
Maximum desired capacity: 6
Scaling policy name: Target Tracking Policy and it will Execute policy that is to maintain Average CPU utilization at 60%

Replacement behavior: Launch before terminating
Min healthy percentage: 100
Max healthy percentage: 110
Monitoring: Disabled
Default instance warmup: 300 seconds
There is no deletion protection set for auto scaling group

## SGs
abacus-task-1-sg-for-alb: 
    inbound rule: soure 0.0.0.0/0 and port 80
    outbound rule: all
abacus-task-1-sg: 
    inbound rule: soure abacus-task-1-sg-for-alb and port 80
    outbound rule: all