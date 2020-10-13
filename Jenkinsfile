pipeline {
  agent any
  stages {
    stage('Provision DataSets') {
      steps {
        sh '''
	{ set -x; } 2>/dev/null

	#PATH=/home/delphix_os/DaticalDB/repl:${PATH}

	cd /home/delphix_os/API
        /home/delphix_os/API/jet_build.sh create
	/home/delphix_os/API/jet_vcs.sh bookmark create before_test false ""rel_1.1"" 
	cd - 
 
        '''
      }
    }

    stage('Mask Data Sets') {
      steps {
        echo 'mask'
      }
    }

    stage('Create Branches') {
      steps {
        sh '''
	{ set -x; } 2>/dev/null

        cd /home/delphix_os/API
        /home/delphix_os/API/jet_vcs.sh branch create rel20 latest rel20
	/home/delphix_os/API/jet_vcs.sh branch activate default 
        /home/delphix_os/API/jet_vcs.sh branch create rel30 latest rel30
	/home/delphix_os/API/jet_vcs.sh branch activate default 
	cd - 
 
        '''
      }
    }

    stage('Unit Tests') {
      parallel {
        stage('Test Success') {
          steps {
            echo 'DB Okay'
          }
        }

        stage('Found Bad Data') {
          steps {
            sh '''
	{ set -x; } 2>/dev/null

        cd /home/delphix_os/API
	sleep 2
	/home/delphix_os/API/jet_vcs.sh bookmark create bad_data true """" 
        /home/delphix_os/API/jet_vcs.sh branch create break_fix bad_data bf1 
	/home/delphix_os/API/jet_vcs.sh branch activate default 
	cd - 
 
        '''
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