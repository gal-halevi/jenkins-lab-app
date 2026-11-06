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
        RUFF_REPORT = "${env.REPORT_DIR}/ruff-report.xml"
        PYTEST_REPORT = "${env.REPORT_DIR}/pytest-report.xml"
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
        post {
            always {
                junit testResults: "${env.RUFF_REPORT}"
            }
        }

        stage('Run Tests') {
            steps {
                sh '$VENV_DIR/pytest --junitxml=$REPORT_DIR/pytest-report.xml tests/'
            }
        }
        post {
            always {
                junit testResults: "${env.PYTEST_REPORT}"
            }
        }

        stage('Package') {
            steps {
                sh '$VENV_DIR/python -m build'
            }
        }
        post {
            success {
                archiveArtifacts artifacts: "dist/**", fingerprint: true
            }
        }
    }
}
