# Getting Started with Azure DevOps Pipeline for Hasura DDN

Welcome! This guide will help you set up a complete CI/CD pipeline for your Hasura DDN project.

## 📦 What You've Got

Your repository now includes a complete Azure DevOps pipeline setup:

```
📁 Your Project
├── 📄 azure-pipelines.yml              ← Main pipeline configuration
├── 📄 GETTING_STARTED.md              ← You are here!
├── 📄 PIPELINE_QUICK_START.md         ← 5-minute setup guide
├── 📄 AZURE_DEVOPS_SETUP.md           ← Detailed documentation
├── 📄 PIPELINE_README.md              ← Pipeline overview
├── 📄 SETUP_CHECKLIST.md              ← Step-by-step checklist
├── 📁 .azure/
│   └── 📄 variables-template.json     ← Variable configuration template
└── 📁 scripts/
    ├── 🔧 local-pipeline-test.sh      ← Test pipeline locally
    └── 🔧 validate-pipeline-config.sh ← Validate your setup
```

## 🎯 What This Pipeline Does

Your Azure DevOps pipeline will automatically:

1. **Introspect** your Snowflake database schema
2. **Update** connector configuration with latest schema
3. **Build** your Hasura DDN supergraph
4. **Deploy** to production (on main branch)

All triggered automatically when you push code!

## 🚀 Quick Start (Choose Your Path)

### Path 1: I Want to Get Started FAST (5 minutes)
👉 Follow **[PIPELINE_QUICK_START.md](PIPELINE_QUICK_START.md)**

This is the fastest way to get your pipeline running.

### Path 2: I Want to Understand Everything (30 minutes)
👉 Follow **[AZURE_DEVOPS_SETUP.md](AZURE_DEVOPS_SETUP.md)**

This provides comprehensive documentation with explanations.

### Path 3: I Want a Step-by-Step Checklist
👉 Follow **[SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)**

This gives you a checkbox list to track your progress.

## 🧪 Before You Start: Test Locally

It's highly recommended to test the pipeline locally before setting up Azure DevOps:

### Step 1: Validate Your Configuration
```bash
./scripts/validate-pipeline-config.sh
```

This checks:
- ✅ All required files exist
- ✅ Environment variables are set
- ✅ DDN CLI is installed
- ✅ Configuration is valid

### Step 2: Test the Pipeline Locally
```bash
./scripts/local-pipeline-test.sh
```

This simulates what Azure DevOps will do:
- ✅ Runs introspection
- ✅ Updates metadata
- ✅ Builds supergraph
- ✅ Generates artifacts

If both scripts succeed, you're ready for Azure DevOps!

## 📋 Prerequisites

Before you begin, make sure you have:

- [ ] **Azure DevOps account** with permissions to create pipelines
- [ ] **Hasura DDN account** and project
- [ ] **Hasura DDN PAT** (Personal Access Token)
- [ ] **Snowflake credentials** and connection details
- [ ] **Git repository** connected to Azure DevOps

### Getting Your Hasura DDN PAT

```bash
# Login to DDN
ddn auth login

# Get your PAT
ddn auth print-access-token
```

Save this token - you'll need it for Azure DevOps!

## 🎓 Understanding the Pipeline

### Pipeline Stages

```
┌─────────────────┐
│  Code Change    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Stage 1:        │
│ Introspect      │  ← Scans Snowflake schema
│                 │  ← Updates connector config
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Stage 2:        │
│ Build           │  ← Builds supergraph
│                 │  ← Validates metadata
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Stage 3:        │
│ Deploy          │  ← Deploys to DDN
│ (main only)     │  ← Requires approval
└─────────────────┘
```

### When Does It Run?

The pipeline triggers automatically on:
- ✅ Push to `main` or `develop` branches
- ✅ Pull requests to `main` or `develop`
- ✅ Changes to connector, metadata, or config files

## 🔐 Security First

**Important:** Never commit secrets to Git!

The pipeline uses Azure DevOps Variable Groups to store:
- 🔒 Hasura DDN PAT
- 🔒 Snowflake credentials
- 🔒 Service tokens

See `.azure/variables-template.json` for the complete list.

## 📚 Documentation Guide

Here's when to use each document:

| Document | When to Use |
|----------|-------------|
| **GETTING_STARTED.md** | First time setup - you are here! |
| **PIPELINE_QUICK_START.md** | Want to get running in 5 minutes |
| **AZURE_DEVOPS_SETUP.md** | Need detailed explanations |
| **SETUP_CHECKLIST.md** | Want a step-by-step checklist |
| **PIPELINE_README.md** | Reference for pipeline features |
| **.azure/variables-template.json** | Setting up variables |

## 🛠️ Setup Overview

Here's the high-level process:

### 1. Local Validation (5 minutes)
```bash
./scripts/validate-pipeline-config.sh
./scripts/local-pipeline-test.sh
```

### 2. Azure DevOps Setup (10 minutes)
- Create variable group with secrets
- Create production environment (optional)
- Create pipeline from `azure-pipelines.yml`

### 3. First Run (5 minutes)
- Push code to trigger pipeline
- Monitor the run
- Verify artifacts

### 4. Verification (5 minutes)
- Test your GraphQL API
- Review generated metadata
- Confirm deployment

**Total Time: ~25 minutes**

## 🎯 Next Steps

1. **Choose your path** from the Quick Start section above
2. **Run validation scripts** to test locally
3. **Follow your chosen guide** to set up Azure DevOps
4. **Run your first pipeline** and celebrate! 🎉

## 💡 Pro Tips

### Tip 1: Start with a Feature Branch
Don't test on `main` first. Create a feature branch:
```bash
git checkout -b feature/test-pipeline
git push origin feature/test-pipeline
```

This runs Stages 1 & 2 without deploying.

### Tip 2: Use the Validation Script
Before every push, run:
```bash
./scripts/validate-pipeline-config.sh
```

This catches issues before they reach Azure DevOps.

### Tip 3: Monitor First Few Runs
Watch the first 2-3 pipeline runs closely to ensure everything works as expected.

### Tip 4: Set Up Notifications
Configure Azure DevOps to notify you of pipeline failures via email or Slack.

## 🐛 Troubleshooting

### Pipeline Fails Immediately
- Check variable group is named exactly `hasura-ddn-variables`
- Verify all required variables are set
- Ensure secrets are marked with 🔒

### Introspection Fails
- Verify Snowflake credentials in variable group
- Check `JDBC_SCHEMAS` variable is set correctly
- Test Snowflake connection locally

### Build Fails
- Run `ddn supergraph build create` locally first
- Check metadata files for errors
- Review connector configuration

### Deploy Doesn't Run
- Ensure you're on `main` branch
- Check previous stages succeeded
- Verify `production` environment exists

For more troubleshooting, see [AZURE_DEVOPS_SETUP.md](AZURE_DEVOPS_SETUP.md#troubleshooting).

## 🤝 Getting Help

Stuck? Here's how to get help:

1. **Check the docs** - Start with the troubleshooting sections
2. **Run validation** - `./scripts/validate-pipeline-config.sh`
3. **Test locally** - `./scripts/local-pipeline-test.sh`
4. **Check logs** - Review Azure DevOps pipeline logs
5. **Ask the community** - [Hasura Discord](https://hasura.io/discord)

## 📞 Support Resources

- **Hasura DDN Docs:** https://hasura.io/docs/3.0/
- **DDN CLI Reference:** https://hasura.io/docs/3.0/cli/overview/
- **Azure Pipelines Docs:** https://docs.microsoft.com/azure/devops/pipelines/
- **Community Discord:** https://hasura.io/discord

## ✅ Ready to Start?

Pick your path and let's get started:

- 🚀 **Fast Track:** [PIPELINE_QUICK_START.md](PIPELINE_QUICK_START.md)
- 📖 **Detailed Guide:** [AZURE_DEVOPS_SETUP.md](AZURE_DEVOPS_SETUP.md)
- ☑️ **Checklist:** [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)

Good luck! 🎉

