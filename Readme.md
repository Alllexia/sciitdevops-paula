# DevOps Final Project

CI/CD pipeline for a cloud website displaying the weather

---

## Table of Contents

- [About](#about)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## About

An end-to-end CI/CD pipeline that:

1. Deploys infrastructure (VMs for k3s and application servers) using Terraform.

2. Configures the infrastructure using Ansible.

3. Sets up a GitOps workflow using ArgoCD to deploy Jenkins into k3s.

4. Uses Jenkins to deploy a web app that dynamically fetches weather forecasts based on user input.

5. Implements observability (logs, monitoring, and alerting).

---

## Installation

### Prerequisites

#### Software or tools required to run the project:


### Steps

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/project-name.git

