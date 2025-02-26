# Setup Instructions for AWS Docs CustomGPT Project

## Overview

This guide provides detailed steps to set up and run the AWS Docs CustomGPT project on your local machine. This project integrates AWS documentation as git submodules, making it easier to manage and update them.

## Prerequisites

Before you begin, ensure you have the following installed on your system:
- Git
- Python 3.8 or newer
- pip (Python package installer)

Additionally, you will need a GitHub account and a personal access token with permissions to access public repositories. This token will be used to automate tasks via GitHub Actions and scripts.

## Step-by-Step Setup

### 1. Clone the Repository

Start by cloning the project repository to your local machine. Use the following command, replacing `[repository URL]` with the actual URL of the repository:

```bash
git clone [repository URL]
cd [repository directory]
```

### 2. Install Python Dependencies

This project requires certain Python libraries to function correctly, particularly for scripting and automation tasks. Install these dependencies by running:

```bash
pip install -r requirements.txt
```

This command will install all the libraries listed in the `requirements.txt` file, such as `requests`, which is used for making HTTP requests in Python.

### 3. Set Up Git Submodules

This project uses submodules to manage the AWS documentation repositories. Initialize and update the submodules with the following commands:

```bash
git submodule init
git submodule update
```

### 4. Configure Your GitHub Personal Access Token

To allow the scripts to automatically update submodules and interact with GitHub's API, configure your GitHub personal access token. Replace `YOUR_GITHUB_PERSONAL_ACCESS_TOKEN` with your actual token in the script files or set it as an environment variable in your operating system.

### 5. Running the Add Submodules Script

If you need to add new AWS documentation submodules, you can run the provided Python script:

```bash
python .github/scripts/add_submodules.py
```

Make sure to update the script with your GitHub token and any specific configurations related to repository management.

### 6. Regular Updates

Configure your system or use GitHub Actions to regularly update the documentation submodules to ensure you always have the latest documentation. You can manually update the submodules by running:

```bash
git submodule update --remote --recursive
```

### 7. Additional Configuration

Depending on your specific needs, you may want to configure additional settings or scripts to better manage the documentation within your project. Refer to the `README.md` and `CONTRIBUTING.md` for more information on project standards and contribution guidelines.

## Conclusion

Following these setup instructions will help you get the AWS Docs CustomGPT project up and running on your local machine. This setup ensures that you have a robust system for managing and updating AWS documentation effectively. For any issues during setup, refer to the GitHub repository's issues section or contact the project maintainers.