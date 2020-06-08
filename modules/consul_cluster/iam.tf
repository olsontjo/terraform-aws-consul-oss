# creates new instance role profile (noted by name_prefix which forces new resource) for named instance role
# uses random UUID & suffix
# see: https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html
resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${random_id.environment_name.hex}-consul" # TODO: transition to var
  role        = aws_iam_role.instance_role.name
}

# creates IAM role for instances using supplied policy from data source below
resource "aws_iam_role" "instance_role" {
  name_prefix        = "${random_id.environment_name.hex}-consul" # TODO: transition to var
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

# defines JSON for instance role base IAM policy
data "aws_iam_policy_document" "instance_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# creates IAM role policy for cluster discovery and attaches it to instance role
resource "aws_iam_role_policy" "cluster_discovery" {
  name   = "${random_id.environment_name.hex}-consul-cluster_discovery" # TODO: transition to var
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.cluster_discovery.json
}

# creates IAM policy document for linking to above policy as JSON
data "aws_iam_policy_document" "cluster_discovery" {
  # allow role with this policy to do the following: list instances, list tags, autoscale
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "autoscaling:CompleteLifecycleAction",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }

  # allow the named S3 bucket to be accessed by role with this policy to write and delete
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${random_id.environment_name.hex}-consul-data/*" # TODO: transition to var
    ]
  }

  # allow role with this policy to list the contents of the named bucket and its versions
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucketVersions",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${random_id.environment_name.hex}-consul-data" # TODO: transition to var
    ]
  }

}