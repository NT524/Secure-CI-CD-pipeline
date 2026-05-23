locals {
    cluster_name = "${var.cluster_name}-${var.environment}"
    vpc_dirs = {
        staging = "10.1.0.0/16"
    }

    private_subnets = {
        staging = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
    }

    public_subnets = {
        staging = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
    }

    instance_types = {
        staging = "t3.medium"
    }

    desired_instances = {
        staging = 2
    }
}