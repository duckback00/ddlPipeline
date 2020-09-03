pipeline {
  agent any
  stages {
    stage('Host Info') {
      steps {
        sh 'uname -a ; ls -ll /var/lib/jenkins/workspace/ddlPipeline_master'
      }
    }

    stage('Provision VDB') {
      steps {
        echo 'VDB'
      }
    }

    stage('Mask VDB') {
      steps {
        echo 'mask'
      }
    }

    stage('Package and Test DDL') {
      steps {
        echo 'DDL'
      }
    }

    stage('Forecast Database') {
      parallel {
        stage('Forecast Database') {
          steps {
            echo 'Forecast DB'
          }
        }

        stage('bad scripot') {
          steps {
            echo 'bad'
          }
        }

      }
    }

    stage('Deploy DDL') {
      steps {
        echo 'Deploy DDL'
      }
    }

    stage('Deploy Application') {
      steps {
        echo 'Deploy App'
      }
    }

  }
}