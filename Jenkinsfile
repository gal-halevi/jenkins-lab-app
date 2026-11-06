pipeline {
    agent {
        label 'python'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '5'))
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }

    environment {
        VENV_BIN_DIR = '.venv/bin'
        REPORT_DIR = 'reports'
        PYTEST_REPORT = "${env.REPORT_DIR}/pytest-report.xml"
    }

    stages {

        stage('Clean & Checkout') {
            steps {
                deleteDir()
                checkout scm
                sh 'mkdir -p $REPORT_DIR'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'python3 -m venv $(dirname "$VENV_BIN_DIR")'
                sh '$VENV_BIN_DIR/pip install -r requirements-dev.txt . --no-deps'
            }
        }

        stage('Lint') {
            steps {
                sh '$VENV_BIN_DIR/ruff check . && $VENV_BIN_DIR/ruff format --check .'
            }
        }

        stage('Run Tests') {
            steps {
                sh '$VENV_BIN_DIR/pytest -m "not slow" --junitxml=$PYTEST_REPORT tests/'
            }
            post {
                always {
                    junit testResults: "${env.PYTEST_REPORT}"
                }
            }
        }

        stage('Package') {
            steps {
                sh '$VENV_BIN_DIR/python -m build'
            }
            post {
                success {
                    archiveArtifacts artifacts: "dist/**", fingerprint: true
                }
            }
        }
    }
}
