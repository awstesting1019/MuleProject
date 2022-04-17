pipeline {
  agent any
    tools { 
      maven 'M2_HOME' 
      jdk 'JAVA_HOME' 
    }
  stages {
    stage('Build Stage') {
      steps {
        sh 'mvn clean package'
      }
    }
  }
}  
