pipeline {
  agent any
  stages {
    stage('Host Info') {
      steps {
        sh 'uname -a ; ls -ll /home/delphix_os/API/jet*'
      }
    }

    stage('Provision DataSets') {
      steps {
         sh '''
			{ set -x; } 2>/dev/null

			PATH=/home/delphix_os/DaticalDB/repl:${PATH}
			
			#RESULTS=`/opt/datical/dxtoolkit2/dx_get_db_env -engine delphix-vm-n-6 --format json | jq ".results[] | select(.Database == \\"orcl\\")"`
			#echo "Ingest Results: ${RESULTS}"
			#if [[ "${RESULTS}" == "" ]]
			#then
        /home/delphix_os/API/jet_build.sh create
			#	/opt/datical/dxtoolkit2/link_oracle_i.sh orcl Oracle_Source 172.16.129.133 orcl delphixdb delphixdb
			#fi
 
        '''
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
