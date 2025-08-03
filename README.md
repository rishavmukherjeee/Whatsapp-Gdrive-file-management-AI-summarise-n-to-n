

# WhatsApp Drive Automation & AI Summarizer

## Video Walkthrough

Watch the following embedded YouTube video for a working demo of the project:

<a href="https://youtu.be/DcTkqTEnpIc" target="_blank">
  <img src="https://img.youtube.com/vi/DcTkqTEnpIc/0.jpg" alt="YouTube Video" width="480"/>
</a>

Or [click here to watch on YouTube](https://youtu.be/DcTkqTEnpIc).

---

## Overview

This project automates file management between WhatsApp storage (your WhatsApp media folder or backup), Google Drive (cloud storage), and uses ChatGPT (OpenAI's conversational AI) for summarization and chat help. It allows you to:

- **List** files from your WhatsApp drive (local folder or backup)
- **Move** files between WhatsApp drive and Google Drive (gdrive)
- **Delete** files from either location
- **Summarize** file content or messages using ChatGPT (OpenAI)
- **Chat** with ChatGPT for normal conversation and help


**Definitions:**
- **WhatsApp drive:** The folder or backup location where your WhatsApp media/files are stored on your device or PC.
- **gdrive:** Google Drive, a cloud storage service by Google.
- **ChatGPT:** An AI chatbot by OpenAI that can summarize, answer questions, and chat.

All operations are managed via PowerShell scripts and Docker Compose for easy setup and execution.

## Prerequisites

- **Windows OS** (PowerShell v5.1 or later)
- **Docker Desktop** installed and running
- **Git** (optional, for cloning the repository)

## Project Structure

```
docker-compose.yml      # Docker Compose configuration
process.ps1             # Main PowerShell script for processing
setup.ps1               # PowerShell script for initial setup
test.ps1                # PowerShell script for testing
workflow-raw.json       # Raw workflow configuration
workflow.json           # Processed workflow configuration
README.md               # Project documentation
```

## Setup Instructions

1. **Clone or Download the Repository**
   - If you haven't already, clone this repository or download the ZIP and extract it.

2. **Install Docker Desktop**
   - Download and install Docker Desktop from [here](https://www.docker.com/products/docker-desktop/).
   - Start Docker Desktop and ensure it is running.

3. **Open PowerShell**
   - Navigate to the project directory:
     ```powershell
     cd "path\to\Task2"
     ```

4. **Run Setup Script**
   - Execute the setup script to prepare the environment:
     ```powershell
     .\setup.ps1
     ```

5. **Start Docker Services**
   - Use Docker Compose to start the required services:
     ```powershell
     docker-compose up -d
     ```

6. **Run the Main Process**
   - Execute the main process script:
     ```powershell
     .\process.ps1
     ```

7. **(Optional) Run Tests**
   - To run tests, use:
     ```powershell
     .\test.ps1
     ```

8. **Stop Docker Services**
   - When finished, stop the Docker containers:
     ```powershell
     docker-compose down
     ```

## Video Walkthrough

For a step-by-step video guide, watch the following embedded YouTube video:

<a href="https://youtu.be/DcTkqTEnpIc" target="_blank">
  <img src="https://img.youtube.com/vi/DcTkqTEnpIc/0.jpg" alt="YouTube Video" width="480"/>
</a>

Or [click here to watch on YouTube](https://youtu.be/DcTkqTEnpIc).

---

If you encounter any issues, please check your Docker installation and ensure all prerequisites are met.
