pipeline {
    agent {
        label 'python'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }

    environment {
        VENV_DIR = '.venv/bin'
        REPORT_DIR = 'reports'
    }

    stages {

        stage('Clean & Checkout') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'python3 -m venv .venv'
                sh '$VENV_DIR/pip install -r requirements-dev.txt . --no-deps'
            }
        }

        stage('Create Reports Directory') {
            steps {
                sh 'mkdir -p $REPORT_DIR'
            }
        }

        stage('Lint') {
            steps {
                sh '$VENV_DIR/ruff check . --output-format junit > $REPORT_DIR/ruff-report.xml'
            }
        }

        stage('Run Tests') {
            steps {
                sh '$VENV_DIR/pytest --junitxml=$REPORT_DIR/pytest-report.xml tests/'
            }
        }

        stage('Build') {
            steps {
                sh '$VENV_DIR/python -m build'
            }
        }
    }
    post {
            always {
                junit allowEmptyResults: true, testResults: "${env.REPORT_DIR}/*.xml"
                archiveArtifacts allowEmptyArchive: true, artifacts: "dist/**", fingerprint: true
            }
        }
}
