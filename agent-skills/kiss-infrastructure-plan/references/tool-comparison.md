# IaC tool comparison

| Tool | Language | Strengths | Watch out |
|---|---|---|---|
| Terraform / OpenTofu | HCL | Multi-cloud; huge module ecosystem | State management discipline |
| Bicep | Bicep (DSL over ARM) | First-class Azure | Azure-only |
| Pulumi | TypeScript / Python / Go / C# | Real language + testing | Smaller ecosystem than TF |
| AWS CloudFormation | YAML / JSON | First-class AWS + CDK on top | AWS-only; slow drift detection |
| Ansible | YAML + Jinja | Config management > provisioning | Not the best for lifecycle state |

## Picking

- Multi-cloud or likely to be → Terraform / OpenTofu.
- Azure-only + Azure-native team → Bicep.
- Prefer real languages with full IDE support → Pulumi.
- Already heavily invested in one ecosystem → stay there unless a
  clear reason to move.

## State + collaboration

Never use local state for shared infrastructure. Use a remote
backend with locking (S3 + DynamoDB, Azure Storage + blob lease,
GCS + IAM lock, Terraform Cloud, etc.).

## AI-authoring note

The skill **does not** run `terraform init/plan/apply` or any
cloud CLI. It writes the design and a starter module; a human
operates the tool with appropriate credentials.
