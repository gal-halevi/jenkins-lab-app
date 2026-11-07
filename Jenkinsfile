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
                sh 'ci/setup.sh'
            }
        }

        stage('Lint') {
            steps {
                sh 'ci/lint.sh'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'ci/test.sh'
            }
            post {
                always {
                    junit testResults: "${env.PYTEST_REPORT}"
                }
            }
        }

        stage('Package') {
            steps {
                sh 'ci/package.sh'
            }
            post {
                success {
                    archiveArtifacts artifacts: "dist/**", fingerprint: true
                }
            }
        }
    }
}
