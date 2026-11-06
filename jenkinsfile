pipeline {
    agent {
        label 'python'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    environment {
        VENV_DIR = '.venv/bin'
        REPORT_DIR = 'reports'
    }

    stages {

        // skipping the checkout stage since the code is already checked out by Jenkins in declarative pipeline

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

        stage('Package') {
            steps {
                sh 'twine upload dist/*'
            }
        }
    }
    post {
            always {
                junit(
                    allowEmptyResults: true,
                    testResults: '$REPORT_DIR/*.xml'
                )
                archiveArtifacts(
                    allowEmptyArchive: true,
                    artifacts: 'dist/*.xml',
                    fingerprint: true
                )
            }
        }
}
