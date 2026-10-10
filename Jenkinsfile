#!/usr/bin/env groovy

library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
  [$class: 'GitSCMSource',
  remote: 'https://github.com/asambataiden/twn-devops-bootcamp-12-terraform-jenkins-shared-library.git',
  credentialsId: 'github-credentials'
  ]
)

pipeline {   
  agent any
  tools {
    maven 'maven-3.9'
  }
  environment {
    IMAGE_NAME = 'asambataiden/demo-app:java-maven-2.0'
  }
  stages {
    stage("build app") {
      steps {
        script {
          echo 'building application jar...'
          buildJar()
        }
      }
    }
    stage("build image") {
      steps {
        script {
          echo 'building docker image...'
          buildImage(env.IMAGE_NAME)
          dockerLogin()
          dockerPush(env.IMAGE_NAME)
        }
      }
    }

    stage("provision server") {
      environment {
        AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws_secret_access_key')
        TF_VAR_env_prefix = 'test'
      }
      steps {
          script {
              dir('terraform') {

                    sh '''
                        set -eu

                        terraform init -input=false
                        terraform validate
                        terraform plan -out=tfplan -input=false
                        terraform apply -input=false -auto-approve tfplan
                    '''

                  env.EC2_PUBLIC_IP = sh(
                      script: 'terraform output -raw ec2_public_ip',
                      returnStdout: true
                  ).trim()
              }

              echo "EC2 Public IP: ${env.EC2_PUBLIC_IP}"
          }
      }
    }

stage('deploy') {
    environment {
        DOCKER_CREDS = credentials('docker-hub-repo-asambataiden')
    }

    steps {
        script {
            echo 'Waiting for EC2 bootstrap to complete...'
            echo "EC2 Public IP: ${env.EC2_PUBLIC_IP}"

            sshagent(['server-ssh-key']) {

                // Wait until SSH is reachable
                sh '''
                    set -eu

                    for attempt in $(seq 1 30); do
                        if ssh \
                          -o StrictHostKeyChecking=no \
                          -o ConnectTimeout=5 \
                          ec2-user@"$EC2_PUBLIC_IP" \
                          'echo "SSH ready"' 2>/dev/null; then

                            echo "EC2 SSH is ready."
                            break
                        fi

                        echo "Waiting for EC2 SSH... attempt ${attempt}/30"
                        sleep 10

                        if [ "$attempt" -eq 30 ]; then
                            echo "ERROR: EC2 did not become reachable via SSH."
                            exit 1
                        fi
                    done
                '''

                // Wait until Terraform user_data / cloud-init has completed
                sh '''
                    set -eu

                    ssh \
                      -o StrictHostKeyChecking=no \
                      ec2-user@"$EC2_PUBLIC_IP" \
                      'sudo cloud-init status --wait'
                '''

                // Validate the tools that deployment requires
                sh '''
                    set -eu

                    ssh \
                      -o StrictHostKeyChecking=no \
                      ec2-user@"$EC2_PUBLIC_IP" \
                      '
                        set -eu

                        echo "Checking Docker installation..."
                        docker --version

                        echo "Checking Docker Compose installation..."
                        docker compose version

                        echo "Checking disk capacity..."
                        df -h /
                        df -h /var/lib/docker
                      '
                '''

                echo 'EC2 bootstrap completed. Copying deployment files...'

                sh '''
                    set -eu

                    scp \
                      -o StrictHostKeyChecking=no \
                      server-cmds.sh \
                      ec2-user@"$EC2_PUBLIC_IP":/home/ec2-user/

                    scp \
                      -o StrictHostKeyChecking=no \
                      docker-compose.yaml \
                      ec2-user@"$EC2_PUBLIC_IP":/home/ec2-user/
                '''

                echo 'Authenticating EC2 with Docker Hub...'

                sh '''
                    set -eu

                    printf '%s' "$DOCKER_CREDS_PSW" \
                    | ssh \
                        -o StrictHostKeyChecking=no \
                        ec2-user@"$EC2_PUBLIC_IP" \
                        "docker login \
                          --username '$DOCKER_CREDS_USR' \
                          --password-stdin"
                '''

                echo 'Deploying application...'

                sh '''
                    set -eu

                    ssh \
                      -o StrictHostKeyChecking=no \
                      ec2-user@"$EC2_PUBLIC_IP" \
                      "bash /home/ec2-user/server-cmds.sh '$IMAGE_NAME'"
                '''
            }
        }
    }
  }
  }
}
