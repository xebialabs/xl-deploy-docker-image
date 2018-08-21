#!groovy

pipeline {
    agent none

    environment {
        GRADLE_OPTS = '-Xmx1024m'
    }

    options {
        buildDiscarder(logRotator(artifactDaysToKeepStr: '7', artifactNumToKeepStr: '5'))
        skipDefaultCheckout()
        timeout(time: 1, unit: 'HOURS')
        timestamps()
        ansiColor('xterm')
    }

    parameters {
        string(name: 'version', description: 'Version to tag the docker image')
        string(name: 'flavor', defaultValue: "debian-slim", description: 'Flavor of the docker image')
        string(name: 'registry', defaultValue: "xl-docker.xebialabs.com", description: 'Registry to push the image to')
        string(name: 'repository', defaultValue: "xl-deploy", description: 'Repository to push the image to')
    }

    stages {
        stage('Publish Docker image to XLD docker registry') {
            when {
                expression { params.version != '' }
            }
            agent {
                node {
                    label 'xld || release-xld'
                }
            }

            steps {
                checkout scm

                withCredentials([usernamePassword(credentialsId: 'nexus-ci', passwordVariable: 'nexus_pass', usernameVariable: 'nexus_user'),
                                 usernamePassword(credentialsId: 'xldevdocker', passwordVariable: 'docker_pass', usernameVariable: 'docker_user')]) {

                    sh "./build.sh -f \"${params.flavor}\" -h -v \"${params.version}\" -s nexus -u \"${nexus_user}\" -p \"${nexus_pass}\" -U \"${docker_user}\" -P \"${docker_pass}\" -g \"${params.registry}\" -r \"${params.repository}\""

                }

            }
        }
    }
}

