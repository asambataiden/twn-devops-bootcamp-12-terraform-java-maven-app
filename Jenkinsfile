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
            sh "terraform init"
            sh "terraform apply --auto-approve"
            EC2_PUBLIC_IP = sh(
              script: "terraform output ec2_public_ip",
              returnStdout: true
            ).trim()
          }
        }
      }
    }

   stage('deploy') {
       environment {
           DOCKER_CREDS = credentials('docker-hub-repo-asambataiden')
       }

       steps {
           script {
               echo 'Waiting for the EC2 instance to be ready...'
               sleep(time: 90, unit: 'SECONDS')

               echo 'Deploying Docker image to EC2...'
               echo "EC2 Public IP: ${env.EC2_PUBLIC_IP}"

               sshagent(['server-ssh-key']) {

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
