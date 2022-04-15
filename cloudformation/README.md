## Deploying

Make sure you have SAM CLI installed and your AWS credentials are configured correctly.

simply run:

```bash
sam build && sam deploy --config-file samconfig.toml --resolve-image-repos --resolve-s3
```
