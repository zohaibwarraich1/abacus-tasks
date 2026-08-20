data "aws_iam_policy_document" "assume_role_policy" {
  count = var.create_iam_profile ? 1 : 0
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count              = var.create_iam_profile ? 1 : 0
  name               = "${var.launch_template_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[0].json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "this" {
  count = var.create_iam_profile ? 1 : 0
  name  = "${var.launch_template_name}-profile"
  role  = aws_iam_role.this[0].name
  tags  = var.tags
}

# Baseline policy for Systems Manager (SSM) access
resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.create_iam_profile ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach any extra policies passed via variables (e.g. from prod/main.tf)
resource "aws_iam_role_policy_attachment" "additional_policies" {
  count      = var.create_iam_profile ? length(var.additional_iam_policy_arns) : 0
  role       = aws_iam_role.this[0].name
  policy_arn = var.additional_iam_policy_arns[count.index]
}
