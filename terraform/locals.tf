locals {
    CLUSTER_NAME = "${var.cluster_name}-${var.environment}"
    # CIDR blocks for each environment
    vpc_cidrs = {
        staging = "10.1.0.0/16"
        prod    = "10.2.0.0/16"
    }

    # Private subnets for each environment
    private_subnets = {
        staging = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
        prod    = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
    }

    # Public subnets for each environment
    public_subnets = {
        staging = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
        prod    = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]
    }

    # Instance types based on environment
    instance_type = {
        staging = "t3.small"
        prod    = "t3.small"
    }

    # Desired node count per environment
    desired_instance_count = {
        staging = 2
        prod    = 3
    }
}
