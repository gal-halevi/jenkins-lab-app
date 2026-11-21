pipeline {
    agent none

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
        stage('Build') {
            agent {
                label 'python'
            }
            stages {

                stage('Clean & Checkout') {
                    steps {
                        deleteDir()
                        checkout scm
                    }
                }

                stage('Lint CI Scripts') {
                    steps {
                        sh 'ci/shellcheck.sh'
                    }
                }

                stage('Install Dependencies') {
                    steps {
                        sh 'ci/setup.sh'
                    }
                }

                stage('Version') {
                    steps {
                        script {
                            def version = sh(script: 'ci/version.sh', returnStdout: true).trim()
                            if (!version) {
                                error('ci/version.sh printed no version')
                            }
                            env.APP_VERSION = version
                            currentBuild.displayName = "${version} #${env.BUILD_NUMBER}"
                        }
                    }
                }

                stage('Checks') {
                    failFast true
                    parallel {
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
                        stage('Security') {
                            steps {
                                script {
                                    // ci/security.sh: 0 = clean, 3 = warnings only, anything else = failure
                                    def rc = sh(script: 'ci/security.sh', returnStatus: true)
                                    if (rc == 3) {
                                        unstable('Security findings below the blocking threshold: see the log and reports/')
                                    } else if (rc != 0) {
                                        error("Security checks failed (exit ${rc})")
                                    }
                                }
                            }
                            post {
                                always {
                                    // Empty allowed on purpose: if security.sh stops before writing a report
                                    // (e.g. jq missing), its own error already explains why.
                                    archiveArtifacts artifacts: 'reports/pip-audit-*.json,reports/bandit.json',
                                                     allowEmptyArchive: true
                                }
                            }
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
                            stash name: 'verify', includes: 'dist/**,requirements.txt,.python-version,ci/verify.sh,ci/common.sh'
                        }
                    }
                }
            }
        }

        stage('Verify') {
            agent {
                label 'python'
            }
            steps {
                deleteDir()
                unstash "verify"
                fingerprint "dist/*.whl"
                sh 'ci/verify.sh'
            }
        }
    }
}
