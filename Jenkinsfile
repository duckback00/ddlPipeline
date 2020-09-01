pipeline {
  agent any
  stages {
    stage('Host Info') {
      steps {
        sh 'uname -a ; ls -ll /var/lib/jenkins/workspace/ddlPipeline_master'
      }
    }

  }
}