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
        VENV_BIN_DIR = '.venv/bin'
        REPORT_DIR = 'reports'
        RUFF_REPORT = "${env.REPORT_DIR}/ruff-report.xml"
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
                sh '$VENV_BIN_DIR/ruff check . --output-format junit > $RUFF_REPORT'
            }
            post {
                always {
                    junit testResults: "${env.RUFF_REPORT}"
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh '$VENV_BIN_DIR/pytest --junitxml=$PYTEST_REPORT tests/'
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
