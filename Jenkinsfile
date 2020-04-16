pipeline {
    agent { label "slave" }
    environment{
        branchName = sh(
            script: "echo ${env.GIT_BRANCH} | sed -e 's|/|-|g'",
            returnStdout: true
        ).trim()
        dockerTag="${env.branchName}-${env.BUILD_NUMBER}"
        dockerImage="${env.CONTAINER_IMAGE}:${env.dockerTag}"
        appName="credit-contract"
        githubUsername="Evrynetlabs"

        status_failure="{\"state\": \"failure\",\"context\": \"continuous-integration/jenkins\", \"description\": \"Jenkins\", \"target_url\": \"${BUILD_URL}\"}"
        status_success="{\"state\": \"success\",\"context\": \"continuous-integration/jenkins\", \"description\": \"Jenkins\", \"target_url\": \"${BUILD_URL}\"}"
    }
    stages {
        stage ('Cleanup') {
            steps {
                dir('directoryToDelete') {
                    deleteDir()
                }
            }
        }

        stage('Build Image Test') {
            steps {
                    sh '''
                        echo "Build Image"
                        docker build --pull -t ${dockerImage} -f docker/Dockerfile .
                    '''
                }
        }

        stage('Lint') {
            steps {
                sh '''
                    echo "Run lint -> ${dockerImage}"
                    docker run --rm ${dockerImage} sh -c "make lint"
                '''
            }
        }

        stage('Unit Test') {
            steps {
                sh '''
                    echo "Run unit test -> ${dockerImage}"
                    # docker run --rm ${dockerImage} sh -c "make test-coverage"
                '''
            }
        }

        stage('SonarQube Code Analysis') {
            steps {
                sh '''
                    echo "SonarQube Code Analysis"              
                '''
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                sh '''
                    echo "SonarQube Quality Gate"    
                '''
            }
        }
    }
    post {
        failure {
            withCredentials([string(credentialsId: 'evry-github-token-pipeline-status', variable: 'githubToken')]) {
                sh '''
                    curl \"https://api.github.com/repos/${githubUsername}/${appName}/statuses/${GIT_COMMIT}?access_token=${githubToken}\" \
                    -H \"Content-Type: application/json\" \
                    -X POST \
                    -d "${status_failure}"
                '''
                }
        }
        success {
            withCredentials([string(credentialsId: 'evry-github-token-pipeline-status', variable: 'githubToken')]) {
                sh '''
                    curl \"https://api.github.com/repos/${githubUsername}/${appName}/statuses/${GIT_COMMIT}?access_token=${githubToken}\" \
                    -H \"Content-Type: application/json\" \
                    -X POST \
                    -d "${status_success}"
                '''
                }
        }
        always {
            sh '''
               docker image rm -f ${dockerImage}
            '''
            deleteDir()
        }
    }
}
