pipeline {
    agent {
        label 'python'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '5'))
        timestamps()
        timeout(time: 3, unit: 'MINUTES')
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }

    environment {
        VENV_BIN_DIR = '.venv/bin'
        PYTEST_REPORT = "reports/pytest-report.xml"
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
                sh 'ci/setup.sh "$VENV_BIN_DIR"'
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
